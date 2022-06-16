import { expect } from "chai";
import { ethers } from "hardhat";
import { Signer } from "ethers";
import { impersonate, stopImpersonating } from "./helpers/impersonate";
import { Contract, Planner, CommandFlags } from "weiroll.js";

import { InterestTokenFactory__factory } from "typechain-types/factories/elf-smart-contracts/contracts/factories/InterestTokenFactory__factory";
import { TrancheFactory__factory } from "typechain-types/factories/elf-smart-contracts/contracts/factories/TrancheFactory__factory";
import { DateString__factory } from "typechain-types/factories/elf-smart-contracts/contracts/libraries/DateString__factory";
import { YVaultAssetProxy__factory } from "typechain-types/factories/elf-smart-contracts/contracts/YVaultAssetProxy__factory";
import { IERC20__factory } from "typechain-types/factories/@openzeppelin/contracts/token/ERC20/IERC20__factory";
import { IYearnVault__factory } from "typechain-types/factories/elf-smart-contracts/contracts/interfaces/IYearnVault__factory";
import { Router__factory } from "typechain-types/factories/contracts/Router__factory";
import { Checker__factory } from "typechain-types/factories/contracts/Checker__factory";
import { Tranche__factory } from "typechain-types/factories/elf-smart-contracts/contracts/Tranche__factory";
import { Router } from "typechain-types/contracts/Router";
import { TrancheFactory } from "typechain-types/elf-smart-contracts/contracts/factories/TrancheFactory";
import { IYearnVault } from "typechain-types/elf-smart-contracts/contracts/interfaces/IYearnVault";
import { IERC20 } from "typechain-types/@openzeppelin/contracts/token/ERC20/IERC20";
import { YVaultAssetProxy } from "typechain-types/elf-smart-contracts/contracts/YVaultAssetProxy";
import { Tranche } from "typechain-types/elf-smart-contracts/contracts/Tranche";
import { Checker } from "typechain-types/contracts/Checker";

describe("Router", function () {
  let router: Router;
  let trancheFactory: TrancheFactory;
  let yusdc: IYearnVault;
  let usdc: IERC20;
  let position: YVaultAssetProxy;
  let trancheAddress: string;
  let tranche: Tranche;
  let user1: Signer;
  let checker: Checker;

  async function deployChecker(signer: Signer) {
    const checkerDeployer = new Checker__factory(signer);
    return await checkerDeployer.deploy();
  }

  const deployInterestTokenFactory = async (signer: Signer) => {
    const deployer = new InterestTokenFactory__factory(signer);
    return await deployer.deploy();
  };

  const deployTrancheFactory = async (signer: Signer) => {
    const interestTokenFactory = await deployInterestTokenFactory(signer);
    const deployer = new TrancheFactory__factory(signer);
    const dateLibFactory = new DateString__factory(signer);
    const dateLib = await dateLibFactory.deploy();
    const deployTx = await deployer.deploy(
      interestTokenFactory.address,
      dateLib.address
    );
    return deployTx;
  };

  const deployYasset = async (
    signer: Signer,
    yUnderlying: string,
    underlying: string,
    name: string,
    symbol: string
  ) => {
    const yVaultDeployer = new YVaultAssetProxy__factory(signer);
    const signerAddress = await signer.getAddress();
    return await yVaultDeployer.deploy(
      yUnderlying,
      underlying,
      name,
      symbol,
      signerAddress,
      signerAddress
    );
  };

  before(async () => {
    const usdcAddress = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
    const yusdcAddress = "0x5f18C75AbDAe578b483E5F43f12a39cF75b973a9";
    const [signer] = await ethers.getSigners();
    const routerDeployer = new Router__factory(signer);
    router = await routerDeployer.deploy();
    user1 = (await ethers.getSigners())[1];

    checker = await deployChecker(signer);
    usdc = IERC20__factory.connect(usdcAddress, signer);
    yusdc = IYearnVault__factory.connect(yusdcAddress, signer);
    position = await deployYasset(
      signer,
      yusdc.address,
      usdc.address,
      "Element Yearn USDC",
      "eyUSDC"
    );
    trancheFactory = await deployTrancheFactory(signer);
    await trancheFactory.deployTranche(1e15, position.address);
    const eventFilter = trancheFactory.filters.TrancheCreated(null, null, null);
    const events = await trancheFactory.queryFilter(eventFilter);
    trancheAddress = events[0] && events[0].args && events[0].args[0];
    tranche = Tranche__factory.connect(trancheAddress, signer);

    // get USDC
    const usdcWhaleAddress = "0xAe2D4617c862309A3d75A0fFB358c7a5009c673F";
    impersonate(usdcWhaleAddress);
    const usdcWhale = ethers.provider.getSigner(usdcWhaleAddress);
    await usdc.connect(usdcWhale).transfer(await user1.getAddress(), 2e11); // 200k usdc
    stopImpersonating(usdcWhaleAddress);
  });

  /**
   *  Decoded structure of below test case planner call.
           selector    flag       inputs       output             target address
        [  ----4-----   -1   --------6--------   -1   ----------------20----------------------
          '0xe63697c8   01   00 01 02 ff ff ff   ff   5f18c75abdae578b483e5f43f12a39cf75b973a9',  --- call
          '0x70a08231   02   01 ff ff ff ff ff   01   a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48',  --- staticall
          '0x85f45c88   81   03 ff ff ff ff ff   83   e909128d38077bebd996692916865a5c24bfb522',  --- call
          '0x77e2eefa   02   83 01 00 ff ff ff   ff   c6e7df5e7b4f2a278906862b61205850344d4e7d'   --- staticall
        ]
        [
          '0x0000000000000000000000000000000000000000000000000000002df2362124',
          '0x00000000000000000000000059b670e9fa9d0a427751af201d676719a970857b',  -- it get update with the balance of the position after the second command
          '0x0000000000000000000000000000000000000000000000000000000000000000',
          '0x00000000000000000000000070997970c51812dc3a010c7d01b50e0d17dc79c8'
        ]

        ----------------------------------------------------------------------------------------------
        for withdraw use below input - 

        [0x0000000000000000000000000000000000000000000000000000002df2362124, -- shares
        0x00000000000000000000000059b670e9fa9d0a427751af201d676719a970857b, -- position address
        0x0000000000000000000000000000000000000000000000000000000000000000   -- 0
        ]
        ----------------------------------------------------------------------------------------------
        for balanceOf use below input - 
        [0x00000000000000000000000059b670e9fa9d0a427751af201d676719a970857b] -- position address

        output - 

        Added at the index 1 of state array
        ----------------------------------------------------------------------------------------------
        for prefundedDeposit use below input - 

        [0x00000000000000000000000070997970c51812dc3a010c7d01b50e0d17dc79c8] -- user address


        output - 

        Update the index 3 with bytes value i.e 64 in length 
        ----------------------------------------------------------------------------------------------

        For verifySuccessfulSharesIn the input is 

        [
            <dynamic length data start from index 3>,                               -- tuple value
            <update balance in 2 call>,                                             -- balance queried in 2nd command
            0x0000000000000000000000000000000000000000000000000000002df2362124      -- shares
        ]
  */

  it("Successful execution of pipeline", async () => {
    // Create a new planner
    const yearnSharesPlanner = new Planner();
    // Create the wrapper contract for the weiroll.
    const wVault = Contract.createContract(yusdc);
    // Need to drive the tranche first. Maybe create a stateless contract for helpers function or we can drive manually as well.
    // create the wrapper contract tranche contract.
    const wTranche = Contract.createContract(tranche, CommandFlags.CALL);
    // Create the staticcall for the usdc.
    const wUsdc = Contract.createContract(usdc, CommandFlags.STATICCALL);
    // Create the staticcall for the Checker contract.
    const wChecker = Contract.createContract(checker, CommandFlags.STATICCALL);
    await usdc.connect(user1).approve(yusdc.address, 2e11);
    await yusdc.connect(user1).deposit(2e11, await user1.getAddress());
    const shares = await yusdc.balanceOf(await user1.getAddress());
    await yusdc.connect(user1).approve(router.address, shares);
    const approvalTokens = [
      { identifier: yusdc.address, amount: shares, receiver: router.address },
    ];
    yearnSharesPlanner.add(wVault.withdraw(shares, position.address, 0));
    console.log(`Yusdc address - ${yusdc.address}`);
    const retBalance = yearnSharesPlanner.add(
      wUsdc.balanceOf(position.address)
    );
    const ret = yearnSharesPlanner.add(
      wTranche.prefundedDeposit(await user1.getAddress()).rawValue()
    );
    yearnSharesPlanner.add(
      wChecker.verifySuccessfulSharesIn(ret, retBalance, shares)
    );
    const { commands, state } = yearnSharesPlanner.plan();
    console.log(commands);
    console.log(state);
    await router.connect(user1).execute(commands, state, approvalTokens, []);
  });
});
