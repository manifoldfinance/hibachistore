pragma solidity ^0.6.2;

interface LotterySwapInterface {
    function getEthToDaiProfit(uint totalProfit) external view returns(uint requiredAmt);
    function getTokenToDaiProfit(uint totalProfit) external view returns(uint requiredAmt);
    function getEthToDaiFee(uint totalAmt) external view returns(uint requiredAmt);
    function getTokenToDaifee(uint totalAmt) external view returns(uint requiredAmt);

    function swapEthToDai(
        address payable user,
        address hibachiFor,
        uint totalAmt,
        bool isFee,
        bool isIn
    ) external payable returns(uint leftAmt, uint candies);

    function swapTokenToDai(
        address user,
        address hibachiFor,
        address token,
        uint totalAmt,
        bool isFee,
        bool isIn
    ) external returns(uint leftAmt, uint candies);
}