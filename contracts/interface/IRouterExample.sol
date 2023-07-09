// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {BalanceDelta} from "v4-core/types/BalanceDelta.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {Currency} from "v4-core/libraries/CurrencyLibrary.sol";

interface IRouterExample is IERC1155Receiver {
   function swap(
        IPoolManager.PoolKey memory key,
        IPoolManager.SwapParams memory params
    ) external payable returns (BalanceDelta delta);

    function modifyPosition(
        IPoolManager.PoolKey memory key, 
        IPoolManager.ModifyPositionParams memory params
    ) external payable returns (BalanceDelta delta); 

    function donate(
        IPoolManager.PoolKey memory key,
        uint256 amount0,
        uint256 amount1
    ) external payable returns (BalanceDelta delta);

    function mint(Currency currency, uint256 amount) external returns (BalanceDelta delta);
    
    function burn(Currency currency, uint256 amount) external returns (BalanceDelta delta);
}