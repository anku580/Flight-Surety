
var FlightSuretyApp = artifacts.require("FlightSuretyApp");
var FlightSuretyData = artifacts.require("FlightSuretyData");
var BigNumber = require('bignumber.js');

var Config = async function (accounts) {

    // These test addresses are useful when you need to add
    // multiple users in test scripts
    let testAddresses = [
        "0x69e1CB5cFcA8A311586e3406ed0301C06fb839a2",
        "0xF014343BDFFbED8660A9d8721deC985126f189F3",
        "0x0E79EDbD6A727CfeE09A2b1d0A59F7752d5bf7C9",
        "0x9bC1169Ca09555bf2721A5C9eC6D69c8073bfeB4",
        "0xa23eAEf02F9E0338EEcDa8Fdd0A73aDD781b2A86",
        "0x6b85cc8f612d5457d49775439335f83e12b8cfde",
        "0xcbd22ff1ded1423fbc24a7af2148745878800024",
        "0xc257274276a4e539741ca11b590b9447b26a8051",
        "0x2f2899d6d35b1a48a4fbdc93a37a72f264a9fca7",
        '0x85Cc736D9509b48DfdEA49d8141D3B33e6870aFA',
        '0x1fBd9A0445d7F80D1d6d5ff2Fe9EBf74ed470120',
        '0x40f98192BBB85FfEEF5371F60BeE3d32d3bb1B98',
        '0xcE034e0DD3162d1C7A9dc4A2Af8BDd7191271E8E',
        '0xf073400a484707eAaFA25c4337126fd2E52590dD',
        '0xA2E4bb51fdC98EB3618395C445Baa7B2C5E9cf44',
        '0xF91e2Af7c7D762814D6314F27B2f6cB3d1BE9AF8',
        '0xc059938A258AD9d608242736E145208779F5356B',
        '0x51a08C04B7B71102573091010677Bb351bb88a53',
        '0xfb0cB3e01F90fAE20E3543B0B33497572e18B084'
    ];


    let owner = accounts[0];
    let firstAirline = accounts[1];

    let flightSuretyData = await FlightSuretyData.new(firstAirline);
    let flightSuretyApp = await FlightSuretyApp.new(flightSuretyData.address);


    return {
        owner: owner,
        firstAirline: firstAirline,
        weiMultiple: (new BigNumber(10)).pow(18),
        testAddresses: testAddresses,
        flightSuretyData: flightSuretyData,
        flightSuretyApp: flightSuretyApp
    }
}

module.exports = {
    Config: Config
};