// SPDX-License-Identifier: MIT
// Code written by n-three for Asimov Hub

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MRC721OpenMintingDifferentContentToken is ERC721Enumerable, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;

    uint256 private _pricePerMint;

    string[] private _customTokenURIs;

    constructor(address owner_, string memory name_, string memory symbol_, uint256 pricePerMint_) ERC721(name_, symbol_) {
        _pricePerMint = pricePerMint_;
        _transferOwnership(owner_);
    }

    function mint() external payable returns (uint256) {
        require(!paused(), "Minting is paused");
        require(msg.value >= _pricePerMint, "You have not sent enough MTV");
        require(_customTokenURIs.length > totalSupply(), "No tokens to mint left");
        require(bytes(_customTokenURIs[_tokenIdTracker.current()]).length > 0, "Token is not ready yet. Tell this the creator");

        _mint(msg.sender, _tokenIdTracker.current());
        _tokenIdTracker.increment();
        return _tokenIdTracker.current() - 1;
    }

    function mintTo(address receiver_) external onlyOwner returns (uint256) {
        require(!paused(), "Minting is paused");
        require(_customTokenURIs.length > totalSupply(), "No tokens to mint left");
        require(bytes(_customTokenURIs[_tokenIdTracker.current()]).length > 0, "Token is not ready yet. You must set it.");
        uint256 tokenId = _tokenIdTracker.current();
        _mint(receiver_, tokenId);
        _tokenIdTracker.increment();
        return tokenId;
    }

    function getAdminTokenURI(uint256 tokenId_) external view onlyOwner returns (string memory) {
        return _customTokenURIs[tokenId_];
    }

    function getMintingPrice() external view returns (uint256) {
        return _pricePerMint;
    }

    function getTokenLimit() external view returns (uint256) {
        return _customTokenURIs.length;
    }

    function getSetTokens() external view onlyOwner returns (string[] memory) {
        return _customTokenURIs;
    }

    function setMintingPrice(uint256 pricePerMint_) external onlyOwner {
        _pricePerMint = pricePerMint_;
    }

    function setTokenURI(uint256 tokenId_, string memory tokenURI_) external onlyOwner {
        require(!_exists(tokenId_), "You cannot change minted tokens");
        require(tokenId_ == 0 || tokenId_ <= _customTokenURIs.length, "You can only set the token id of the next token or previously assigned tokens");
        require(bytes(tokenURI_).length > 0, "You cannot use an empty string");
        if (tokenId_ < _customTokenURIs.length) {
            _customTokenURIs[tokenId_] = tokenURI_;
        } else {
            _customTokenURIs.push(tokenURI_);
        }
    }

    function tokenURI(uint256 tokenId_) public view virtual override returns (string memory) {
        require(_exists(tokenId_), "Token does not exist");
        return _customTokenURIs[tokenId_];
    }

    function withdraw(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance);
        address payable to = payable(msg.sender);
        to.transfer(amount);
    }

    function pauseMinting() external onlyOwner {
        _pause();
    }

    function unpauseMinting() external onlyOwner {
        _unpause();
    }

    function isContractLocked() external view returns (bool) {
        return owner() == address(0);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function generator() external pure returns (string memory) {
        return "https://asimov.ac";
    }
}
