pragma solidity >=0.5.0;

interface GovernanceInterface {
    function lendingProxy() external view returns (address);

    function lotterySwap() external view returns (address);

    function hibachiStoreArbs() external view returns (address);

    function hibachiStore() external view returns (address);

    function randomness() external view returns (address);

    function lotteryDuration() external view returns (uint256);

    function admin() external view returns (address);

    function hibachiPrice() external view returns (uint256);

    function profitShare() external view returns (uint256);

    function fee() external view returns (uint256);
}
