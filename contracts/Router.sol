//SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { VM } from "weiroll/contracts/VM.sol";
import { Assert, Error } from "./library/Assert.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract Router is VM, Initializable {

    address private _admin;

    modifier onlyAdmin() {
        Assert.check(msg.sender == _admin, Error.Type.NotAuthorised);
        _;
    }

    // TODO : Need to amend the function
    // Switch off the delegate call as it comes with a lot of serious vunerabilities.
    function execute(bytes32[] calldata commands, bytes[] calldata state) external onlyAdmin returns (bytes[] memory) {
        return _execute(commands, state);
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(address admin) external initializer {
        _admin = admin;
    }
}
