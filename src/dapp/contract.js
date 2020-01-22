import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import FlightSuretyData from '../../build/contracts/FlightSuretyData.json';
import Config from './config.json';
import Web3 from 'web3';

export default class Contract {
    constructor(network, callback) {

        let config = Config[network];
        this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));
        this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
        this.flightSuretyData = new this.web3.eth.Contract(FlightSuretyData.abi, config.dataAddress);
        this.initialize(callback);
        this.owner = null;
        this.gas = config.gas;
        this.gasPrice = config.gasPrice
        this.airlines = [];
        this.passengers = [];
        console.log(config.firstAirline)
        this.firstAirline = config.dataAddress;
    }

    initialize(callback) {
        this.web3.eth.getAccounts( async (error, accts) => {
            this.owner = await accts[0];

            let counter = 1;
            
            while(this.airlines.length < 5) {
                this.airlines.push(accts[counter++]);
            }

            while(this.passengers.length < 5) {
                this.passengers.push(accts[counter++]);
            }

            callback();
        });
    }

    isOperational(callback) {
       let self = this;
       self.flightSuretyApp.methods
            .isOperational()
            .call({ from: self.owner}, callback);
    }

    // authorizeCaller(callback) {
    //     let self = this;
    //     let payload = {
    //         appContractOwner: self.owner,
    //         authorized: true
    //     }
    //     self.flightSuretyData.methods
    //         .authorizeCaller(self.appAddress)
    //         .send({ from: payload.appContractOwner }, (error, result) => {
    //             console.log(result);
    //             callback(error, payload);
    //         });
    // }

    addAirline(newAirline, callback) {
        let self = this;
        console.log(self.firstAirline);
        let payload = {
            newAirline: newAirline
        } 
        self.flightSuretyApp.methods
            .addAirline(payload.newAirline)
            .send({ from: self.firstAirline, gas: self.gas, gasPrice: self.gasPrice }, (error, result) => {
                console.log(result);
                callback(error, payload);
            });
    }

    registerAirline(newAirline, callback) {
        let self = this;
        let payload = {
            newAirline: newAirline
        } 
        self.flightSuretyApp.methods
            .registerAirline(payload.newAirline)
            .send({ from: self.firstAirline, gas: self.gas, gasPrice: self.gasPrice }, (error, result) => {
                console.log(result)
                callback(error, payload);
            });
    }

    fund(airline, amount, callback) {
        let self = this;
        let payload = {
            airline: airline,
            amount: amount
        } 
        console.log(payload.amount)
        self.flightSuretyApp.methods
            .fund()
            .send({ from: payload.airline, value: payload.amount }, (error, result) => {
                callback(error, payload);
            });
    }

    vote(airline, airlineToBeAdded, callback) {
        let self = this;
        let payload = {
            airline: airline,
            airlineToBeAdded: airlineToBeAdded
        } 
        self.flightSuretyData.methods
            .vote(payload.airlineToBeAdded)
            .send({ from: payload.airline, gas: self.gas, gasPrice: self.gasPrice }, (error, result) => {
                callback(error, payload);
            });
    }
    
    buy(airline, flight, timestamp, insuree, value, callback) {
        let self = this;
        let payload = {
            airline: airline,
            flight: flight,
            timestamp: timestamp,
            insuree: insuree,
            value: value
        } 
        self.flightSuretyApp.methods
            .buy(payload.airline, payload.flight, payload.timestamp)
            .send({ from: payload.insuree, value: payload.value }, (error, result) => {
                callback(error, payload);
            });
    }

    withdraw(insuree, callback) {
        let self = this;
        let payload = {
            passenger: insuree
        } 
        self.flightSuretyApp.methods
            .withdraw()
            .send({ from: payload.passenger, gas: self.gas, gasPrice: self.gasPrice }, (error, result) => {
                callback(error, payload);
            });
    }

    fetchFlightStatus(airline, flight, timestamp, callback) {
        let self = this;
        let payload = {
            airline: airline,
            flight: flight,
            timestamp: timestamp
        } 
        self.flightSuretyApp.methods
            .fetchFlightStatus(payload.airline, payload.flight, payload.timestamp)
            .send({ from: self.owner }, (error, result) => {
                callback(error, payload);
            });
    }
}