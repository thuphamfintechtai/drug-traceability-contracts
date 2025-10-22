// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

import "./accessControl.sol";

import "./libraries/structsLibrary.sol";

contract MyNFT  is ERC721URIStorage{

    /*              VARIBLES        */

    uint256 private _tokenIds;

    accessControlService public accessControlServiceObj;

    bytes32 public ManufactorByte = keccak256("Manufactor");

    bytes32 public DistributorByte = keccak256("Distributor");

    bytes32 public PharmacyByte = keccak256("Pharmacy");

    /*              EVENTS              */

    event TrackingEvent(address _Distributor , uint256);

    /*              MAPPINGS            */

    mapping(uint256 => AddressTracking[]) public tokenIdTravelInfos;

    /*              CONTRUCTOR          */

    constructor(address initialOwner) ERC721("MyNFT", "NFT"){
        accessControlServiceObj = accessControlService(initialOwner);
    }


    /*              MINT NFT           */



    function mintNFT(address recipient, string memory tokenURI)
        public
        returns (uint256)
    {
        _tokenIds++;

        uint256 newItemId = _tokenIds;
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }


    /*           MANUFACTOR TO DISTRIBUTOR                  */

    function manufactorToDistributor(uint256 tokenId ,address distributorAddress) public
    {

        // Checking For If It's Valid Distributor Addreess

        require(accessControlServiceObj.checkIsManufactor(msg.sender) , "Invalid Role");


        require(accessControlServiceObj.checkManufactorAuthorityDistributor(distributorAddress)
        , "Error Invalid Authority"); 


        tokenIdTravelInfos[tokenId].push(AddressTracking(
            ManufactorByte,
            DistributorByte,
            msg.sender,
            distributorAddress ,
            block.timestamp
        ));
    }






}
