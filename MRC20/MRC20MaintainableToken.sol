// SPDX-License-Identifier: MIT
// This is a customized version of the following contract written by n-three for Asimov Hub
// OpenZeppelin Contracts v4.5.0 (token/ERC/ERC.sol)

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MRC20MaintainableToken is Context, IERC20, IERC20Metadata, AccessControlEnumerable {
    using SafeMath for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _burnFeePermille;

    bool _lockedMinting;
    bool _lockedContract;

    constructor(address owner_, string memory name_, string memory symbol_, uint8 decimals_, uint256 initialAmount_, uint256 burnFeePermille_) {
        require(burnFeePermille_ >= 0, "Burn fee cannot be smaller than zero. Where should those funds comes from?");
        require(burnFeePermille_ < 1000, "Burn fee cannot be greater than 999. What should be transferred?");
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _burnFeePermille = burnFeePermille_;

        _setupRole(DEFAULT_ADMIN_ROLE, owner_);
        _setupRole(MINTER_ROLE, owner_);

        if (initialAmount_ > 0) {
            _mint(owner_, initialAmount_ * 10 ** decimals_);
        }
    }

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        require(!_lockedMinting, "Minting is locked");
        require(!_lockedContract, "Contract is locked");
        _mint(to, amount);
    }

    function lockContract() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!_lockedContract, "Contract is already locked");
        _lockedContract = true;
        _lockedMinting = true;
    }

    function isContractLocked() external view returns (bool) {
        return _lockedContract;
    }

    function lockMinting() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!_lockedContract, "Contract is locked");
        _lockedMinting = true;
    }

    function isMintingLocked() public view returns (bool) {
        return _lockedMinting || _lockedContract;
    }

    function minter() public view returns (address) {
        if (getRoleMemberCount(MINTER_ROLE) < 1) {
            return address(0);
        }
        return getRoleMember(MINTER_ROLE, 0);
    }

    function removeMinter(address minterAddress_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!_lockedContract, "Contract is locked");
        revokeRole(MINTER_ROLE, minterAddress_);
    }

    function setMinter(address newMinter_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!_lockedContract, "Contract is locked");
         if (minter() != address(0)) {
            revokeRole(MINTER_ROLE, minter());
        }
        _setupRole(MINTER_ROLE, newMinter_);
    }

    function owner() external view returns (address) {
        if (getRoleMemberCount(DEFAULT_ADMIN_ROLE) < 1) {
            return address(0);
        }
        return getRoleMember(DEFAULT_ADMIN_ROLE, 0);
    }

    function setOwner(address newOwner_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!_lockedContract, "Contract is locked");
        revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, newOwner_);
    }

    function setBurnFeePermille(uint256 burnFeePermille_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!_lockedContract, "Contract is locked");
        require(burnFeePermille_ < 1000, "Burn fee cannot be greater than 999. What should be transferred?");
        _burnFeePermille = burnFeePermille_;
    }

    function getBurnFeePermille() external view returns (uint256) {
        return _burnFeePermille;
    }

    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) external {
        uint256 currentAllowance = _allowances[account][_msgSender()];
        require(currentAllowance >= amount, "MRC20MaintainableToken: burn amount exceeds allowance");
    unchecked {
        _approve(account, _msgSender(), currentAllowance - amount);
    }
        _burn(account, amount);
    }

    function name() external view virtual override returns (string memory) {
        return _name;
    }

    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() external view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner_, address spender_) external view virtual override returns (uint256) {
        return _allowances[owner_][spender_];
    }

    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "MRC20MaintainableToken: transfer amount exceeds allowance");
    unchecked {
        _approve(sender, _msgSender(), currentAllowance - amount);
    }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "MRC20MaintainableToken: decreased allowance below zero");
    unchecked {
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
    }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        uint256 permilleBase = 1000;
        require(sender != address(0), "MRC20MaintainableToken: transfer from the zero address");
        require(recipient != address(0), "MRC20MaintainableToken: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "MRC20MaintainableToken: transfer amount exceeds balance");

        if (_burnFeePermille > 0) {
            uint256 sentAmount = amount.div(permilleBase).mul(permilleBase.sub(_burnFeePermille));
            uint256 burnAmount = amount.sub(sentAmount);

            unchecked {
                _balances[sender] = senderBalance - sentAmount;
            }

            _balances[recipient] += sentAmount;
            emit Transfer(sender, recipient, sentAmount);

            if (burnAmount > 0) {
                _burn(sender, burnAmount);
            }
        } else {
            unchecked {
                _balances[sender] = senderBalance - amount;
            }
            _balances[recipient] += amount;
            emit Transfer(sender, recipient, amount);
        }
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "MRC20MaintainableToken: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "MRC20MaintainableToken: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "MRC20MaintainableToken: burn amount exceeds balance");
    unchecked {
        _balances[account] = accountBalance - amount;
    }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner_,
        address spender_,
        uint256 amount_
    ) internal virtual {
        require(owner_ != address(0), "MRC20MaintainableToken: approve from the zero address");
        require(spender_ != address(0), "MRC20MaintainableToken: approve to the zero address");

        _allowances[owner_][spender_] = amount_;
        emit Approval(owner_, spender_, amount_);
    }

    function generator() external pure returns (string memory) {
        return "https://asimov.ac";
    }
}

