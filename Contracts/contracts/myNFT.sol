// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./accessControl.sol";
import "./libraries/structsLibrary.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract MyNFT is ERC1155 {

    accessControlService public accessControlServiceObj;

    uint256 private _nextTokenId = 1;

    mapping(uint256 => AddressTracking[]) public tokenIdTravelInfos;

    mapping(address => mapping(address => bool)) distributorPharmacyContract;

    event ManufacturerToDistributor(address indexed manufacturerAddress, address indexed distributorAddress, uint256[] tokenIds, uint receivedTimestamp);
    event DistributorToPharmacy(address indexed distributorAddress, address indexed pharmacyAddress, uint256[] tokenIds, uint receivedTimestamp);
    event mintNFTEvent(address indexed manufactureAddress, uint256[] tokenIds);

    /*          CONTRACT EVENTS             */

    event distributorSignTheContractEvent(address indexed distributorAddress , address indexed pharmacyAddress , uint timespan);

    event pharmacySignTheContractEvent(address indexed pharmacyAddress , address indexed distributorAddress , uint timespan);


    /*         NFT MINTER           */

    event distributorMintNFTEvent(address indexed distributorAddress , uint tokenId , uint timespan);


    constructor(
        address _accessControlAddress,
        string memory _uri
    ) 
        ERC1155(_uri) 
    {
        require(_accessControlAddress != address(0), "Invalid access control address");
        accessControlServiceObj = accessControlService(_accessControlAddress);
    }

    /*               Hàm set lại URI                */

    function setURI(string memory _uri) public{
        require(accessControlServiceObj.isAdmin(msg.sender), "You Must be Admin to do this function");
        _setURI(_uri);
    }


    /*      Contract Service    */

    function distributorCreateAContract(address pharmacyAddress) public
    {
        require(accessControlServiceObj.checkIsDistributor(msg.sender) , "Address is not a distributor");
        require(accessControlServiceObj.checkIsPharmacy(pharmacyAddress) , "Address is not a Pharmacy");

        require(!distributorPharmacyContract[msg.sender][pharmacyAddress],"The Contract Is Already Signed (Distributor Func)");

        // Adding the contract Info 

        distributorPharmacyContract[msg.sender][pharmacyAddress] = false;

        emit distributorSignTheContractEvent(msg.sender , pharmacyAddress , block.timestamp);
    }

    function pharmacyConfirmTheContract(address distributorAddress) public {

        require(accessControlServiceObj.checkIsDistributor(distributorAddress) , "Address is not a distributor");
        require(accessControlServiceObj.checkIsPharmacy(msg.sender) , "Address is not a Pharmacy");

        require(!distributorPharmacyContract[distributorAddress][msg.sender],"The Contract Is Already Signed (Pharmacy Func)");

        distributorPharmacyContract[distributorAddress][msg.sender] = true;

        emit pharmacySignTheContractEvent(msg.sender , distributorAddress , block.timestamp);
    }


    /*                   Distributor Mint                      */
    // Chú thích
    // Kiểm tra xem hợp đồng có thật sự được ký hay chưa

    function distributorMintTheNFT(address pharmacyAddress) public{

        require(accessControlServiceObj.checkIsDistributor(msg.sender) , "Address is not a distributor");

        require(accessControlServiceObj.checkIsPharmacy(pharmacyAddress) , "Address is not a Pharmacy");

        require(distributorPharmacyContract[msg.sender][pharmacyAddress] , "The Contract is not signed yet !");

        // Mint NFT
        uint tokenId = _nextTokenId;
        _mint(msg.sender , tokenId , 1 , "");
        _nextTokenId++;


        emit distributorMintNFTEvent(msg.sender , tokenId , block.timestamp);


    }


    /*                  NFT MINTER               */

    function mintNFT(
        uint256[] memory amounts
    ) public {
        require(accessControlServiceObj.checkIsManufacturer(msg.sender), "Invalid Role: Only Manufacturer can mint");

        uint256 numToMint = amounts.length; 
        require(numToMint > 0, "Amount array cannot be empty");

        uint256 currentId = _nextTokenId; 

        uint256[] memory newIds = new uint256[](numToMint);

        for(uint256 i = 0; i < numToMint; i++) {
            newIds[i] = currentId + i;
        }

        _mintBatch(msg.sender, newIds, amounts, "");

        _nextTokenId = currentId + numToMint;
        
        emit mintNFTEvent(msg.sender, newIds);
    }


    function manufacturerTransferToDistributor(
        uint256[] memory tokenIds,
        uint256[] memory amount,
        address distributorAddress
    ) public {
        
        // --- 1. Kiểm tra vai trò ---
        require(accessControlServiceObj.checkIsManufacturer(msg.sender), "Caller is not a Manufacturer");
        require(accessControlServiceObj.checkIsDistributor(distributorAddress), "Receiver is not a Distributor");


        address[] memory owners = new address[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            owners[i] = msg.sender;
        }

        uint256[] memory balances = balanceOfBatch(owners, tokenIds);

        for (uint256 i = 0; i < balances.length; i++) {
            require(balances[i] >= amount[i], "Manufacturer: insufficient balance");
        }

        safeBatchTransferFrom(
            msg.sender,
            distributorAddress,
            tokenIds,
            amount,
            ""
        );
        uint timeSpan = block.timestamp;


        bytes32 fromRole = accessControlServiceObj.MANUFACTURER_ROLE();
        bytes32 toRole = accessControlServiceObj.DISTRIBUTOR_ROLE();

        for (uint i = 0; i < tokenIds.length; i++) {
            if (amount[i] > 0) { 
                tokenIdTravelInfos[tokenIds[i]].push(AddressTracking(
                    fromRole, toRole, msg.sender, distributorAddress, timeSpan
                ));
            }
        }

        emit ManufacturerToDistributor(msg.sender, distributorAddress, tokenIds, timeSpan);
    }


    function distributorTransferToPharmacy(
        address pharmaAddress,
        uint256[] memory tokenIds,
        uint256[] memory amount
    ) public {
        
        require(accessControlServiceObj.checkIsDistributor(msg.sender), "Caller is not a Distributor");

        require(accessControlServiceObj.checkIsPharmacy(pharmaAddress), "Receiver is not a Pharmacy");

        require(distributorPharmacyContract[msg.sender][pharmaAddress] , "The Contract is not exist or not signed by 2 side yet !");

        address[] memory owners = new address[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            owners[i] = msg.sender;
        }
        uint256[] memory balances = balanceOfBatch(owners, tokenIds);
        for (uint256 i = 0; i < balances.length; i++) {
            require(balances[i] >= amount[i], "Distributor: insufficient balance");
        }

        safeBatchTransferFrom(
            msg.sender,
            pharmaAddress,
            tokenIds,
            amount,
            ""
        );

        uint timeSpan = block.timestamp;


        bytes32 fromRole = accessControlServiceObj.DISTRIBUTOR_ROLE();
        bytes32 toRole = accessControlServiceObj.PHARMACY_ROLE();

        for (uint i = 0; i < tokenIds.length; i++) {
            if (amount[i] > 0) {
                tokenIdTravelInfos[tokenIds[i]].push(AddressTracking(
                    fromRole, toRole, msg.sender, pharmaAddress, timeSpan
                ));
            }
        }

        emit DistributorToPharmacy(msg.sender, pharmaAddress, tokenIds, timeSpan);
    }

    /*          THIS IS A OLD FUNCION OF BUSSNIESS LEVEL            */


            /*          Distributor confirm the NFT Transfer         */

    // function distributorConfirmTheNFT(
    //     address pharmaAddress ,
    //     uint [] memory tokenIds ,
    //     uint [] amount
    // ) public
    // {
    //     // Trước tiên kiểm tra xem coi Distributor có tồn tại trên hệ thống hay không

    //     require(accessControlServiceObj.checkIsDistributor(msg.sender) , "Distributor address is Invalid");

    //     require(accessControlServiceObj.checkIsDistributor(pharmaAddress) , "Pharma address is Invalid");

    //     for(uint256 index =0;index < tokenIds.length; index++)
    //     {
    //         // Tiến hành kiểm tra xem token có thực sự thuộc về manufacture hay không
    //         require(
    //             _ownerOf(tokenIds[index]) == pharmaAddress , "Token Is not Belong to this manufacture"
    //         );

    //         // Sau Khi lamf phaanf này tiếp tục ghi lên smart contract

    //         tokenIdTravelInfos[tokenIds[index]].push(AddressTracking(
    //             accessControlServiceObj.MANUFACTURER_ROLE(),
    //             accessControlServiceObj.DISTRIBUTOR_ROLE(),
    //             manufactureAddress,
    //             msg.sender,
    //             block.timestamp
    //         ));
    //     }

    //     emit ManufacturerToDistributor(manufactureAddress, msg.sender, tokenIds, block.timestamp);
    // }

            /*      Pharma confirm the NFT Transfer         */

    // function pharmaConfirmTheNFTTransfer(
    //     address distributorAddress ,
    //     uint [] memory tokenIds
    // ) public
    // {
    //     // Trước tiên kiểm tra xem coi Distributor có tồn tại trên hệ thống hay không

    //     require(accessControlServiceObj.checkIsDistributor(distributorAddress) , "Distributor address is Invalid");

    //     require(accessControlServiceObj.checkIsPharmacy(msg.sender) , "Pharmacy address is Invalid");

    //     for(uint256 index =0;index < tokenIds.length; index++)
    //     {
    //         // Tiến hành duyệt qua mảng vào tìm kiếm NFTs

    //         AddressTracking [] memory getTheNFTAddressTracking 
    //             = tokenIdTravelInfos[tokenIds[index]];

    //         // Tiến hành tìm vị trí cuối trong mảng

    //         AddressTracking memory getTheLastIndex = 
    //             getTheNFTAddressTracking[getTheNFTAddressTracking.length - 1];

    //         // Tiến hành tìm kiếm thông tin distributor có thật sự nằm trong chuỗi cung ứng hay không 

    //         require(getTheLastIndex
    //         .toUserType == accessControlServiceObj.DISTRIBUTOR_ROLE()
    //         && 
    //         getTheLastIndex.toUserAddress == distributorAddress , "Invalid Distributor , Distributor does not exits");

    //         tokenIdTravelInfos[tokenIds[index]].push(AddressTracking(
    //             accessControlServiceObj.DISTRIBUTOR_ROLE(),
    //             accessControlServiceObj.PHARMACY_ROLE(),
    //             distributorAddress,
    //             msg.sender,
    //             block.timestamp
    //         ));
    //     }

    //     emit DistributorToPharmacy(distributorAddress, msg.sender, tokenIds, block.timestamp);
    // }


    function getTrackingHistory(uint256 tokenId) 
        public 
        view 
        returns (AddressTracking[] memory) 
    {
        return tokenIdTravelInfos[tokenId];
    }

    function pharmacyGetContractInfoByDistributorAddress(address distributorAddress) public view returns(getContractInfoStruct memory) {

        bool isSigned = distributorPharmacyContract[distributorAddress][msg.sender];

        return getContractInfoStruct(
            distributorAddress,
            msg.sender,
            isSigned ? "Signed" : "Not Signed"
        );

    }

    function distributorGetContractByPharmacyAddress(address pharmacyAddress) public view returns(getContractInfoStruct memory){
        bool isSigned = distributorPharmacyContract[msg.sender][pharmacyAddress];

        return getContractInfoStruct(
            msg.sender,
            pharmacyAddress,
            isSigned ? "Signed" : "Not Signed"
        );

    }
}