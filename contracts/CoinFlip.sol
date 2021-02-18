pragma solidity 0.5.12;

// import "./Ownable.sol";
import "./api/provableAPI_0.5.sol";

/**
    1 - Need to wait for a while for flip response
    2 - Handle separate callbacks for different players
    3 - If the player has already performed a pending bet, has to wait 
 */



contract CoinFlip is usingProvable{

    uint public balance; //Automatically created a getter for balance
    uint public minimumBetAmount;

    uint256 constant NUM_RANDOM_BYTES_REQUESTED = 1;
    uint256 public latestNumber;


    struct Player {
        uint balance;
        uint betAmount;
        uint betChoice;
        bool isWaiting;
    }

    mapping (address => Player) public betters; //to check who's the player
    mapping (bytes32 => address) public pendingBets; //to check who's the sender of a pending bet 


    event PlacedBet(bytes32 betId, address sender, uint amount, uint choice);
    event ClosedBet(bytes32 betId, bool result);
    event WithdrownBalance(uint amount);
    event WithdrownFundsFromPlayer(address player, uint amount, uint contractBalance);
    event OccurredDeposit(address, uint);
    
    event LogNewProvableQuery(string description);
    event generatedRandomNumber(uint256 randomNumber);

    event DebugClosingBet(bytes32 betId, address playerAddress, bool waiting, uint choice, uint randomNumber);
    event DebugPlacingBet(bytes32 betId, address player);
    
    
    modifier costsAtLeast {
        require(msg.value >= minimumBetAmount , "Not enough stake");
        _;
    }

    constructor() public payable {
        balance += msg.value;
        minimumBetAmount = 0.01 ether;
    }
    
    function deposit() public payable returns(uint){
        balance += msg.value;

        emit OccurredDeposit(msg.sender, msg.value);

        return msg.value;
    }
    
    function withdrawFunds() public {
        require(msg.sender != address(0), "Inexistent address");
        require(betters[msg.sender].balance > 0, "Not enough funds to withdraw");
        require(betters[msg.sender].isWaiting == false, "This address still has an open bet");

        uint amt = betters[msg.sender].balance;
        msg.sender.transfer(amt);
        
        delete(betters[msg.sender]);
        
        emit WithdrownFundsFromPlayer(msg.sender, amt, balance);
    }

    // function withdrawAll() public onlyOwner returns(uint) {
    //     uint toTransfer = balance;
    //     balance = 0;
    //     msg.sender.transfer(toTransfer);

    //     emit WithdrownBalance(toTransfer);

    //     return toTransfer;
    // }

    // 0 - Head
    // 1 - Tails
    function placeBet(uint _choice) public payable costsAtLeast {
        require(msg.value*2 <= balance, "Contract hasn't enough funds to perform this bet");
        require(betters[msg.sender].isWaiting == false, "This address still has an open bet");
        require(_choice <= 1, "The parameter _choice must be 0 or 1");

        //balance += msg.value;
        
        bytes32 betId = update();
        pendingBets[betId] = msg.sender;
        betters[msg.sender].isWaiting = true;
        betters[msg.sender].betAmount = msg.value;
        betters[msg.sender].betChoice = _choice;
        
        emit PlacedBet(betId, msg.sender, msg.value, _choice);
        emit DebugPlacingBet(betId, pendingBets[betId]);
 
    }

    function closeBet(bytes32 _id, uint _result) internal returns(bool) {

        // address payable player = address(uint160(pendingBets[_id]));
        address player = pendingBets[_id];
        bool win = false;
        
        if (betters[player].betChoice == _result) {
            win = true;
            betters[player].balance += betters[player].betAmount;
            balance -= betters[player].betAmount;
            
            //player.transfer((betters[player].betAmount*2));
        } else {
            betters[player].balance -= betters[player].betAmount;
            balance += betters[player].betAmount;
        }
        
        emit DebugClosingBet(_id, pendingBets[_id], betters[pendingBets[_id]].isWaiting ,betters[pendingBets[_id]].betChoice, _result);

        betters[pendingBets[_id]].isWaiting = false;
        delete pendingBets[_id];

        emit ClosedBet(_id, win);

        return win;
    }

    function __callback( bytes32 queryId, string memory result, bytes memory proof) public {
        //require(msg.sender == provable_cbAddress());
        //require(provable_randomDS_proofVerify__returnCode(_queryId, _result, _proof) == 0, "Call not coming from the oracle");
        
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(result))) % 2;
        latestNumber = randomNumber;
        
        emit generatedRandomNumber(randomNumber);

        closeBet(queryId, randomNumber);
    }

    function update() internal returns (bytes32) {
        // uint256 QUERY_EXECUTION_DELAY = 0; 
        // uint256 GAS_FOR_CALLBACK = 200000; // Whenever the oracle has the response, we need to pay for the transaction to get the result in this contract

        //PRODUCTION MODE
        //bytes32 queryId = provable_newRandomDSQuery(QUERY_EXECUTION_DELAY, NUM_RANDOM_BYTES_REQUESTED, GAS_FOR_CALLBACK);

        //DEVELOPMENT MODE (comment in production)
        bytes32 queryId = dev_testRandomFunc();

        emit LogNewProvableQuery(
            "Provable query was sent, standing by for the answer..."
        );
        return queryId;
    }

    //DEVELOPMENT MODE (comment in production)
    function dev_testRandomFunc() internal returns(bytes32) {
        bytes32 queryId = bytes32(keccak256(abi.encodePacked(msg.sender)));
        __callback(queryId, "1", bytes("test"));
        return queryId;
    }


}





// pragma solidity 0.5.12;

// import { SafeMath } from './utils/SafeMath.sol';
// import "./api/provableAPI_0.5.sol";

// // A simple coin flip smart contract that uses 'Provable API' oracle to achieve randomness.
// // Oracle docs: https://docs.provable.xyz
// // Oracle GitHub: https://github.com/provable-things

// contract CoinFlip is usingProvable {

//   using SafeMath for uint;  

//   event LogNewProvableQuery(address indexed player);
//   event GeneratedRandomNumber(uint randomNumber);
//   event FlipResult(address indexed player, bool won, uint amountWon);
//   event BalanceUpdated(address user, uint depositAmount, uint newBalance);

//   constructor() public {
//     provable_setProof(proofType_Ledger);
//     contractBalance = 0;
//   }

//   struct Temp {
//     bytes32 id;
//     address playerAddress;
//   }

//   struct PlayerByAddress {
//     uint balance;
//     uint betAmount;
//     uint choice;
//     address playerAddress;
//     bool inGame;
//   }

//   mapping(bytes32 => Temp) public temps;
//   mapping(address => PlayerByAddress) public playersByAddress;

//   uint private constant NUM_RANDOM_BYTES_REQUESTED = 1;
//   uint private contractBalance;

//   // @dev               Initialize a new game.
//   // @notice            The value sent should be higher than 0 but less than the contract balance / 2,
//   //                    the contract pays double the bet if the user wins. A player can play one game at time.
//   // @param _choice     A binary choice.
//   function flip(uint _choice) payable public {
//     require(msg.value > 0 && msg.value <= _getContractBalance().div(2), "Cannot payout in case of a victory");
//     require(_choice <= 1, "The param _choice has to be 0 or 1");
//     require(_isPlaying(msg.sender) == false, "Currently in game");

//     playersByAddress[msg.sender].playerAddress = msg.sender;
//     playersByAddress[msg.sender].choice = _choice;
//     playersByAddress[msg.sender].betAmount = msg.value.sub(provable_getPrice("random")); // Contract keeps oracle's fee.
//     playersByAddress[msg.sender].inGame = true;

//     _update();
//   }

//   // @dev               Calls the oracle random function.
//   //                    Sets Temp for the given player.          
//   function _update() internal {
//     uint QUERY_EXECUTION_DELAY = 0;
//     uint GAS_FOR_CALLBACK =200000;
//     bytes32 query_id = provable_newRandomDSQuery(QUERY_EXECUTION_DELAY, NUM_RANDOM_BYTES_REQUESTED, GAS_FOR_CALLBACK);

//     temps[query_id].id = query_id;
//     temps[query_id].playerAddress = msg.sender;

//     emit LogNewProvableQuery(msg.sender);
//   }

//   // @dev               The callback function called by the oracle once the random number is created.    
//   // @param _queryId    The query unique identifier that is the key to the player Temp.
//   // @param _result     The random number generated by the oracle.
//   // @param _proof      Used to check if the result has been tampered.
//   function __callback(bytes32 _queryId, string memory _result, bytes memory _proof) public {
//     require(msg.sender == provable_cbAddress());

//     if (provable_randomDS_proofVerify__returnCode(_queryId, _result, _proof) == 0){
//       uint randomNumber = uint(keccak256(abi.encodePacked(_result)))%2;
//       _verifyResult (randomNumber, _queryId);
//       emit GeneratedRandomNumber(randomNumber);
//     }
//   }

//   // @dev               Verifies the flip result.
//   // @notice            Handle the player and contract balances based on the flip result.
//   // @param _randomNbr  The random number generated by the oracle.
//   // @param _queryId    The query unique identifier that is the key to the player Temp.
//   function _verifyResult (uint _randomNbr, bytes32 _queryId) internal {
//     address player = temps[_queryId].playerAddress;
//     if(_randomNbr == playersByAddress[player].choice){
//       playersByAddress[player].balance = playersByAddress[player].balance.add(playersByAddress[player].betAmount.mul(2));
//       contractBalance = contractBalance.sub(playersByAddress[player].betAmount.mul(2));
//       emit FlipResult (player, true, playersByAddress[player].betAmount.mul(2));
//     }else{
//       contractBalance = contractBalance.add(playersByAddress[msg.sender].betAmount);
//       emit FlipResult (player, false, 0);
//     }
//     delete(temps[_queryId]);
//     playersByAddress[player].betAmount = 0;
//     playersByAddress[player].inGame = false;
//   }

//   function withdrawFunds() public {
//     require(msg.sender != address(0));
//     require(playersByAddress[msg.sender].balance > 0);
//     require(!_isPlaying(msg.sender));

//     uint amt = playersByAddress[msg.sender].balance;
//     delete(playersByAddress[msg.sender]);
//     msg.sender.transfer(amt);
//     emit BalanceUpdated(msg.sender, amt, contractBalance);
//   }

//   function deposit() public payable {
//     require(msg.value > 0);

//     contractBalance = contractBalance.add(msg.value);
//     emit BalanceUpdated(msg.sender,msg.value,contractBalance);
//   }

//   function getPlayerBalance() public view returns (uint) {
//     return playersByAddress[msg.sender].balance;
//   }

//   function _getContractBalance() internal view returns (uint) {
//     return contractBalance;
//   }

//   function _isPlaying(address _player) internal view returns (bool) {
//     return playersByAddress[msg.sender].inGame;
//   }
// }