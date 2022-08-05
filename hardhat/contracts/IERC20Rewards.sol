// SPDX-License-Identifier: MIT LICENSE
pragma solidity 0.8.9;


interface IERC20Rewards {
    function mint(address to, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    function addController(address controller) external;

    function removeController(address controller) external;
}
