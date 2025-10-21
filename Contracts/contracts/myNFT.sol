// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./drugContract.sol";

contract MyNFT is  drugContractService, ERC721URIStorage{
    uint256 private _tokenIds;

    drugContractService drugContractServiceHelper;

    event TrackingEvent(address _Distributor , uint256);

    // Truyền vào địa chỉ của Ví để thêm vào 

    constructor(address initialOwner) ERC721("MyNFT", "NFT") onlyOwner {
        drugContractServiceHelper = drugContractService(initialOwner);
    }

    function mintNFT(address recipient, string memory tokenURI)
        public
        onlyOwner
        returns (uint256)
    {
        _tokenIds++;

        uint256 newItemId = _tokenIds;
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }

    function TransferDistributorToPharmacy(uint256 tokenId , address _Distributor) public onlyDistributor
    {
        tokenIdTravelInfos[tokenId] = _Distributor;
    }

    function TransferManufactureToDistributor(uint256 tokenId , address _Manufacture) public onlyManufacture{
        tokenIdTravelInfos[tokenId] = _Manufacture;
    }
}
