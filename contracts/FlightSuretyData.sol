pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    address[] private registeredAirlinesAddress;

     struct Flight {
        string code;
        string from;
        string to;
        bool isRegistered;
        bool isInsured;
        uint8 statusCode;
        uint256 departureDate;
        address airline;
        address[] insuredPassengers;
    }

    struct Insurance {
        bytes32 flightHash;
        int amount;
    }

    bool private operational = true;               // Blocks all state changes throughout the contract if false

    mapping (address => bool) private registeredAirlines;
    mapping (address => address[]) private voteToAddAirline;
    mapping(address => uint) private fundedAirlines;
    mapping(bytes32 => Flight) private registeredFlights;
    mapping(address => Insurance[]) private passengersInsuredFlights;

    uint256 public constant MIN_FLIGHT_FUND_AMOUNT = 10 ether;
    uint256 public constant MAX_FLIGHT_INSURANCE = 1 ether;


    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/


    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor
                                (
                                    address airline
                                ) 
                                public 
    {
        contractOwner = msg.sender;
        registeredAirlines[airline] = true;
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() 
    {
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    modifier requireIsAirlineRegisterd(address airline)
    {
        require(registeredAirlines[airline] == true, 'Airline not registered');
        _;
    }

    modifier requireIsAirlineFunded(address airline)
    {
        require(isAirlineFunded(airline) == true, 'Airline not funded the minimum amount');
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational() 
                            public 
                            view 
                            returns(bool) 
    {
        return operational;
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus
                            (
                                bool mode
                            ) 
                            external
                            requireContractOwner 
    {
        operational = mode;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */   
    function registerAirline
                            (
                                address airline   
                            )
                            external
                            requireIsOperational
                            returns(bool success)
    {
        require(airline != address(0), 'Please provide a valid address');
        registeredAirlines[airline] = true;
        registeredAirlinesAddress.push(airline);
        return registeredAirlines[airline];
    }

    function isAirlineRegistered( address airline) public view returns(bool) {
        
        return registeredAirlines[airline];
    }

    function AirlinesCurrentlyRegistered() public view returns(uint256) {

        return registeredAirlinesAddress.length;
    }

    function voteToAirline(address airline, address callerAirline) requireIsOperational public view {

        voteToAddAirline[airline].push(callerAirline);
    }

    function getTotalVotes(address airline) public view returns(uint256) {

        return voteToAddAirline[airline].length;
    }

    function isAirlineVoted(address airline, address callerAirline) requireIsOperational public view returns(bool) {
        bool isVoted = false;
        uint8 i = 0;
        for(i=0; i < voteToAddAirline[airline].length; i++) {
            if(voteToAddAirline[airline][i] == callerAirline) {
                isVoted = true;
            }
        }
        return isVoted;
    }

    function fundAirline(address airline, uint price) 
                                                    public 
                                                    view
                                                    requireIsOperational
                                                    requireIsAirlineRegisterd(airline) 
    {
        fundedAirlines[airline] += price;
    }

    function isAirlineFunded(address airline) 
                                            public
                                            view
                                            requireIsOperational
                                            requireIsAirlineRegisterd(airline)  
                                            returns(bool) {
        if(fundedAirlines[airline] >= MIN_FLIGHT_FUND_AMOUNT) {
            return true;
        } else {
            return false;
        }
    }

    function registerFlight(string _flightCode, string _origin, string destination,
     uint256 _departureDate) external
        requireIsAirlineRegisterd(msg.sender)
        requireIsAirlineFunded(msg.sender) {

            bytes32 flightHash = getFlightKey(msg.sender, _flightCode, _departureDate);
            require(registeredFlights[flightHash].isRegistered == false, 'Flight already registered');

            Flight memory addNewFlight = Flight({
                code : _flightCode,
                from : _origin,
                to : _destination,
                isRegistered : true,
                isInsured : false,
                statusCode : 0,
                departureDate : _departureDate,
                airline : msg.sender,
                insuredPassengers : new address[](0)
            });

            registeredFlights[flightHash] = addNewFlight;
    }

    function alreadyInsured(address _airline, address _passenger, string _flightCode, uint256 _departureDate) external 
    {
        bytes32 flightHash = getFlightKey(_airline, _flightCode, _departureDate);
        bool insured = false;

        for(int i=0; i<passengersInsuredFlights[_passenger].length; i++)
        {
            if(passengersInsuredFlights[_passenger][i].flightHash == flightHash) {
                insured = true;
                break;
            }
        }

        return insured;
    }

    function buyInsurance(address _airline, string _flightCode, uint256 _departureDate) external payable
    {
        require(alreadyInsured(_airline, msg.sender, _flightCode, _departureDate) == false, 'Already Insured');
        require(msg.value <= 1 ether && msg.value > 0 ether, "Not enough ethers!!");
        bytes32 flightHash = getFlightKey(_airline, _flightCode, _departureDate);

        passengersInsuredFlights[msg.sender].push(new Insurance(flightHash, msg.value));

        Flight storage flight = registeredFlights[flightHash];
        flight.insuredPassengers.push(msg.sender);
    }

   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy
                            (
                                address airline,   
                                uint amount                          
                            )
                            external
                            requireIsOperational
                            payable
    {

    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                )
                                external
                                pure
    {
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                            )
                            external
                            pure
    {
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   
    function fund
                            ( 
                                address airline  
                            )
                            public
                            payable
    {
        require(msg.value >= MIN_FLIGHT_FUND_AMOUNT, 'Insufficient ethers to fund the airline');
        
    }

    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function() 
                            external 
                            payable 
    {
        fund();
    }


}

