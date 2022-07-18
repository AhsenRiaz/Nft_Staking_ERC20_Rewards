// SPDX-License-Identifier: MIT LICENSE
pragma solidity 0.8.9;

interface IERC20Burnable {
    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount)  external;
}