
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import {ERC20} from "openzeppelin/token/ERC20/ERC20.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {Currency} from "v4-core/libraries/CurrencyLibrary.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolManager} from "v4-core/PoolManager.sol";
import {PoolId, PoolIdLibrary} from "v4-core/libraries/PoolId.sol";
import {Fees} from "v4-core/libraries/Fees.sol";
import {PoolModifyPositionTest} from "v4-core/test/PoolModifyPositionTest.sol";

contract PoolManagerSetUp is Test {
    using PoolIdLibrary for IPoolManager.PoolKey;

    uint160 constant SQRT_RATIO_1_1 = 79228162514264337593543950336;
    uint160 constant SQRT_RATIO_1_2 = 56022770974786139918731938227;
    uint160 constant SQRT_RATIO_1_4 = 39614081257132168796771975168;
    uint160 constant SQRT_RATIO_4_1 = 158456325028528675187087900672;

    PoolManager poolManager;
    PoolModifyPositionTest modifyPositionRouter;

    ERC20 tokenA;
    ERC20 tokenB;

    IPoolManager.PoolKey key;
    PoolId id;

    function setUp() public virtual {
        poolManager = new PoolManager(500000);
        modifyPositionRouter = new PoolModifyPositionTest(poolManager);
    
        tokenA = new ERC20("ERC20 token A", "AAA");
        deal(address(tokenA), address(this), 1000 ether, true);
        tokenB = new ERC20("ERC20 token B", "BBB");
        deal(address(tokenB), address(this), 1000 ether, true);

        key = IPoolManager.PoolKey({
            currency0: Currency.wrap(address(tokenA)),
            currency1: Currency.wrap(address(tokenB)),
            fee: 3000,
            hooks: IHooks(address(0)),
            tickSpacing: 60
        });

        id = key.toId();
         
        poolManager.initialize(key, SQRT_RATIO_1_1);
        tokenA.approve(address(modifyPositionRouter), 10 ether);
        tokenB.approve(address(modifyPositionRouter), 10 ether);

        modifyPositionRouter.modifyPosition(
            key,
            IPoolManager.ModifyPositionParams({tickLower: -120, tickUpper: 120, liquidityDelta: 1 ether})
        );
    }
}
