// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {BalanceDelta} from "v4-core/types/BalanceDelta.sol";

interface IRouter {
   function swap(
        IPoolManager.PoolKey memory key,
        IPoolManager.SwapParams memory params
    ) external payable returns (BalanceDelta delta);

    function modifyPosition(
        IPoolManager.PoolKey memory key, 
        IPoolManager.ModifyPositionParams memory params
    ) external payable returns (BalanceDelta delta); 
}