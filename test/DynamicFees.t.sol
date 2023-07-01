// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {PoolId, PoolIdLibrary} from "v4-core/libraries/PoolId.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {Currency} from "v4-core/libraries/CurrencyLibrary.sol";
import {PoolManager} from "v4-core/PoolManager.sol";
import {PoolSwapTest} from "v4-core/test/PoolSwapTest.sol";
import {Deployers} from "./utils/Deployers.sol";
import {IDynamicFeeManager} from "v4-core/interfaces/IDynamicFeeManager.sol";
import {Fees} from "v4-core/libraries/Fees.sol";

contract DynamicFees is IDynamicFeeManager {
    uint24 internal fee;

    function setFee(uint24 _fee) external {
        fee = _fee;
    }

    function getFee(IPoolManager.PoolKey calldata) public view returns (uint24) {
        return fee;
    }
}

contract TestDynamicFees is Test, Deployers {
    using PoolIdLibrary for IPoolManager.PoolKey;

    DynamicFees dynamicFees = DynamicFees(
        address(
            uint160(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF)
                & uint160(
                    ~Hooks.BEFORE_INITIALIZE_FLAG & ~Hooks.AFTER_INITIALIZE_FLAG & ~Hooks.BEFORE_MODIFY_POSITION_FLAG
                        & ~Hooks.AFTER_MODIFY_POSITION_FLAG & ~Hooks.BEFORE_SWAP_FLAG & ~Hooks.AFTER_SWAP_FLAG
                        & ~Hooks.BEFORE_DONATE_FLAG & ~Hooks.AFTER_DONATE_FLAG
                )
        )
    );
    PoolManager manager;
    IPoolManager.PoolKey key;
    PoolSwapTest swapRouter;

    function setUp() public {
        DynamicFees impl = new DynamicFees();
        vm.etch(address(dynamicFees), address(impl).code);

        (manager, key,) = Deployers.createFreshPool(IHooks(address(dynamicFees)), Fees.DYNAMIC_FEE_FLAG, SQRT_RATIO_1_1);
        swapRouter = new PoolSwapTest(manager);
    }

    function testSwapFailsWithTooLargeFee() public {
        dynamicFees.setFee(1000000);
        vm.expectRevert(IPoolManager.FeeTooLarge.selector);
        swapRouter.swap(
            key, IPoolManager.SwapParams(false, 1, SQRT_RATIO_1_1 + 1), PoolSwapTest.TestSettings(false, false)
        );
    }

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

    function testSwapWorks() public {
        dynamicFees.setFee(123);
        vm.expectEmit(true, true, true, true, address(manager));
        emit Swap(key.toId(), address(swapRouter), 0, 0, SQRT_RATIO_1_1 + 1, 0, 0, 123);
        swapRouter.swap(
            key, IPoolManager.SwapParams(false, 1, SQRT_RATIO_1_1 + 1), PoolSwapTest.TestSettings(false, false)
        );
    }
}
