// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
    
import "forge-std/Test.sol";
import {PoolManagerSetUp} from "../helper/PoolManagerSetUp.sol";
import {PoolId, PoolIdLibrary} from "v4-core/libraries/PoolId.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {ISwapper} from "../../contracts/interface/ISwapper.sol";
import {Swapper} from "../../contracts/Swapper.sol";

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

    Swapper swapper;
    
    function setUp() override public {
        super.setUp();
        swapper = new Swapper(poolManager);
    }

    function testSwapSucceed() public {
        tokenA.approve(address(swapper), 100);
        IPoolManager.SwapParams memory params =
            IPoolManager.SwapParams({zeroForOne: true, amountSpecified: 100, sqrtPriceLimitX96: SQRT_RATIO_1_2});
        
        vm.expectEmit(true, true, false, true);
        emit Swap(id, address(swapper), 100, -98, 79228162514264329749955861424, 1 ether, -1, 3000);
        
        ISwapper(swapper).swap(key, params); 
    }
}