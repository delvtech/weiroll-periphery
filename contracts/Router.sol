//SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { VM } from "weiroll/contracts/VM.sol";
import { Assert, Error } from "./library/Assert.sol";
import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Some assumptions or recommendations - 
//
// Contract allowances can be changed using the `execute` function itself, No need to write
// explicit function for the same but it comes with its own caveat that it will allow anyone to change
// the provided allowaces by the contract. So it is recommended to provide allowances in the commands
// to make sure that transaction will go through.

// Because of the design of the contract it is also not recommended to send direct ETH in the contract, if
// sent, then it is recommended to sent through execute function call and at the end of the call all ETH funds
// should sent back to the msg.sender or to the designated address.

// TODO: Do we need a permit call version of the execute function?
contract Router is VM, ReentrancyGuard {

    using SafeERC20 for IERC20;


    struct Tokens {
        IERC20 identifier;
        uint256 amount;
        address receiver;
    }

    /// @dev TODO: Switch off the delegate call as it may come up with a lot of gateways to harm the system.
    /// @dev `approvalTokens` address should be unique to avoid mess up between balances query. TODO: Do we need to enforce this on-chain ?
    /// @param commands       Set of commands that get executed by this function, More details can be found (here)[https://github.com/element-fi/weiroll#weiroll]  
    /// @param state          State that will get used during the execution of the given `commands`. 
    /// @param approvalTokens List of ERC-20 tokens addresses that will be used during the execution of given commands.
    /// @return data          Data that would get return by the commands execution.
    function execute(
        bytes32[] calldata commands,
        bytes[]   calldata state,
        Tokens[]  calldata approvalTokens
    ) 
        external 
        payable
        nonReentrant
        returns (bytes[] memory data)
    {
        uint256 noOfApprovalTokens = approvalTokens.length;
        uint256[] memory selfBeforeBalances = new uint256[](noOfApprovalTokens);
        // Keep the before balance of the ETH
        uint256 beforeEthBalance = address(this).balance;
        // Transfer tokens to the contract from the user so further interaction can go
        // through the router contract.
        for (uint256 i = 0; i < noOfApprovalTokens; i++) {
            Tokens memory t = approvalTokens[i];
            // Calculate the before funds of the contract
            // TODO: Need to find a way to avoid this as it is expensive if the no. of tokens are higher.
            selfBeforeBalances[i] = t.identifier.balanceOf(address(this));
            // Check that receiver is not 0x0
            Assert.check(t.receiver != address(0), Error.Type.ZeroValue);
            // Move funds to the given receiver. It can be the `address(this)` or some other address as well.
            t.identifier.safeTransferFrom(msg.sender, t.receiver, t.amount);
        }
        data = _execute(commands, state);

        // Make sure at the end of the execution the balance delta is zero.
        for (uint256 i = 0; i < noOfApprovalTokens; i++) {
            Assert.check(selfBeforeBalances[i] == approvalTokens[i].identifier.balanceOf(address(this)), Error.Type.UnAccountedERC20Balance);
        }
        // Make sure the eth balance delta is remain zero.
        Assert.check(beforeEthBalance == address(this).balance, Error.Type.UnAccountedETHBalance);
        return data; 
    }

    // Allow this contract to receive ether during the transaction execution.
    // not recommend to send ether directly otherwise someone can extract it before
    // the original sender does.
    receive() external payable {}
   
}
