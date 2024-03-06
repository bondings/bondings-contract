// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MockUSDB is ERC20, Ownable {
    constructor() ERC20("Bondings Mock USDB", "bmUSDB") Ownable(msg.sender) {
        _mint(msg.sender, 1_000_000 * (10 ** uint256(decimals())));
    }
    
    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function mint() public {
        _mint(msg.sender, 1_000 * (10 ** uint256(decimals())));
    }

    function mintAny(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
