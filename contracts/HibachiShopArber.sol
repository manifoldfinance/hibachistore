
pragma solidity >=0.6.12;

import {IUniswapV2Callee} from '@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol';
import {IUniswapV2Pair} from '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import {Babylonian} from '@uniswap/lib/contracts/libraries/Babylonian.sol';

import  {UniswapV2Library} from './libraries/UniswapV2Library.sol';
import {IUniswapV1Factory} from './interfaces/V1/IUniswapV1Factory.sol';
import {IUniswapV1Exchange} from './interfaces/V1/IUniswapV1Exchange.sol';
import {IUniswapV2Router01} from'./interfaces/IUniswapV2Router01.sol';
import {GovernanceInterface} from './interfaces/governance.sol';
import {LotterySwapInterface} from './interfaces/lotterySwap.sol';
import {IERC20} from './interfaces/IERC20.sol';
import {IWETH} from './interfaces/IWETH.sol';
import {SafeMath} from './libraries/SafeMath.sol';

// HibachiShopArber is the arbitrage contract that deals with arbitrage opportunities per trade
// Right now the prize pool is long DAI,ETH,USDT,USDC
contract HibachiShopArber is IUniswapV2Callee {
    using SafeMath for uint256;
    address ethAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    IUniswapV1Factory immutable factoryV1;
    address immutable factory;
    IUniswapV2Router01 immutable router01;
    IWETH immutable WETH;
    GovernanceInterface public governance;
    uint256 ONE = 1000000000000000000; 
    
    constructor(
        address _factory,
        address _factoryV1,
        address router,
        address _governance
    ) public {
        factoryV1 = IUniswapV1Factory(_factoryV1);
        factory = _factory;
        router01 = IUniswapV2Router01(router); 
        WETH = IWETH(IUniswapV2Router01(router).WETH());
        governance = GovernanceInterface(_governance);
    }


     // calculateAmountForArbitrage calculates how much to arbitrage
    function calculateAmountForArbitrage(address token, bool IsDirectionETHToToken) public view returns(uint256) {
        IUniswapV1Exchange exchangeV1 = IUniswapV1Exchange(factoryV1.getExchange(token));
        uint256 reserveETHV1 = address(exchangeV1).balance;
       uint256 reserveTokenV1 = IERC20(address(token)).balanceOf(address(exchangeV1)); 
       uint256 price;

        // get uniswapV2 reserves
       (uint256 reserveETHV2, uint256 reserveTokenV2) = UniswapV2Library.getReserves(factory, address(WETH), token);
        price = ((reserveTokenV1/reserveETHV1) + (reserveTokenV2/reserveETHV2))/2;
       (bool EthToToken, uint256 amountIn) = computeProfitMaximizingTrade(
                1, price,
                reserveETHV1, reserveTokenV1
        );

        require(EthToToken == IsDirectionETHToToken,"Direction invalid");

        return (amountIn);
    }

    // computeProfitMaximizingTrade computes the direction and magnitude of the profit-maximizing tradea
    function computeProfitMaximizingTrade(
        uint256 truePriceTokenA,
        uint256 truePriceTokenB,
        uint256 reserveA,
        uint256 reserveB
    ) pure public returns (bool aToB, uint256 amountIn) {
        aToB = reserveA.mul(truePriceTokenB) / reserveB < truePriceTokenA;

        uint256 invariant = reserveA.mul(reserveB);

        uint256 leftSide = Babylonian.sqrt(
            invariant.mul(aToB ? truePriceTokenA : truePriceTokenB).mul(1000) /
            uint256(aToB ? truePriceTokenB : truePriceTokenA).mul(997)
        );
        uint256 rightSide = (aToB ? reserveA.mul(1000) : reserveB.mul(1000)) / 997;

        // compute the amount that must be sent to move the price to the profit-maximizing price
        amountIn = leftSide.sub(rightSide);
    }

    // gets tokens/WETH via a V2 flash swap, swaps for the ETH/tokens on V1, repays V2, and keeps the rest!
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external override {
        address[] memory path = new address[](2);
        uint amountToken;
        uint amountETH;
        { // scope for token{0,1}, avoids stack too deep errors
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        require(msg.sender == UniswapV2Library.pairFor(factory, token0, token1),"CS: Msg sender is not the uniswapV2 pair"); // ensure that msg.sender is actually a V2 pair
        require(amount0 == 0 || amount1 == 0,"CS: One of the amounts should be zero"); // this strategy is unidirectional
        path[0] = amount0 == 0 ? token0 : token1;
        path[1] = amount0 == 0 ? token1 : token0;
        amountToken = token0 == address(WETH) ? amount1 : amount0;
        amountETH = token0 == address(WETH) ? amount0 : amount1;
        }

        require(path[0] == address(WETH) || path[1] == address(WETH),"CS: Path should contain WETH address"); // this strategy only works with a V2 WETH pair
        IERC20 token = IERC20(path[0] == address(WETH) ? path[1] : path[0]);
        IUniswapV1Exchange exchangeV1 = IUniswapV1Exchange(factoryV1.getExchange(address(token))); // get V1 exchange

        if (amountToken > 0) {
            // we have tokens on loan which we want to swap for ETH on V1 and return the ETH as WETH back to V2
            (uint minETH) = abi.decode(data, (uint)); // slippage parameter for V1, passed in by caller
            token.approve(address(exchangeV1), amountToken);
            uint amountReceived = exchangeV1.tokenToEthSwapInput(amountToken, minETH, uint(-1));           
            uint amountRequired = UniswapV2Library.getAmountsIn(factory, amountToken, path)[0];
            require(amountReceived > amountRequired,"CS: Not enough ETH to payback loan"); // fail if we didn't get enough ETH back to repay our flash loan
            WETH.deposit{value: amountRequired}();
            require(WETH.transfer(msg.sender, amountRequired),"CS: Flash loan repayment failed"); // return WETH to V2 pair

            // TODO we can remove this as its the same contract
            (bool success,) = sender.call{value: amountReceived - amountRequired}(new bytes(0)); // keep the rest! (ETH)
            require(success,"ETH transfer failed");
        } else {
            (uint minTokens) = abi.decode(data, (uint)); // slippage parameter for V1, passed in by caller
            WETH.withdraw(amountETH);
            uint amountReceived = exchangeV1.ethToTokenSwapInput{value: amountETH}(minTokens, uint(-1));
            uint amountRequired = UniswapV2Library.getAmountsIn(factory, amountETH, path)[0];
            require(amountReceived > amountRequired,"CS: Not enough tokens to payback loan"); // fail if we didn't get enough tokens back to repay our flash loan
            require(token.transfer(msg.sender, amountRequired),"CS: Paying back loan failed"); // return tokens to V2 pair
            // TODO: Remove this as its the same contract
            require(token.transfer(sender, amountReceived - amountRequired),"CS: Token transfer to original transfer failed"); // keep the rest! (tokens)
        }
    }
    function _ethToTokenArbs(
        uint256 existingTokens,
        address token,
        IUniswapV1Exchange exchangeV1,
        uint slippageParam,
        uint arbAmt,
        bool withHibachi
    ) internal returns(uint numTokensObtained, uint leftProfit, uint numHibachi) {
        numTokensObtained =  existingTokens;
        uint256 EthBeforeArb;
        IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(factory, address(WETH), token));
        // Now we want to borrow tokens from V2 and trade them for ETH on V1 => return ETH to V2
        uint256 numOfTokensToBeTraded = arbAmt > 0 ? arbAmt : calculateAmountForArbitrage(token,false);
        // to get the profit we store number of tokens before arbing
        EthBeforeArb = address(this).balance;

        // finally we execute a arb to reduce slippage
        pair.swap((pair.token0() == address(token) ? numOfTokensToBeTraded : 0),(pair.token0() == address(token) ? 0 : numOfTokensToBeTraded), address(this), abi.encode(slippageParam));
        // revert if we didnt get profit
        require(address(this).balance > EthBeforeArb,"CS: Hibachi shop should have profit to split");
        uint profit = address(this).balance - EthBeforeArb;
        
        if (withHibachi) {
            (leftProfit, numHibachi) = LotterySwapInterface(governance.lotterySwap())
            .swapEthToDai{value: (profit)}(
                msg.sender, // Sender of the swap
                msg.sender, // Buy candies for addresss
                profit, // profit to split
                false, // candies are brought by fee or profit (fee=>true)
                true // to participate in lottery or not
            );
        } else {
            leftProfit = profit;
        }

        numTokensObtained = numTokensObtained + exchangeV1.ethToTokenSwapInput{value: leftProfit}(1, uint(-1));
        require(IERC20(token).transfer(msg.sender, numTokensObtained),"CS: Transfer tokens to original swapper failed");
    }

    function EthToTokenSwap(
        address token,
        uint256 deadline,
        uint256 minTokens,
        uint256 slippageParam,
        uint256 arbAmt,
        bool WithArb,
        bool withHibachi
    ) public payable returns(uint256 numTokensObtained, uint256 leftProfit, uint256 numHibachi){
        // get V1 contract exchange
        IUniswapV1Exchange exchangeV1 = IUniswapV1Exchange(factoryV1.getExchange(token));

        // execute original trade
        numTokensObtained = exchangeV1.ethToTokenSwapInput{value: msg.value}(minTokens, uint(-1));
        leftProfit;
        if (WithArb){
             (numTokensObtained, leftProfit, numHibachi) = _ethToTokenArbs(numTokensObtained,
                    token,
                    exchangeV1,
                    slippageParam,
                    arbAmt,
                    withHibachi
                );
        } else {
            if (withHibachi) {
                require(IERC20(token).approve(governance.lotterySwap(), numTokensObtained), "approve not successfull");
                (numTokensObtained, numHibachi) = LotterySwapInterface(governance.lotterySwap())
                    .swapTokenToDai(
                        msg.sender, // Sender of the swap
                        msg.sender, // Buy candies for addresss
                        token, // token address
                        numTokensObtained, // amount fee will be charged
                        true, // candies are brought by fee or profit(profit=>false)
                        true // to participate in lottery or not
                    );
            }
        }
    }

    function _TokenToEthHibachi(
        address token,
        uint profit,
        bool withHibachi
    ) internal returns (uint leftProfit, uint numHibachi){
        if (withHibachi) {
            require(IERC20(token).approve(governance.lotterySwap(), profit), "approve not successfull");
            (leftProfit, numHibachi) = LotterySwapInterface(governance.lotterySwap())
                    .swapTokenToDai(
                        msg.sender,
                        msg.sender,
                        token,
                        profit,
                        false,
                        true
                    );
        } else {
            leftProfit = profit;
        }
    }

    function _TokenToEthArbs(
        uint256 existingEth,
        address token,
        IUniswapV1Exchange exchangeV1,
        uint slippageParam,
        uint deadline,
        uint arbAmt,
        bool withHibachi
    ) internal returns(uint numEthObtained, uint leftProfit, uint numHibachi) {
        uint256 TokensBeforeArb;
        numEthObtained = existingEth;

        IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(factory, address(WETH), token));
        // Now we want to borrow ETH from V2 and trade them for TOKENS on V1 => return TOKENS to V2
        uint256 numOfEthToBeArbedWith = arbAmt > 0 ? arbAmt : calculateAmountForArbitrage(token,true);
        
        // to get the profit we store number of tokens before arbing
        TokensBeforeArb = IERC20(token).balanceOf(address(this));
        
        // finally we execute a arb to reduce slippage
        pair.swap((pair.token0() == address(token) ? 0 : numOfEthToBeArbedWith),(pair.token0() == address(token) ? numOfEthToBeArbedWith : 0),address(this),abi.encode(slippageParam));

        // revert if we didnt get profit
        require(IERC20(token).balanceOf(address(this))>TokensBeforeArb,"CS: Hibachi shop should have profit to split");
        uint profit = IERC20(token).balanceOf(address(this)) - TokensBeforeArb;
        
        (leftProfit, numHibachi) = _TokenToEthHibachi(token, profit, withHibachi);

        require(IERC20(token).approve(address(exchangeV1), leftProfit), "approve not successfull");
        numEthObtained = numEthObtained + IUniswapV1Exchange(factoryV1.getExchange(token)).tokenToEthSwapInput(leftProfit, 1, deadline);
        (bool success,) = (msg.sender).call{value: numEthObtained}(new bytes(0)); // keep the rest! (ETH)
        require(success,"ETH transfer failed");
    }

    function TokenToEthSwap(
        address token,
        uint256 tokensSold,
        uint256 deadline,
        uint256 minEth,
        uint256 slippageParam,
        uint256 arbAmt,
        bool WithArb,
        bool withHibachi
    ) public returns(uint256 numEthObtained, uint256 leftProfit, uint numHibachi) {   
        // get V1 contract exchange
        IUniswapV1Exchange exchangeV1 = IUniswapV1Exchange(factoryV1.getExchange(token));     
        // execute original trade
        require(IERC20(token).transferFrom(msg.sender,address(this),tokensSold),"transferFrom failed");
        require(IERC20(token).approve(address(exchangeV1), tokensSold),"transfer not successfull");
        numEthObtained = exchangeV1.tokenToEthSwapInput(tokensSold, minEth, deadline);
        leftProfit;
        if (WithArb){
            (numEthObtained, leftProfit, numHibachi) = _TokenToEthArbs(numEthObtained,
                                                token,
                                                exchangeV1,
                                                slippageParam,
                                                deadline,
                                                arbAmt,
                                                withHibachi
                                            );
        } else {
            if (withHibachi) {
                (numEthObtained, numHibachi) =  LotterySwapInterface(governance.lotterySwap())
                    .swapEthToDai{value: numEthObtained}(
                        msg.sender,
                        msg.sender,
                        numEthObtained,
                        true,
                        true
                    );
            }
        }
    }

    event Report(uint tokenBrought, uint profit, uint candiesBrought);
    /**
     * @dev Swap.
     * @param buyAddr buying token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAddr selling token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAmt selling token amount.
     * @param minBuyAmt min buy amount.
     * @param slippage slippage.
     * @param deadline deadline.
     * @param WithArb with arbs.
    */
    function swap(
        address buyAddr,
        address sellAddr,
        uint sellAmt,
        uint minBuyAmt,
        uint slippage,
        uint deadline,
        uint arbAmt,
        bool WithArb,
        bool withHibachi
    ) external payable returns(
        uint256 tokenBrought,
        uint256 profit,
        uint256 candiesBrought
    ) {
        if (buyAddr != ethAddr) {
            require(sellAmt == msg.value, "msg.value is not same");
            (tokenBrought, profit, candiesBrought) = EthToTokenSwap(
                buyAddr,
                deadline,
                minBuyAmt,
                slippage,
                arbAmt,
                WithArb,
                withHibachi
            );
        } else {
            (tokenBrought, profit, candiesBrought) = TokenToEthSwap(
                sellAddr,
                sellAmt,
                deadline,
                minBuyAmt,
                slippage,
                arbAmt,
                WithArb,
                withHibachi
            );
        }
        emit Report(tokenBrought, profit, candiesBrought);
    }
    
    // needs to accept ETH from any V1 exchange and WETH. ideally this could be enforced, as in the router,
    // but it's not possible because it requires a call to the v1 factory, which takes too much gas
    receive() external payable {}

    function approveTokenToHibachiShopArber(address token, uint256 amount) external {
       IERC20(address(token)).approve(address(this),amount); 
    }

    function getBalance(address token, uint amountSold, bool EtoT) public view returns(
       uint ethBalanceV1,
       uint tokenBalaceV1,
       uint ethBalanceV2,
       uint tokenBalaceV2
    ) {
       address exchangeV1 = address(IUniswapV1Exchange(factoryV1.getExchange(token)));
       ethBalanceV1 = exchangeV1.balance;
       tokenBalaceV1 = IERC20(address(token)).balanceOf(exchangeV1);
        (ethBalanceV2, tokenBalaceV2) = UniswapV2Library.getReserves(factory, address(WETH), token);

       if (EtoT) {
           uint _t1 = IUniswapV1Exchange(exchangeV1).getEthToTokenInputPrice(amountSold);
           ethBalanceV1 = ethBalanceV1.add(amountSold);
           tokenBalaceV1 = tokenBalaceV1.sub(_t1);
       } else {
           uint _e1 = IUniswapV1Exchange(exchangeV1).getTokenToEthInputPrice(amountSold);
           tokenBalaceV1 = tokenBalaceV1.add(amountSold);
           ethBalanceV1 = ethBalanceV1.sub(_e1);
       }
   }
}
