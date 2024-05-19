// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Disperse is Ownable {
    using SafeERC20 for IERC20;

    constructor() Ownable(_msgSender()) {}

    function disperseToken(
        address _token,
        address[] calldata _recipients,
        uint256[] calldata _values
    ) public onlyOwner {
        require(
            _recipients.length == _values.length,
            "Disperse: Recipients and values length mismatch"
        );
        for (uint256 i = 0; i < _recipients.length; i++) {
            IERC20(_token).safeTransfer(_recipients[i], _values[i]);
        }
    }

    function disperseTokenPermissionless(
        address _token,
        address[] calldata _recipients,
        uint256[] calldata _values
    ) public {
        require(
            _recipients.length == _values.length,
            "Disperse: Recipients and values length mismatch"
        );
        for (uint256 i = 0; i < _recipients.length; i++) {
            IERC20(_token).safeTransferFrom(
                _msgSender(),
                _recipients[i],
                _values[i]
            );
        }
    }
}
