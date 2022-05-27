//SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

library Error {

    error ZeroValue();
    error NotAuthorised();

    enum Type { 
        ZeroValue,
        NotAuthorised
    }

    function emitError(Type _errorType) external pure {
       if (_errorType == Type.ZeroValue) {
           revert ZeroValue();
       } else if (_errorType == Type.NotAuthorised) {
           revert NotAuthorised();
       }
    }
}