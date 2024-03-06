// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../BondingsCore.sol";

contract BondingsCoreTest is BondingsCore {

    /**
     * This is a test contract that inherits from the BexCore contract. 
     * We disabled the signature verification here.
     */

    function disableSignatureMode() public override pure returns (bool) {
        return true;
    }
    
}