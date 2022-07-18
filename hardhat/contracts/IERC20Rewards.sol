// SPDX-License-Identifier: MIT LICENSE
pragma solidity 0.8.9;

import "./IERC20Burnable.sol";
import "./IOwnable.sol";

interface IERC20Rewards is IERC20Burnable, IOwnable {
    function mint(address to, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    function addController(address controller) external;

    function removeController(address controller) external;
}
