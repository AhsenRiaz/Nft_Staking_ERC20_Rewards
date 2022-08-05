// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract CoinioRewards is ERC20, ERC20Burnable, Ownable {
    mapping(address => bool) private _controllers;

    uint256 constant MAXIMUM_SUPPLY = 1000000 * 10**18;

    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {
        _mint(msg.sender, 1000000 * 10**18);
    }

    function mint(address to, uint256 amount) external {
        require(
            _controllers[msg.sender],
            "CoinioRewards: only controllers can mint"
        );

        uint256 _totalSupply = totalSupply();

        require(
            (_totalSupply + amount) <= MAXIMUM_SUPPLY,
            "CoinioRewards: maximum supply reached"
        );

        _mint(to, amount);
    }

    function burnFrom(address account, uint256 amount) public override {
        if (_controllers[msg.sender]) {
            _burn(account, amount);
        } else {
            super.burnFrom(account, amount);
        }
    }

    function addController(address controller) external onlyOwner {
        _controllers[controller] = true;
    }

    function removeController(address controller) external onlyOwner {
        _controllers[controller] = false;
    }

    function maxSupply() public pure returns (uint256) {
        return MAXIMUM_SUPPLY;
    }
}
