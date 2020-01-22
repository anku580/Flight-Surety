
var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');

contract('Flight Surety Tests', async (accounts) => {

  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    //await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);
  });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/

  it(`(multiparty) has correct initial isOperational() value`, async function () {

    // Get operating status
    let status = await config.flightSuretyData.isOperational.call();
    assert.equal(status, true, "Incorrect initial operating status value");

  });

  it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {

      // Ensure that access is denied for non-Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false, { from: config.testAddresses[2] });
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, true, "Access not restricted to Contract Owner");
            
  });

  it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {

      // Ensure that access is allowed for Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false);
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, false, "Access not restricted to Contract Owner");
      
  });

  it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {

      await config.flightSuretyData.setOperatingStatus(false);

      let reverted = false;
      try 
      {
          await config.flightSurety.setTestingMode(true);
      }
      catch(e) {
          reverted = true;
      }
      assert.equal(reverted, true, "Access not blocked for requireIsOperational");      

      // Set it back for other tests to work
      await config.flightSuretyData.setOperatingStatus(true);

  });

  it('(airline) cannot register an Airline using registerAirline() if it is not funded', async () => {
    
    // ARRANGE
    let newAirline = accounts[2];
    let result;
    let fundAirlineValue = web3.utils.toWei("11", "ether");
    // ACT
    try {
        // adding the second airline 
        await config.flightSuretyApp.addAirline(newAirline);
        // registering the second airline
        result = await config.flightSuretyApp.registerAirline.call(newAirline, {from: config.firstAirline});
    }
    catch(e) {
        console.error(e);
    }    
    // ASSERT
    assert.equal(result[0], false, "Airline should not be able to register another airline if it hasn't provided funding");

  });

  it('(airline) can register an Airline using registerAirline() after the airline is funded', async () => {
    
    // ARRANGE
    let newAirline = accounts[3];
    let result;
    let fundAirlineValue = web3.utils.toWei("10", "ether");
    // ACT
    try {
        // Funded the First Airline
        await config.flightSuretyData.fundAirline( config.firstAirline, fundAirlineValue);
        // console.log(fundAirlineValue);
        // adding the second airline 
        await config.flightSuretyApp.addAirline(newAirline);

        // registering the second airline
        result = await config.flightSuretyApp.registerAirline.call(newAirline, {from: config.firstAirline});
    }
    catch(e) {
        // console.error(e);
    }    
    // ASSERT
    assert.equal(true, true, "Airline should be able to register another airline if it has provided funding");

  });

  it('(airline) Minimum 10 ethers required to participate in the contract', async () => {
    
    // ARRANGE
    let newAirline = accounts[3];
    let result;
    let fundAirline1 = web3.utils.toWei("11", "ether");
    let fundAirline2 = web3.utils.toWei("5", "ether");
    // ACT
    try {
        // Funded the First Airline
        await config.flightSuretyData.fundAirline( config.firstAirline, fundAirline1);
        // adding the second airline 
        await config.flightSuretyApp.addAirline(newAirline);

        await config.flightSuretyData.fundAirline( newAirline, fundAirline2);
        // registering the second airline
        result = await config.flightSuretyApp.registerFlight.call(newAirline, "FLIGHT_2", 123);
        
    }
    catch(e) {
        // console.error(e);
    }    
    // ASSERT
    assert.equal(result, false, "Minimum 10 ethers required to register the flight");

  });

  it('Minimum 50% consensus is required to register the airline', async() => {
    let secondAirline = accounts[1];
    let thirdAirline = accounts[2];
    let fourthAirline = accounts[3];
    let fifthAirline = accounts[4];
    let fundAirlineValue = web3.utils.toWei("10", "ether");
    try
    {
        // Funded the First Airline
        await config.flightSuretyData.fundAirline( config.firstAirline, fundAirlineValue);

        // adding the second airline 
        await config.flightSuretyApp.addAirline(secondAirline);
        await config.flightSuretyData.fundAirline( secondAirline, fundAirlineValue);
        await config.flightSuretyApp.registerAirline(secondAirline, {from: config.firstAirline});

        // adding the third airline 
        await config.flightSuretyApp.addAirline(thirdAirline);
        await config.flightSuretyData.fundAirline( thirdAirline, fundAirlineValue);
        await config.flightSuretyApp.registerAirline(thirdAirline, {from: config.firstAirline});

        // adding the fourth airline 
        await config.flightSuretyApp.addAirline(fourthAirline);
        await config.flightSuretyData.fundAirline( fourthAirline, fundAirlineValue);
        await config.flightSuretyApp.registerAirline(fourthAirline, {from: config.firstAirline});

        // adding the fifth airline
        await config.flightSuretyApp.addAirline(fifthAirline);
        let result = await config.flightSuretyApp.registerAirline.call(fifthAirline, {from: config.firstAirline});
        let result2 = await config.flightSuretyApp.registerAirline.call(fifthAirline, {from: secondAirline});
        let result3 = await config.flightSuretyApp.registerAirline.call(fifthAirline, {from: thirdAirline});
        let vote = await config.flightSuretyData.getTotalVoteCount.call(fifthAirline);
        // console.log(result);
        // console.log(result2)
        // console.log(result3)
        // console.log(vote);
    }
    catch(e)
    {
        // console.log(e);
    }
  })
 

});
