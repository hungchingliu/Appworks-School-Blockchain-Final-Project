// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
    
import "forge-std/Test.sol";
import {PoolManagerSetUp} from "./helper/PoolManagerSetUp.sol";
import {PoolId, PoolIdLibrary} from "v4-core/libraries/PoolId.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {Currency} from "v4-core/libraries/CurrencyLibrary.sol";
import {IRouter} from "../contracts/interface/IRouter.sol";
import {Router} from "../contracts/Router.sol";

contract SwapperTest is PoolManagerSetUp {
    
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

    Router router;
    
    function setUp() override public {
        super.setUp();
        router = new Router(poolManager);
    }

    function testSwapSucceed() public {
        tokenA.approve(address(router), 100);
        IPoolManager.SwapParams memory params =
            IPoolManager.SwapParams({
                zeroForOne: true,
                amountSpecified: 100,
                sqrtPriceLimitX96: SQRT_RATIO_1_2
            });
        
        vm.expectEmit(true, true, false, true);
        emit Swap(id, address(router), 100, -98, 79228162514264329749955861424, 1 ether, -1, 3000);
        
        IRouter(router).swap(key, params); 
    }

    function testModifyPositionSucceed() public {
        tokenA.approve(address(router), 100);
        tokenB.approve(address(router), 100);

        IPoolManager.ModifyPositionParams memory params = 
        IPoolManager.ModifyPositionParams({
            tickLower: 0,
            tickUpper: 60,
            liquidityDelta: 100
        });

        vm.expectEmit(true, true, false, true);
        emit ModifyPosition(id, address(router), 0, 60, 100);

        IRouter(router).modifyPosition(key, params);
    }

    function testDonateSucceed() public {
        tokenA.approve(address(router), 100);
        tokenB.approve(address(router), 100); 

        //vm.expectEmit(true, true, false, true)

        IRouter(router).donate(key, 100, 100);
    }

    function testMintSucceed() public {
        tokenA.approve(address(router), 100);
        IRouter(router).mint(Currency.wrap(address(tokenA)), 100);
    }

    function testBurnSucceed() public {
        tokenA.approve(address(router), 100);
        IRouter(router).mint(Currency.wrap(address(tokenA)), 100);
        
        IRouter(router).burn(Currency.wrap(address(tokenA)), 100);
    }

    function testGetSwapFeeAfterRemoveLiquidity() public {}

    function testGetDonateFeeAfterRemoveLiquidity() public {}
}