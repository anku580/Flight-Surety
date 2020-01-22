pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    struct Airline {
        address airline;
        bool isRegistered;
        bool isFunded;
        uint256 voteCount;
        uint256 fundingAmount;
    }

    struct Flight {
        address airline;
        bool isRegistered;
        uint8 statusCode;
        string flight;
        uint256 departureDate;
        mapping (address => uint256) insuredPassengers;
    }


    address private contractOwner;   
    mapping(address => bool) private appContracts;
    address private appcontractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false

    uint256 private constant MIN_ETH = 10 ether;
    mapping(address => Airline) airlines;
    mapping(bytes32 => Flight) registeredFlights;
    mapping(address => uint256) insuredPassengerBalance;
    mapping(address => uint) voting;

    uint registeredAirlinesCount;
    uint airlinesCount;

    event AirlineRegistered(address airline);
    event AirlineVoted(uint256 voteCount);
    event AirlineToVote(address airline);
    event AirlineVoted(address airline);

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/


    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor
                                (
                                    address firstAirline
                                ) 
                                public 
    {
        contractOwner = msg.sender;
        // this.addAirline(firstAirline);
        // this.registerAirline(firstAirline, msg.sender);
        Airline memory registerAirline = Airline(firstAirline, false, false, 0, 0);
        airlines[firstAirline] = registerAirline;
        airlines[firstAirline].isRegistered = true;
        registeredAirlinesCount = registeredAirlinesCount.add(1);
        emit AirlineRegistered(firstAirline);
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

    modifier requireAirlineRegistered(address airline)
    {
        require(airlines[airline].isRegistered, "Airline Not registered");
        _;
    }

    modifier requireAirlineFunded(address airline)
    {
        require(airlines[airline].isFunded, "Airline Not Funded");
        _;
    }

    modifier requireAirlineFundedWithMinimumEthers(address airline)
    {
        require(airlines[airline].fundingAmount > MIN_ETH , "Minimum 10 ethers are required");
        _;
    }

    modifier requireFlightRegistered(bytes32 flightKey)
    {
        require(registeredFlights[flightKey].isRegistered, "Flight not registered");
        _;
    }

    modifier requireAppCaller()
    {
        require(appContracts[msg.sender], "Caller is not authorized");
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

    function addAirline
                    (
                        address airlineToRegister
                    )
                    external
                    requireIsOperational()
    {
        Airline memory registerAirline = Airline({
            airline : airlineToRegister,
            isRegistered : true,
            isFunded : false,
            voteCount : 0,
            fundingAmount : 0
        });
        airlines[airlineToRegister] = registerAirline;
        airlinesCount = airlinesCount.add(1);
    }
   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */   
    function registerAirline
                            (
                                address airlineToRegister,
                                address registeredAirline
                            )
                            external
                            requireIsOperational()
                            requireAirlineRegistered(registeredAirline)
    {
        // require(airlines[airlineToRegister].isRegistered, "Airline is already registered" );
        airlines[airlineToRegister].isRegistered = true;
        registeredAirlinesCount = registeredAirlinesCount.add(1);
    }

    function vote
                (
                    address airlineToBeAdded
                )
                external 
                requireIsOperational()
                requireAirlineFunded(msg.sender)

    {
        airlines[airlineToBeAdded].voteCount++;
        voting[airlineToBeAdded]++;
        emit AirlineToVote(airlineToBeAdded);
        emit AirlineVoted(msg.sender);
        emit AirlineVoted(airlines[airlineToBeAdded].voteCount);
    }

    function fundAirline
                (
                    address airline,
                    uint256 value
                )
                external
                requireIsOperational()
                requireAirlineRegistered(airline)
    {
        airlines[airline].fundingAmount += value;
        airlines[airline].isFunded = true;
    }

    function registerFlight
                           (
                               address airline,
                               string _flight,
                               uint256 _departureDate
                           )
                           external
                           requireAirlineRegistered(airline)
                           requireAirlineFunded(airline)
                           returns(bool)
    {
        if(airlines[airline].fundingAmount >= MIN_ETH)
        {
            bytes32 flightKey = getFlightKey(airline, _flight, _departureDate);
            // require(registeredFlights[flightKey] == false, "Flight is already registered");

            Flight memory addNewFlight = Flight(airline, true, 0, _flight, _departureDate);
            registeredFlights[flightKey] = addNewFlight;
            return true;
        }
        else
            return false;
    }   
   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy
                            (
                                address _airline,
                                string _flight,
                                uint256 _departureDate,
                                address passenger                             
                            )
                            external
                            payable
                            requireIsOperational
    {
        // address(this).transfer(msg.value);

        bytes32 flightKey = getFlightKey(_airline, _flight, _departureDate);
        registeredFlights[flightKey].insuredPassengers[passenger] = msg.value;
    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                    address _airline,
                                    string _flight,
                                    uint256 _departureDate,
                                    address passenger,
                                    uint multi
                                )
                                external
                                requireIsOperational
    {
        bytes32 flightKey = getFlightKey(_airline, _flight, _departureDate);
        insuredPassengerBalance[passenger] = multi.mul(registeredFlights[flightKey].insuredPassengers[passenger]);
        registeredFlights[flightKey].insuredPassengers[passenger] = 0;
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                                address insuredPassenger
                            )
                            external
                            payable
                            requireIsOperational()
    {
        require(insuredPassengerBalance[insuredPassenger] > 0, "The insured passenger does not have any balance");
        uint256 balance = insuredPassengerBalance[insuredPassenger];
        insuredPassenger.transfer(balance);
        insuredPassengerBalance[insuredPassenger] = 0;
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

   
    function getTotalVoteCount
                            (
                                address airline
                            )       
                            external
                            requireIsOperational()
                            returns(uint)                         
    {
        return(voting[airline]);
    }

    function getRegisteredAirlinesCount() external view requireIsOperational
    returns(uint256)
    {
        return registeredAirlinesCount;
    }

     function authorizeCaller(address app) external requireContractOwner
    {
        appContracts[app] = true;
    }

    /**
     * @dev Add an app contract that can call into this contract
     */
    function deauthorizeCaller(address app) external requireContractOwner
    {
        delete appContracts[app];
    }

    function isAirline
                        (
                            address airline
                        )
                        external
                        requireIsOperational
                        returns(uint256)
    {
        return airlines[airline].fundingAmount;     
    }

    function isAirlineFunded
                            (
                                address airline
                            )
                            external
                            requireIsOperational
                            returns(bool)
    {
        return airlines[airline].isFunded;
    }
}

