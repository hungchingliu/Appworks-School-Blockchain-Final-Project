// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IRouter} from "./interface/IRouter.sol";

import {CurrencyLibrary, Currency} from "v4-core/libraries/CurrencyLibrary.sol";
import {IERC20Minimal} from "v4-core/interfaces/external/IERC20Minimal.sol";

import {ILockCallback} from "v4-core/interfaces/callback/ILockCallback.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {BalanceDelta} from "v4-core/types/BalanceDelta.sol";


contract Router is ILockCallback, IRouter {
    using CurrencyLibrary for Currency;

    IPoolManager public immutable manager;

    constructor(IPoolManager _manager) {
        manager = _manager;
    }

    enum Operation {Swap, ModifyPosition}

    struct CallbackData {
        Operation operation;
        address sender;
        IPoolManager.PoolKey key;
        bytes params;
    }

    function swap(
        IPoolManager.PoolKey memory key,
        IPoolManager.SwapParams memory params
    ) external payable returns (BalanceDelta delta) {
        delta =
            abi.decode(manager.lock(abi.encode(CallbackData(Operation.Swap, msg.sender, key, abi.encode(params)))), (BalanceDelta));

        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            CurrencyLibrary.NATIVE.transfer(msg.sender, ethBalance);
        }
    }
    
    function modifyPosition(IPoolManager.PoolKey memory key, IPoolManager.ModifyPositionParams memory params)
        external
        payable
        returns (BalanceDelta delta)
    {
        delta = abi.decode(manager.lock(abi.encode(CallbackData(Operation.ModifyPosition, msg.sender, key, abi.encode(params)))), (BalanceDelta));

        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            CurrencyLibrary.NATIVE.transfer(msg.sender, ethBalance);
        }
    }
    
    function lockAcquired(uint256, bytes calldata rawData) external returns (bytes memory) {
        require(msg.sender == address(manager));


        CallbackData memory data = abi.decode(rawData, (CallbackData));

        BalanceDelta delta;
        
        if(data.operation == Operation.Swap) {
            IPoolManager.SwapParams memory swapParams = abi.decode(data.params, (IPoolManager.SwapParams));
            delta = manager.swap(data.key, swapParams); 
        } else if (data.operation == Operation.ModifyPosition) {
            IPoolManager.ModifyPositionParams memory modifyPositionParams = abi.decode(data.params, (IPoolManager.ModifyPositionParams));
            delta = manager.modifyPosition(data.key, modifyPositionParams);
        }
        
        
        if (delta.amount0() > 0) {
            if (data.key.currency0.isNative()) {
                manager.settle{value: uint128(delta.amount0())}(data.key.currency0);
            } else {
                IERC20Minimal(Currency.unwrap(data.key.currency0)).transferFrom(
                    data.sender, address(manager), uint128(delta.amount0())
                );
                manager.settle(data.key.currency0);
            }
        }
        if (delta.amount1() > 0) {
            if (data.key.currency1.isNative()) {
                manager.settle{value: uint128(delta.amount1())}(data.key.currency1);
            } else {
                IERC20Minimal(Currency.unwrap(data.key.currency1)).transferFrom(
                    data.sender, address(manager), uint128(delta.amount1())
                );
                manager.settle(data.key.currency1);
            }
        }

        if (delta.amount0() < 0) {
            manager.take(data.key.currency0, data.sender, uint128(-delta.amount0()));
        }
        if (delta.amount1() < 0) {
            manager.take(data.key.currency1, data.sender, uint128(-delta.amount1()));
        }

        return abi.encode(delta);
    }
}