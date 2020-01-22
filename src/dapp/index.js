
import DOM from './dom';
import Contract from './contract';
import './flightsurety.css';


(async() => {

    let result = null;

    let contract = new Contract('localhost', () => {

        // Read transaction
        contract.isOperational((error, result) => {
            console.log(error,result);
            display('Operational Status', 'Check if contract is operational', [ { label: 'Operational Status', error: error, value: result} ]);
        });
            
        DOM.elid('submit-oracle').addEventListener('click', () => {
            console.log("Clicked");
        })

        DOM.elid('add-airline').addEventListener('click', () => {
            console.log("add-airline")
            let newAirlineAddress = DOM.elid('new-airline-address_1').value;
            // Write transaction
            contract.addAirline(newAirlineAddress, (error, result) => {
                display('Airline', 'Add Airline', [ { label: 'Add Airline Status', error: error, value: result.newAirline } ]);
            });
        })

        DOM.elid('register-airline').addEventListener('click', () => {
            console.log("register-airline")
            let newAirlineAddress = DOM.elid('new-airline-address_2').value;
            // Write transaction
            contract.registerAirline(newAirlineAddress, (error, result) => {
                display('Airline', 'Register Airline', [ { label: 'Register Airline Status', error: error, value: result.newAirline } ]);
            });
        })

        DOM.elid('submit-funds').addEventListener('click', () => {
            let airlineAddress = DOM.elid('airline-address').value;
            let fundValue = DOM.elid('fund-value').value;
            // Write transaction
            contract.fund(airlineAddress, fundValue, (error, result) => {
                display('Airline', 'Add Funds', [ { label: 'Add Funds Status', error: error, value: result.airline + ' ' + result.amount } ]);
            });
        })

        // User-submitted transaction
        DOM.elid('submit-vote').addEventListener('click', () => {
            let voterAirlineAddress = DOM.elid('voter-airline-address').value;
            let applicantAirlineAddress = DOM.elid('applicant-airline-address').value;
            console.log(voterAirlineAddress)
            console.log(applicantAirlineAddress)
            // Write transaction
            contract.vote(voterAirlineAddress, applicantAirlineAddress, (error, result) => {
                display('Airline', 'Vote Airline', [ { label: 'Vote Airline', error: error, value: result.applicantAirline } ]);
            });
        })
        
        DOM.elid('submit-buy').addEventListener('click', () => {
            let flightAirlineAddress = DOM.elid('flight-airline-address').value;
            let flightNumber = DOM.elid('flight-number').value;
            let timestamp = DOM.elid('timestamp').value;
            let passengerAddress = DOM.elid('passenger-address').value;
            let insuranceValue = DOM.elid('insurance-value').value;
            // Write transaction
            contract.buy(flightAirlineAddress, flightNumber, timestamp, passengerAddress, insuranceValue, (error, result) => {
                display('Flight', 'Buy insurance', [ { label: 'Buy insurance', error: error, value: result.insuree + ' ' + result.value } ]);
            });
        })

        DOM.elid('submit-withdraw').addEventListener('click', () => {
            let passengerAddress = DOM.elid('withdraw-passenger-address').value;
            // Write transaction
            contract.withdraw(passengerAddress, (error, result) => {
                display('Passenger', 'Claim insurance', [ { label: 'Insurance', error: error, value: result.passenger } ]);
            });
        })

        DOM.elid('submit-oracle').addEventListener('click', () => {
            let airlineAddress = DOM.elid('oracle-airline-address').value;
            let flightNumber = DOM.elid('oracle-flight-number').value;
            let timestamp = DOM.elid('oracle-timestamp').value;
            // Write transaction
            contract.fetchFlightStatus(airlineAddress, flightNumber, timestamp, (error, result) => {
                display('Oracles', 'Trigger oracles', [ { label: 'Fetch Flight Status', error: error, value: result.flight + ' ' + result.timestamp} ]);
            });
        })
    });
    
})();


function display(title, description, results) {
    let displayDiv = DOM.elid("display-wrapper");
    let section = DOM.section();
    section.appendChild(DOM.h2(title));
    section.appendChild(DOM.h5(description));
    results.map((result) => {
        let row = section.appendChild(DOM.div({className:'row'}));
        row.appendChild(DOM.div({className: 'col-sm-4 field'}, result.label));
        row.appendChild(DOM.div({className: 'col-sm-8 field-value'}, result.error ? String(result.error) : String(result.value)));
        section.appendChild(row);
    })
    displayDiv.append(section);

}







