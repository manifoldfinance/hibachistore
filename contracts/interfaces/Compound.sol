pragma solidity ^0.6.2;

interface CTokenInterface {
    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function repayBorrowBehalf(address borrower, uint256 repayAmount) external returns (uint256); // For ERC20

    function liquidateBorrow(
        address borrower,
        uint256 repayAmount,
        address cTokenCollateral
    ) external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function balanceOf(address owner) external view returns (uint256 balance);

    function underlying() external view returns (address);
}

interface CETHInterface {
    function mint() external payable;

    function repayBorrow() external payable;

    function repayBorrowBehalf(address borrower) external payable;

    function liquidateBorrow(address borrower, address cTokenCollateral) external payable;
}

interface ComptrollerInterface {
    function enterMarkets(address[] calldata cTokens) external returns (uint256[] memory);

    function exitMarket(address cTokenAddress) external returns (uint256);

    function getAssetsIn(address account) external view returns (address[] memory);

    function getAccountLiquidity(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );
}