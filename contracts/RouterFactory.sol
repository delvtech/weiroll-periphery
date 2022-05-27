//SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { Clones }  from "@openzeppelin/contracts/proxy/Clones.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IRouter } from "./interfaces/IRouter.sol";

contract RouterFactory is Ownable {

    /// Address of the implementation address whose clone will
    /// be created.
    address public implementation;

    /// Keep the list of routers corresponds to the msg.sender.
    /// [<who-owns-the-router>] => [router]
    mapping(address => address) private _routers;

    /// Emit when router get generated.
    event RouterGenerated(address _router, address _owner);

    /// Initialize the contract.
    /// @param routerImplementation Address of the router.
    constructor(address routerImplementation) {
        implementation = routerImplementation;
    }

    /// @notice Allows to generate the cheap clones of the (https://github.com/element-fi/weiroll-periphery/tree/main/Router.sol)[Router] contract.
    /// @return router Address of the generated clone.
    function generateRouter() external returns(address router) {
        // Create the salt using the `msg.sender`
        bytes32 salt = keccak256(abi.encode(msg.sender));
        // Create deterministic clone using the calculated salt.
        router = Clones.cloneDeterministic(implementation, salt);
        // Keep the address in the map to access it afterwards.
        _routers[msg.sender] = router;
        // Initialze the clone with the initial params.
        IRouter(router).initialize(msg.sender);
        emit RouterGenerated(router, msg.sender);
    }

    /// @notice Provides the address of the already created router for given address,i.e. `target`.
    /// @param target Address for whom router address gets queried.
    function getRouter(address target) external view returns (address router) {
        return _routers[target];
    }

    /// @notice Derive router address deterministically.
    /// @param derivedRouter Address of the derived router.
    function deriveRouter(address target) external view returns (address derivedRouter) {
        bytes32 salt = keccak256(abi.encode(target));
        return Clones.predictDeterministicAddress(implementation, salt);
    }
}