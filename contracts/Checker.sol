//SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

contract Checker {

    function greaterThan(uint256 a, uint256 b) public pure returns(bool) {
        return a > b;
    }

    function greaterThanOrEqual(uint256 a, uint256 b) public pure returns(bool) {
        return a >= b;
    }

    function verifySuccessfulSharesIn(bytes calldata tuple, uint256 expectedBalance, uint256 shares) public pure {
        (uint256 ptMinted, uint256 ytMinted) = abi.decode(tuple, (uint256, uint256));
        require(greaterThanOrEqual(ytMinted, expectedBalance), "Not enough YT minted");
        require(greaterThanOrEqual(ptMinted, shares), "Not enough PT Minted");
    }
}
