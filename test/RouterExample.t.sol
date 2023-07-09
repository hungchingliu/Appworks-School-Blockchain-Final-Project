// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
    
import "forge-std/Test.sol";
import {PoolManagerSetUp} from "./helper/PoolManagerSetUp.sol";
import {PoolId, PoolIdLibrary} from "v4-core/libraries/PoolId.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {Currency, CurrencyLibrary} from "v4-core/libraries/CurrencyLibrary.sol";
import {IRouterExample} from "../contracts/interface/IRouterExample.sol";
import {RouterExample} from "../contracts/RouterExample.sol";

contract RouterExampleTest is PoolManagerSetUp {
    using CurrencyLibrary for Currency;

    event Swap(
        PoolId indexed poolId,
        address indexed sender,
        int128 amount0,
        int128 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick,
        uint24 fee
    );

    event ModifyPosition(
        PoolId indexed id,
        address indexed sender,
        int24 tickLower,
        int24 tickUpper,
        int256 liquidityDelta
    );

    RouterExample routerExample;
    
    function setUp() override public {
        super.setUp();
        routerExample = new RouterExample(poolManager);
    }

    function testSwapSucceed() public {
        tokenA.approve(address(routerExample), 100);
        IPoolManager.SwapParams memory params =
            IPoolManager.SwapParams({
                zeroForOne: true,
                amountSpecified: 100,
                sqrtPriceLimitX96: SQRT_RATIO_1_2
            });
        
        vm.expectEmit(true, true, false, true);
        emit Swap(id, address(routerExample), 100, -98, 79228162514264329749955861424, 1 ether, -1, 3000);
        
        IRouterExample(routerExample).swap(key, params); 
    }

    function testAddLiquiditySucceed() public {
        tokenA.approve(address(routerExample), 100);
        tokenB.approve(address(routerExample), 100);

        IPoolManager.ModifyPositionParams memory params = 
        IPoolManager.ModifyPositionParams({
            tickLower: 0,
            tickUpper: 60,
            liquidityDelta: 100
        });

        vm.expectEmit(true, true, false, true);
        emit ModifyPosition(id, address(routerExample), 0, 60, 100);

        IRouterExample(routerExample).modifyPosition(key, params);
    }

    function testRemoveLiquiditySucceed() public {
        tokenA.approve(address(routerExample), 1 ether);
        tokenB.approve(address(routerExample), 1 ether);

        IPoolManager.ModifyPositionParams memory params = 
        IPoolManager.ModifyPositionParams({
            tickLower: 0,
            tickUpper: 60,
            liquidityDelta: 1 ether
        });

        vm.expectEmit(true, true, false, true);
        emit ModifyPosition(id, address(routerExample), 0, 60, 1 ether);

        IRouterExample(routerExample).modifyPosition(key, params);

        uint256 beforeBalance = tokenA.balanceOf(address(this));
        params = 
        IPoolManager.ModifyPositionParams({
            tickLower: 0,
            tickUpper: 60,
            liquidityDelta: -1 ether
        });

        vm.expectEmit(true, true, false, true);
        emit ModifyPosition(id, address(routerExample), 0, 60, -1 ether);

        IRouterExample(routerExample).modifyPosition(key, params);
        
        uint256 afterBalance = tokenA.balanceOf(address(this));

        console.log(afterBalance, beforeBalance);
        assertGt(afterBalance, beforeBalance);
    }

    function testDonateSucceed() public {
        tokenA.approve(address(routerExample), 100);
        tokenB.approve(address(routerExample), 100); 

        IRouterExample(routerExample).donate(key, 100, 100);
    }

    function testMintSucceed() public {
        tokenA.approve(address(routerExample), 100);
        IRouterExample(routerExample).mint(Currency.wrap(address(tokenA)), 100);

        assertEq(poolManager.balanceOf(address(routerExample), Currency.wrap(address(tokenA)).toId()), 100);
    }

    function testBurnSucceed() public {
        tokenA.approve(address(routerExample), 100);
        IRouterExample(routerExample).mint(Currency.wrap(address(tokenA)), 100);
        assertEq(poolManager.balanceOf(address(routerExample), Currency.wrap(address(tokenA)).toId()), 100);
         
        IRouterExample(routerExample).burn(Currency.wrap(address(tokenA)), 100);
        assertEq(poolManager.balanceOf(address(routerExample), Currency.wrap(address(tokenA)).toId()), 0);
    }
}