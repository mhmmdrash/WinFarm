// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "https://github.com/Uniswap/v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol";
import "https://github.com/Uniswap/v2-core/blob/master/contracts/interfaces/IUniswapV2Factory.sol";

contract RenEthPool {

    address public immutable REN;
    address public immutable ROUTER;
    address public immutable WETH;
    address public immutable FACTORY;

    IUniswapV2Router02 public uniswaprouter;

    event log(uint amount, string message);

    constructor(address _ren, address _router, address _factory, address _weth) {
        REN = _ren;
        ROUTER = _router;
        WETH = _weth;
        FACTORY = _factory;
    }

    function addLiquidityForRenAndEth(uint amountA) external payable {
        IERC20(REN).transferFrom(msg.sender, address(this), amountA);
        IERC20(REN).approve(ROUTER, amountA);

        (uint amountToken, uint amountEth, uint liquidity) = IUniswapV2Router02(ROUTER).
        addLiquidityETH{value: msg.value}(
            REN,
            amountA,
            1,
            1,
            msg.sender,
            block.timestamp + 200
        );

        emit log(amountToken, "REN tokens added");
        emit log(amountEth, "ETH added");
        emit log(liquidity, "lp tokens minted");
    }

    function removeLiquidity() external {
        address pair = IUniswapV2Factory(FACTORY).getPair(REN,WETH);
        uint liquidity = IERC20(pair).balanceOf(msg.sender);
        IERC20(pair).transferFrom(msg.sender, address(this), liquidity);
        IERC20(pair).approve(ROUTER, liquidity);
        (uint amountToken, uint amountETH) = IUniswapV2Router02(ROUTER).removeLiquidityETH(
            REN,
            liquidity,
            1,
            1,
            msg.sender,
            block.timestamp + 200
        );

        emit log(amountToken, "REN token removed");
        emit log(amountETH, "ETH removed");
    }

    function swapExactRenForETH(uint amountA) external {
        IERC20(REN).transferFrom(msg.sender, address(this), amountA);
        IERC20(REN).approve(ROUTER, amountA);

        address[] memory path;
        path = new address[](2);
        path[0] = REN;
        path[1] = WETH;

        (uint[] memory amounts) = IUniswapV2Router02(ROUTER).swapExactTokensForETH(
            amountA,
            1,
            path,
            msg.sender,
            block.timestamp + 200
        );

        emit log(amounts[amounts.length - 1], "received");
    }
}
