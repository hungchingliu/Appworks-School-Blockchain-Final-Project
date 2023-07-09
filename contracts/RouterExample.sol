// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IRouterExample} from "./interface/IRouterExample.sol";

import {CurrencyLibrary, Currency} from "v4-core/libraries/CurrencyLibrary.sol";
import {IERC20Minimal} from "v4-core/interfaces/external/IERC20Minimal.sol";

import {ILockCallback} from "v4-core/interfaces/callback/ILockCallback.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {BalanceDelta} from "v4-core/types/BalanceDelta.sol";


contract RouterExample is ILockCallback, IRouterExample {
    using CurrencyLibrary for Currency;

    IPoolManager public immutable manager;

    constructor(IPoolManager _manager) {
        manager = _manager;
    }

    enum Operation {Swap, ModifyPosition, Donate, Mint, Burn}

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

    function donate(IPoolManager.PoolKey memory key, uint256 amount0, uint256 amount1)
        external
        payable
        returns (BalanceDelta delta)
    {
        delta = abi.decode(manager.lock(abi.encode(CallbackData(Operation.Donate, msg.sender, key, abi.encode(amount0, amount1)))), (BalanceDelta));
    }

    function mint(Currency currency, uint256 amount) external returns(BalanceDelta delta) {
        IPoolManager.PoolKey memory emptyKey; 
        delta = abi.decode(manager.lock(abi.encode(CallbackData(Operation.Mint, msg.sender, emptyKey, abi.encode(currency, amount)))), (BalanceDelta));
    }
    
    function burn(Currency currency, uint256 amount) external returns(BalanceDelta delta){
        IPoolManager.PoolKey memory emptyKey;
        delta = abi.decode(manager.lock(abi.encode(CallbackData(Operation.Burn, msg.sender, emptyKey, abi.encode(currency, amount)))), (BalanceDelta));
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

        } else if (data.operation == Operation.Donate) {

            (uint256 amount0, uint256 amount1) = abi.decode(data.params, (uint256, uint256));
            delta = manager.donate(data.key, amount0, amount1);

        } else if (data.operation == Operation.Mint) {

            (Currency currency, uint256 amount) = abi.decode(data.params, (Currency, uint256));
            manager.mint(currency, address(this), amount);

            if (currency.isNative()) {
                manager.settle{value: uint128(amount)}(currency);
            } else {
                IERC20Minimal(Currency.unwrap(currency)).transferFrom(
                    data.sender, address(manager), uint128(amount)
                );
                manager.settle(currency);
            } 

            // already resolve delta by settle
            return abi.encode(delta);

        } else if (data.operation == Operation.Burn) {

            (Currency currency, uint256 amount) = abi.decode(data.params, (Currency, uint256));
            manager.setApprovalForAll(address(manager), true);
            manager.safeTransferFrom(address(this), address(manager), currency.toId(), amount, "");
            manager.setApprovalForAll(address(manager), false);
            manager.take(currency, data.sender, amount);
            // already resolve delta by take
            return abi.encode(delta);

        }
        
        // resolve flash account delta
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

    // supoort reveive ERC1155 token
    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
        external
        pure
        returns (bytes4)
    {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }

    function supportsInterface(bytes4) external pure returns (bool) {
        return true;
    }

    receive() external payable {}
}