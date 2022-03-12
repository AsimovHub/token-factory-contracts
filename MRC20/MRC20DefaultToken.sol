// SPDX-License-Identifier: MIT
// Code written by n-three for Asimov Hub

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MRC20DefaultToken is ERC20 {
    uint8 private _decimals;

    constructor(address owner_, string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_) ERC20(name_, symbol_) {
        _decimals = decimals_;
        _mint(owner_, totalSupply_ * 10 ** decimals_);
    }

    function decimals() public view virtual override(ERC20) returns (uint8) {
        return _decimals;
    }

    function burn(uint256 amount) external virtual {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) external virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "MRC20DefaultToken: burn amount exceeds allowance");
    unchecked {
        _approve(account, _msgSender(), currentAllowance - amount);
    }
        _burn(account, amount);
    }

    function generator() external pure returns (string memory) {
        return "https://asimov.ac";
    }
}
