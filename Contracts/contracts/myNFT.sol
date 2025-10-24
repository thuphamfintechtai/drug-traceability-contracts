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


    event ManufacturerToDistributor(address indexed manufacturerAddress, address indexed distributorAddress, uint []indexed tokenId, uint receivedTimestamp);
    event DistributorToPharmacy(address indexed distributorAddress, address indexed pharmacyAddress, uint [] indexed tokenId, uint receivedTimestamp);


    /*   VARIABLES        */

    uint256 private _tokenIds;



    /*          MAPPINGS            */

    mapping(uint256 => AddressTracking[]) public tokenIdTravelInfos;

    // Return A List Of IDs

    function mintNFT(string [] memory tokenURIs)
        public
        returns (uint256 [] memory)
    {
        uint256 [] memory tokenIds = new uint256[](tokenURIs.length);

        require(accessControlServiceObj.checkIsManufacturer(msg.sender), "Invalid Role: Only Manufacturer can mint");

        for(uint256 tokenURIIndex = 0 ; tokenURIIndex < tokenURIs.length;tokenURIIndex++)
        {
            _tokenIds++;
            uint256 newItemId = _tokenIds;
            _mint(msg.sender, newItemId);
            _setTokenURI(newItemId, tokenURIs[tokenURIIndex]);

            // Push into a array

            tokenIds[tokenURIIndex] = newItemId;
        }

        return tokenIds;
    }


    /*          TRANSFER TOKENID MANUFACTURER TO DISTRIBUTOR         */

    function manufacturerToDistributor(
        uint256 [] memory tokenId,
        address distributorAddress
    ) public {
        require(accessControlServiceObj.checkIsManufacturer(msg.sender), "Invalid Role: Only Manufacturer");
        require(accessControlServiceObj.checkIsDistributor(distributorAddress), "Invalid Target: Target is not a Distributor");
        require(
            accessControlServiceObj.isManufacturerDistributorApproved(msg.sender, distributorAddress),
            "Authority Not Approved: This relationship has not been approved by both parties"
        );

        for(uint256 i = 0;i<tokenId.length;i++)
        {
            require(ownerOf(tokenId[i]) == msg.sender, "ERC721: transfer from incorrect owner");
        }

        for(uint256 tokenIdValue = 0;tokenIdValue < tokenId.length;tokenIdValue++)
        {
            tokenIdTravelInfos[tokenId[tokenIdValue]].push(AddressTracking(
                accessControlServiceObj.MANUFACTURER_ROLE(),
                accessControlServiceObj.DISTRIBUTOR_ROLE(),
                msg.sender,
                distributorAddress,
                block.timestamp
            ));
        }
    
        emit ManufacturerToDistributor(msg.sender, distributorAddress, tokenId, block.timestamp);
    }

    /*            TRANSFER TOKENID DISTRIBUTOR TO PHARMACY                  */

    function distributorToPharmacy(
        uint256 [] memory tokenId,
        address pharmacyAddress
    ) public {
        require(accessControlServiceObj.checkIsDistributor(msg.sender), "Invalid Role: Only Distributor");

        require(accessControlServiceObj.checkIsPharmacy(pharmacyAddress), "Invalid Target: Target is not a Pharmacy");

        require(
            accessControlServiceObj.isDistributorPharmacyApproved(msg.sender, pharmacyAddress),
            "Authority Not Approved: This relationship has not been approved by both parties"
        );

        for(uint tokenIndexValue =0;tokenIndexValue < tokenId.length;tokenIndexValue++)
        {
            tokenIdTravelInfos[tokenId[tokenIndexValue]].push(AddressTracking(
                accessControlServiceObj.DISTRIBUTOR_ROLE(),
                accessControlServiceObj.PHARMACY_ROLE(),
                msg.sender,
                pharmacyAddress,
                block.timestamp
            ));
        }

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