//SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { Error } from "./Error.sol";

library Assert {

    function check(bool _conditionalStatement, Error.Type _error) internal pure {
        if (!_conditionalStatement) {
            Error.emitError(_error);
        }
    }
}