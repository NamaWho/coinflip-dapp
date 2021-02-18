pragma solidity 0.5.12;

contract Ownable {

    address owner;

    modifier onlyOwner {
        require(msg.sender == owner, "Function limited to the owner only");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }
}