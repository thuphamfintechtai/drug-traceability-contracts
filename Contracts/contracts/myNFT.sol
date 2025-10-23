// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./accessControl.sol";
import "./libraries/structsLibrary.sol";

contract MyNFT is ERC721URIStorage {

    /* ACCESS CONTROL SERVICE VARIABLE      */
    accessControlService public accessControlServiceObj;



    constructor(address _accessControlAddress) ERC721("MyNFT", "NFT") {
        require(_accessControlAddress != address(0), "Invalid access control address");
        accessControlServiceObj = accessControlService(_accessControlAddress);
    }


    event ManufacturerToDistributor(address indexed manufacturerAddress, address indexed distributorAddress, uint indexed tokenId, uint receivedTimestamp);
    event DistributorToPharmacy(address indexed distributorAddress, address indexed pharmacyAddress, uint indexed tokenId, uint receivedTimestamp);


    /*   VARIABLES        */

    uint256 private _tokenIds;



    /*          MAPPINGS            */

    mapping(uint256 => AddressTracking[]) public tokenIdTravelInfos;

    function mintNFT(string memory tokenURI)
        public
        returns (uint256)
    {
        require(accessControlServiceObj.checkIsManufacturer(msg.sender), "Invalid Role: Only Manufacturer can mint");

        _tokenIds++;
        uint256 newItemId = _tokenIds;
        
        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }


    /*          MANUFACTURER TO DISTRIBUTOR         */

    function manufacturerToDistributor(
        uint256 tokenId,
        address distributorAddress
    ) public {
        require(accessControlServiceObj.checkIsManufacturer(msg.sender), "Invalid Role: Only Manufacturer");
        require(accessControlServiceObj.checkIsDistributor(distributorAddress), "Invalid Target: Target is not a Distributor");
        require(
            accessControlServiceObj.isManufacturerDistributorApproved(msg.sender, distributorAddress),
            "Authority Not Approved: This relationship has not been approved by both parties"
        );

        require(ownerOf(tokenId) == msg.sender, "ERC721: transfer from incorrect owner");
        
        tokenIdTravelInfos[tokenId].push(AddressTracking(
            accessControlServiceObj.MANUFACTURER_ROLE(),
            accessControlServiceObj.DISTRIBUTOR_ROLE(),
            msg.sender,
            distributorAddress,
            block.timestamp
        ));

        _transfer(msg.sender, distributorAddress, tokenId);

        emit ManufacturerToDistributor(msg.sender, distributorAddress, tokenId, block.timestamp);
    }



    function distributorToPharmacy(
        uint256 tokenId,
        address pharmacyAddress
    ) public {
        require(accessControlServiceObj.checkIsDistributor(msg.sender), "Invalid Role: Only Distributor");

        require(accessControlServiceObj.checkIsPharmacy(pharmacyAddress), "Invalid Target: Target is not a Pharmacy");

        require(
            accessControlServiceObj.isDistributorPharmacyApproved(msg.sender, pharmacyAddress),
            "Authority Not Approved: This relationship has not been approved by both parties"
        );

        require(ownerOf(tokenId) == msg.sender, "ERC721: transfer from incorrect owner");

        tokenIdTravelInfos[tokenId].push(AddressTracking(
            accessControlServiceObj.DISTRIBUTOR_ROLE(),
            accessControlServiceObj.PHARMACY_ROLE(),
            msg.sender,
            pharmacyAddress,
            block.timestamp
        ));

        _transfer(msg.sender, pharmacyAddress, tokenId);

        emit DistributorToPharmacy(msg.sender, pharmacyAddress, tokenId, block.timestamp);
    }

    function getTrackingHistory(uint256 tokenId) 
        public 
        view 
        returns (AddressTracking[] memory) 
    {
        return tokenIdTravelInfos[tokenId];
    }
}