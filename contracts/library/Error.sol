//SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

library Error {

    error ZeroValue();
    error NotAuthorised();
    error IncorrectArrayLength();
    error UnAccountedETHBalance();
    error UnAccountedERC20Balance();

    enum Type { 
        ZeroValue,
        NotAuthorised,
        IncorrectArrayLength,
        UnAccountedETHBalance,
        UnAccountedERC20Balance
    }

    function emitError(Type _errorType) internal pure {
       if (_errorType == Type.ZeroValue) {
           revert ZeroValue();
       } else if (_errorType == Type.NotAuthorised) {
           revert NotAuthorised();
       } else if (_errorType == Type.IncorrectArrayLength) {
           revert IncorrectArrayLength();
       } else if (_errorType == Type.UnAccountedETHBalance) {
           revert UnAccountedETHBalance();
       } else if (_errorType == Type.UnAccountedERC20Balance) {
           revert UnAccountedERC20Balance();
       }
    }
}