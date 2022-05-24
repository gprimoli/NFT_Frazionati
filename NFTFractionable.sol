// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./HolderList.sol";

contract OwnErc20 is ERC20, Ownable {
    uint256 public tokenID;
    address public nft;

    constructor(uint256 _tokenId, string memory name, string memory symbol) ERC20(name, symbol) {
        tokenID = _tokenId;
    }

    function mint(address addr, uint256 intBalance) onlyOwner external {
        nft = msg.sender;
        _mint(addr, intBalance);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount) internal override {
        FractionableNFT(nft).checkOwnership(from, to, amount, tokenID);
    }
}

contract FractionableNFT is ERC721, Ownable {
    uint256 private constant ONE_BILION = 1000000000 * 10 ** 18; //1.000.000.000 1 Bilion
    uint256 private constant ONE_QUARTER_OF_BILION = 250000000 * 10 ** 18; //250.000.000 1/4 Bilion = 25%

    struct NFTinfo {
        string url;
        HolderList holders;
        OwnErc20 fractions;
        mapping(address => bool) isBenificialOwner;
    } mapping(uint256 => NFTinfo) private _NFT_Infos;

    constructor(string memory name, string memory symbol) ERC721(name, symbol){}

    function splitInFraction(uint _tokenId, string memory name, string memory symbol) nftMustNotBeSplitted(_tokenId) external {
        require(ownerOf(_tokenId) == msg.sender, "You aren't the owner");
        _NFT_Infos[_tokenId].holders = new HolderList(msg.sender, ONE_BILION);

        _NFT_Infos[_tokenId].fractions = new OwnErc20(_tokenId, name, symbol);
        _NFT_Infos[_tokenId].fractions.mint(msg.sender, ONE_BILION);
    }

    function mint(address to, uint256 _tokenId, string memory url) onlyOwner external {
        require(bytes(url).length > 0, "You MUST insert a valid URL");
        _mint(to, _tokenId);
        _NFT_Infos[_tokenId].url = url;
        _NFT_Infos[_tokenId].isBenificialOwner[to] = true;
    }

    function checkOwnership(address from, address to, uint256 amount, uint256 _tokenId) external {
        uint256 balanceOfFrom = _NFT_Infos[_tokenId].fractions.balanceOf(from);
        uint256 balanceOfTo = _NFT_Infos[_tokenId].fractions.balanceOf(to);

        _NFT_Infos[_tokenId].holders.transact(from, balanceOfFrom + amount, balanceOfFrom, to, balanceOfTo - amount, balanceOfTo);

        address addressOfOwner = ownerOf(_tokenId);
        uint256 balanceOfOwner = _NFT_Infos[_tokenId].fractions.balanceOf(addressOfOwner);
        address addressOfRichest = _NFT_Infos[_tokenId].holders.getFirstRichest();
        uint256 balanceOfRichest = _NFT_Infos[_tokenId].fractions.balanceOf(addressOfRichest);


        if (balanceOfOwner < balanceOfRichest)
            _transfer(addressOfOwner, addressOfRichest, _tokenId);

        if (balanceOfTo >= ONE_QUARTER_OF_BILION)
            _NFT_Infos[_tokenId].isBenificialOwner[to] = true;

        if (balanceOfFrom < ONE_QUARTER_OF_BILION)
            _NFT_Infos[_tokenId].isBenificialOwner[from] = false;
    }


    /* Getter */
    function isBenificialOwner(address addr, uint256 _tokenId) nftMustExist(_tokenId) external view returns (bool) {
        return _NFT_Infos[_tokenId].isBenificialOwner[addr];
    }

    function fractionsOf(address addr, uint256 _tokenId) nftMustExist(_tokenId) nftMustBeSplitted(_tokenId) external view returns (uint256) {
        return _NFT_Infos[_tokenId].fractions.balanceOf(addr);
    }

    function getFractionalsContract(uint256 _tokenId) nftMustExist(_tokenId) nftMustBeSplitted(_tokenId) external view returns (address){
        return address(_NFT_Infos[_tokenId].fractions);
    }

    function getAllOwner(uint256 _tokenId) external view returns (address[] memory owners){
        return _NFT_Infos[_tokenId].holders.getAllRichest();
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked("https://ipfs.io/ipfs/", _NFT_Infos[tokenId].url));
    }

    /* Modifier */
    modifier nftMustExist(uint256 _tokenId) {
        require(_exists(_tokenId), "NFT doesn't exist");
        _;
    }
    modifier nftMustBeSplitted(uint256 _tokenId) {
        require(address(_NFT_Infos[_tokenId].fractions) != address(0), "NFT isn't fractioned");
        _;
    }
    modifier nftMustNotBeSplitted(uint256 _tokenId) {
        require(address(_NFT_Infos[_tokenId].fractions) == address(0), "NFT already fractioned");
        _;
    }

    /* Gas Optimization */
}
