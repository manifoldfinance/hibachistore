pragma solidity >=0.5.0;

interface IUniswapV1Exchange {
    function balanceOf(address owner) external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function removeLiquidity(
        uint256,
        uint256,
        uint256,
        uint256
    ) external returns (uint256, uint256);

    function tokenToEthSwapInput(
        uint256,
        uint256,
        uint256
    ) external returns (uint256);

    function ethToTokenSwapInput(uint256, uint256) external payable returns (uint256);

    function getEthToTokenInputPrice(uint256 eth_sold) external view returns (uint256);

    function getEthToTokenOutputPrice(uint256 tokens_bought) external view returns (uint256);

    function getTokenToEthInputPrice(uint256 tokens_sold) external view returns (uint256);

    function getTokenToEthOutputPrice(uint256 eth_bought) external view returns (uint256);
}
