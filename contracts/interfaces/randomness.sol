pragma solidity ^0.6.2;

interface RandomnessInterface {
    function randomNumber(uint256) external view returns (uint256);

    function getRandom(uint256, uint256) external;
}
