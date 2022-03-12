// SPDX-License-Identifier: MIT
// Code written by n-three for Asimov Hub

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MRC721OpenMintingSameContentToken is ERC721Enumerable, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdTracker;

    string private _tokenURI;
    string private _tokenURISuffix;
    bool private _useTokenId;

    uint256 private _tokenLimit;
    uint256 private _pricePerMint;

    constructor(address owner_, string memory name_, string memory symbol_, string memory tokenURI_, uint256 tokenLimit_, uint256 pricePerMint_, bool useTokenId_) ERC721(name_, symbol_) {
        _tokenURI = tokenURI_;
        _tokenLimit = tokenLimit_;
        _pricePerMint = pricePerMint_;
        _useTokenId = useTokenId_;
        _transferOwnership(owner_);
    }

    function mint() external payable returns (uint256) {
        require(!paused(), "Minting is paused");
        require(msg.value >= _pricePerMint, "You have not sent enough MTV");
        require(_tokenLimit == 0 || totalSupply() < _tokenLimit, "Token limit reached");
        uint256 tokenId = _tokenIdTracker.current();
        _mint(msg.sender, tokenId);
        _tokenIdTracker.increment();
        return tokenId;
    }

    function mintTo(address receiver_) external onlyOwner returns (uint256) {
        require(!paused(), "Minting is paused");
        require(_tokenLimit == 0 || totalSupply() < _tokenLimit, "Token limit reached");
        uint256 tokenId = _tokenIdTracker.current();
        _mint(receiver_, tokenId);
        _tokenIdTracker.increment();
        return tokenId;
    }

    function getAdminTokenURI() external view onlyOwner returns (string memory) {
        return _tokenURI;
    }

    function getMintingPrice() external view returns (uint256) {
        return _pricePerMint;
    }

    function setMintingPrice(uint256 pricePerMint_) external onlyOwner {
        _pricePerMint = pricePerMint_;
    }

    function useTokenId() external view onlyOwner returns (bool) {
        return _useTokenId;
    }

    function toggleUseTokenId() external onlyOwner {
        _useTokenId = !_useTokenId;
    }

    function getTokenURISuffix() external view onlyOwner returns (string memory) {
        return _tokenURISuffix;
    }

    function setTokenURISuffix(string memory tokenURISuffix_) external onlyOwner {
        _tokenURISuffix = tokenURISuffix_;
    }
    
    function getTokenLimit() external view returns (uint256) {
        return _tokenLimit;
    }

    function setTokenLimit(uint256 tokenLimit_) external onlyOwner {
        require(tokenLimit_ == 0 || tokenLimit_ >= totalSupply(), "You cannot set a token limit smaller than the current supply");
        _tokenLimit = tokenLimit_;
    }

    function setTokenURI(string memory tokenURI_) external onlyOwner {
        _tokenURI = tokenURI_;
    }

    function tokenURI(uint256 tokenId_) public view virtual override returns (string memory) {
        require(_exists(tokenId_), "Token does not exist");

        if (_useTokenId) {
            return (bytes(_tokenURI).length > 0
                ?
                (bytes(_tokenURISuffix).length > 0
                    ?
                    string(abi.encodePacked(string(abi.encodePacked(string(abi.encodePacked(_tokenURI, "/")), tokenId_.toString())), _tokenURISuffix))
                    :
                    string(abi.encodePacked(string(abi.encodePacked(_tokenURI, "/")), tokenId_.toString()))
                )
                :
                "");
        } else {
            return _tokenURI;
        }
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
