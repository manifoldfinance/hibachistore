<<<<<<< HEAD
pragma solidity >=0.4.21 <0.7.0;

contract Migrations {
    address public owner;
    uint256 public last_completed_migration;
=======
pragma solidity ^0.5.0;

contract Migrations {
    address public owner;
    uint256 public lastCompletedMigration;

    modifier restricted() {
        if (msg.sender == owner) {
            _;
        }
    }
>>>>>>> 57993ef1ec6f9346f22ad42b0960b8ab147a88fd

    constructor() public {
        owner = msg.sender;
    }

<<<<<<< HEAD
    modifier restricted() {
        if (msg.sender == owner) _;
=======
    function setCompleted(uint256 completed) public restricted {
        lastCompletedMigration = completed;
>>>>>>> 57993ef1ec6f9346f22ad42b0960b8ab147a88fd
    }

    function setCompleted(uint256 completed) public restricted {
        last_completed_migration = completed;
    }
}
