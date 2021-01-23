pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

import { DSMath } from "./libraries/DSMath.sol";

import { GovernanceInterface } from "./interfaces/governance.sol";
import { HibachiStoreInterface } from "./interfaces/hibachiStore.sol";
import { TokenInterface } from "./interfaces/token.sol";

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

contract Helpers is DSMath {
    address public factory;
    IUniswapV2Router01 public router01;
    GovernanceInterface public governance;
    TokenInterface public stableToken;
    TokenInterface public WETH;

    function getEthToDaiProfit(uint256 totalProfit) public view returns (uint256 requiredAmt) {
        uint256 hibachiPrice = governance.hibachiPrice();
        uint256 candyProfit = (totalProfit * 2) / 10;
        address[] memory paths = new address[](2);
        paths[0] = router01.WETH();
        paths[1] = address(stableToken);
        uint256[] memory amts = router01.getAmountsOut(candyProfit, paths);

        require(amts[1] >= hibachiPrice, "CS: Total amount was less than candy price");
        uint256 extraAmount = mod(amts[1], hibachiPrice);
        requiredAmt = extraAmount > ((hibachiPrice * 6) / 10)
            ? amts[1] + (hibachiPrice - extraAmount)
            : amts[1] - extraAmount;
    }

    function getEthToDaiFee(uint256 totalAmt) public view returns (uint256 requiredAmt) {
        uint256 candyFee = governance.fee();
        uint256 candyProfit = wmul(totalAmt, candyFee);
        uint256 hibachiPrice = governance.hibachiPrice();
        address[] memory paths = new address[](2);
        paths[0] = router01.WETH();
        paths[1] = address(stableToken);
        uint256[] memory amts = router01.getAmountsOut(candyProfit, paths);

        require(amts[1] >= hibachiPrice, "CS: Total amount was less than candy price");
        uint256 extraAmount = mod(amts[1], hibachiPrice);
        requiredAmt = extraAmount > ((hibachiPrice * 8) / 10)
            ? amts[1] + (candyFee - extraAmount)
            : amts[1] - extraAmount;
    }

    function getTokenToDaiProfit(address token, uint256 totalProfit) public view returns (uint256 requiredAmt) {
        uint256 hibachiPrice = governance.hibachiPrice();
        uint256 candyProfit = (totalProfit * 2) / 10;
        address[] memory paths = new address[](2);
        paths[0] = token;
        paths[1] = address(stableToken);
        uint256[] memory amts = router01.getAmountsOut(candyProfit, paths);

        require(amts[1] >= hibachiPrice, "CS: Total profit was less than candy price");
        uint256 extraAmount = mod(amts[1], hibachiPrice);
        requiredAmt = extraAmount > ((hibachiPrice * 6) / 10)
            ? amts[1] + (hibachiPrice - extraAmount)
            : amts[1] - extraAmount;
    }

    function getTokenToDaiFee(address token, uint256 totalAmt) public view returns (uint256 requiredAmt) {
        uint256 candyFee = governance.fee();
        uint256 candyProfit = wmul(totalAmt, candyFee);
        uint256 hibachiPrice = governance.hibachiPrice();
        address[] memory paths = new address[](2);
        paths[0] = token;
        paths[1] = address(stableToken);
        uint256[] memory amts = router01.getAmountsOut(candyProfit, paths);

        require(amts[1] >= hibachiPrice, "CS: Total amount was less than candy price");
        uint256 extraAmount = mod(amts[1], hibachiPrice);
        requiredAmt = extraAmount > ((hibachiPrice * 8) / 10)
            ? amts[1] + (hibachiPrice - extraAmount)
            : amts[1] - extraAmount;
    }
}

contract ArbsResolver is Helpers {
    event LogLeftAmount(uint256 amt);

    modifier isArbs {
        // require(msg.sender == governance.hibachiStoreArbs(), "not-hibachiStoreArbs-address");
        _;
    }

    function swapEthToDai(
        address payable user,
        address candyFor,
        uint256 totalAmt,
        bool isFee,
        bool isIn
    ) public payable isArbs returns (uint256 leftAmt, uint256 hibachis) {
        require(totalAmt == msg.value, "arbs: msg.value is not same");
        address[] memory paths = new address[](2);
        uint256 daiAmt;
        if (isFee) {
            daiAmt = getEthToDaiFee(totalAmt);
        } else {
            daiAmt = getEthToDaiProfit(totalAmt);
        }
        paths[0] = router01.WETH();
        paths[1] = address(stableToken);
        uint256 intialBal = address(this).balance;
        router01.swapETHForExactTokens.value(totalAmt)(daiAmt, paths, address(this), now + 1 days);
        uint256 finialBal = address(this).balance;
        stableToken.approve(governance.hibachiStore(), daiAmt);
        hibachis = HibachiStoreInterface(governance.hibachiStore()).buyHibachi(
            address(stableToken),
            daiAmt,
            candyFor, //TODO - have to set `to` address,
            isIn
        );
        uint256 usedAmt = sub(intialBal, finialBal);
        leftAmt = sub(totalAmt, usedAmt); // TODO -check this.
        if (isFee) {
            user.transfer(leftAmt);
        } else {
            msg.sender.transfer(leftAmt);
        }
        emit LogLeftAmount(leftAmt);
    }

    function swapTokenToDai(
        address user,
        address candyFor,
        address token,
        uint256 totalAmt,
        bool isFee,
        bool isIn
    ) public isArbs returns (uint256 leftAmt, uint256 hibachis) {
        TokenInterface tokenContract = TokenInterface(token);
        tokenContract.transferFrom(msg.sender, address(this), totalAmt);
        uint256 daiAmt;
        if (isFee) {
            daiAmt = getTokenToDaiFee(token, totalAmt);
        } else {
            daiAmt = getTokenToDaiProfit(token, totalAmt);
        }
        address[] memory paths = new address[](2);
        paths[0] = token;
        paths[1] = address(stableToken);
        uint256 intialBal = tokenContract.balanceOf(address(this));
        tokenContract.approve(address(router01), uint256(-1));
        router01.swapTokensForExactTokens(daiAmt, totalAmt, paths, address(this), now + 1 days);
        uint256 finialBal = tokenContract.balanceOf(address(this));
        stableToken.approve(governance.hibachiStore(), daiAmt);
        hibachis = HibachiStoreInterface(governance.hibachiStore()).buyHibachi(
            address(stableToken),
            daiAmt,
            candyFor, //TODO - have to set `to` address,
            isIn
        );
        uint256 usedAmt = sub(intialBal, finialBal);
        leftAmt = sub(totalAmt, usedAmt); // TODO -check this.
        if (isFee) {
            tokenContract.transfer(user, leftAmt);
        } else {
            tokenContract.transfer(msg.sender, leftAmt);
        }
        emit LogLeftAmount(leftAmt);
    }
}

contract LotterySwap is ArbsResolver {
    constructor(
        address _governance,
        address router,
        address token
    ) public {
        router01 = IUniswapV2Router01(router);
        factory = router01.factory();
        WETH = TokenInterface(IUniswapV2Router01(router).WETH());
        governance = GovernanceInterface(_governance);
        stableToken = TokenInterface(token);
    }

    receive() external payable {}
}
