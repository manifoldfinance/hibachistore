pragma solidity ^0.6.12;

interface KingRollInterface {
    function getEthToDaiProfit(uint256 totalProfit) external view returns (uint256 requiredAmt);

    function getTokenToDaiProfit(uint256 totalProfit) external view returns (uint256 requiredAmt);

    function getEthToDaiFee(uint256 totalAmt) external view returns (uint256 requiredAmt);

    function getTokenToDaifee(uint256 totalAmt) external view returns (uint256 requiredAmt);

    function swapEthToDai(
        address payable user,
        address hibachiFor,
        uint256 totalAmt,
        bool isFee,
        bool isIn
    ) external payable returns (uint256 leftAmt, uint256 hibachis);

    function swapTokenToDai(
        address user,
        address hibachiFor,
        address token,
        uint256 totalAmt,
        bool isFee,
        bool isIn
    ) external returns (uint256 leftAmt, uint256 hibachis);
}
