// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./accessControl.sol";
import "./libraries/structsLibrary.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract MyNFT is ERC1155 {

    enum contractStatus {
        NOT_CREATED, 
        PENDING,    
        APPROVED,    
        SIGNED       
    }

    accessControlService public accessControlServiceObj;

    uint256 private _nextTokenId = 1;

    mapping(uint256 => AddressTracking[]) public tokenIdTravelInfos;

    mapping(address => mapping(address => contractStatus)) public distributorPharmacyContract;

    // Events
    event ManufacturerToDistributor(address indexed manufacturerAddress, address indexed distributorAddress, uint256[] tokenIds, uint receivedTimestamp);
    event DistributorToPharmacy(address indexed distributorAddress, address indexed pharmacyAddress, uint256[] tokenIds, uint receivedTimestamp);
    event mintNFTEvent(address indexed manufactureAddress, uint256[] tokenIds);

    event distributorSignTheContractEvent(address indexed distributorAddress , address indexed pharmacyAddress , uint timespan);
    event pharmacySignTheContractEvent(address indexed pharmacyAddress , address indexed distributorAddress , uint timespan);
    
    // Event mới cho bước 4
    event distributorFinalizeAndMintEvent(address indexed distributorAddress , uint tokenId , uint timespan);


    constructor(address _accessControlAddress, string memory _uri) ERC1155(_uri) {
        require(_accessControlAddress != address(0), "Invalid access control address");
        accessControlServiceObj = accessControlService(_accessControlAddress);
    }

    function setURI(string memory _uri) public{
        require(accessControlServiceObj.isAdmin(msg.sender), "You Must be Admin to do this function");
        _setURI(_uri);
    }

    function distributorCreateAContract(address pharmacyAddress) public
    {
        require(accessControlServiceObj.checkIsDistributor(msg.sender) , "Address is not a distributor");
        require(accessControlServiceObj.checkIsPharmacy(pharmacyAddress) , "Address is not a Pharmacy");

        require(distributorPharmacyContract[msg.sender][pharmacyAddress] == contractStatus.NOT_CREATED, 
                "Contract already exists or is pending");

        distributorPharmacyContract[msg.sender][pharmacyAddress] = contractStatus.PENDING;

        emit distributorSignTheContractEvent(msg.sender , pharmacyAddress , block.timestamp);
    }

    function pharmacyConfirmTheContract(address distributorAddress) public {

        require(accessControlServiceObj.checkIsDistributor(distributorAddress) , "Address is not a distributor");
        require(accessControlServiceObj.checkIsPharmacy(msg.sender) , "Address is not a Pharmacy");

        require(distributorPharmacyContract[distributorAddress][msg.sender] == contractStatus.PENDING, 
                "No pending contract request found from this Distributor");

        distributorPharmacyContract[distributorAddress][msg.sender] = contractStatus.APPROVED;

        emit pharmacySignTheContractEvent(msg.sender , distributorAddress , block.timestamp);
    }


    // BƯỚC 4: DISTRIBUTOR XÁC NHẬN LẦN CUỐI & MINT NFT
    function distributorFinalizeAndMint(address pharmacyAddress) public {

        require(accessControlServiceObj.checkIsDistributor(msg.sender) , "Address is not a distributor");
        require(accessControlServiceObj.checkIsPharmacy(pharmacyAddress) , "Address is not a Pharmacy");

        require(distributorPharmacyContract[msg.sender][pharmacyAddress] == contractStatus.APPROVED, 
                "Pharmacy has not approved the contract yet!");

        distributorPharmacyContract[msg.sender][pharmacyAddress] = contractStatus.SIGNED;

        uint tokenId = _nextTokenId;
        _mint(msg.sender, tokenId, 1, ""); 
        _nextTokenId++;

        bytes32 distributorRole = accessControlServiceObj.DISTRIBUTOR_ROLE();
        tokenIdTravelInfos[tokenId].push(AddressTracking(
            bytes32(0), 
            distributorRole, 
            address(0), 
            msg.sender, 
            block.timestamp
        ));

        emit distributorFinalizeAndMintEvent(msg.sender , tokenId , block.timestamp);
    }

    function manufacturerTransferToDistributor(
        uint256[] memory tokenIds,
        uint256[] memory amount,
        address distributorAddress
    ) public {
        require(accessControlServiceObj.checkIsManufacturer(msg.sender), "Caller is not a Manufacturer");
        require(accessControlServiceObj.checkIsDistributor(distributorAddress), "Receiver is not a Distributor");

        address[] memory owners = new address[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) { owners[i] = msg.sender; }

        uint256[] memory balances = balanceOfBatch(owners, tokenIds);
        for (uint256 i = 0; i < balances.length; i++) { require(balances[i] >= amount[i], "Manufacturer: insufficient balance"); }

        safeBatchTransferFrom(msg.sender, distributorAddress, tokenIds, amount, "");
        
        uint timeSpan = block.timestamp;
        bytes32 fromRole = accessControlServiceObj.MANUFACTURER_ROLE();
        bytes32 toRole = accessControlServiceObj.DISTRIBUTOR_ROLE();

        for (uint i = 0; i < tokenIds.length; i++) {
            if (amount[i] > 0) { 
                tokenIdTravelInfos[tokenIds[i]].push(AddressTracking(fromRole, toRole, msg.sender, distributorAddress, timeSpan));
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

        require(distributorPharmacyContract[msg.sender][pharmaAddress] == contractStatus.SIGNED, 
                "The Contract is not finalized/signed yet!");

        address[] memory owners = new address[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) { owners[i] = msg.sender; }
        
        uint256[] memory balances = balanceOfBatch(owners, tokenIds);
        for (uint256 i = 0; i < balances.length; i++) { require(balances[i] >= amount[i], "Distributor: insufficient balance"); }

        safeBatchTransferFrom(msg.sender, pharmaAddress, tokenIds, amount, "");

        uint timeSpan = block.timestamp;
        bytes32 fromRole = accessControlServiceObj.DISTRIBUTOR_ROLE();
        bytes32 toRole = accessControlServiceObj.PHARMACY_ROLE();

        for (uint i = 0; i < tokenIds.length; i++) {
            if (amount[i] > 0) {
                tokenIdTravelInfos[tokenIds[i]].push(AddressTracking(fromRole, toRole, msg.sender, pharmaAddress, timeSpan));
            }
        }

        emit DistributorToPharmacy(msg.sender, pharmaAddress, tokenIds, timeSpan);
    }

    function getTrackingHistory(uint256 tokenId) public view returns (AddressTracking[] memory) {
        return tokenIdTravelInfos[tokenId];
    }

    function _getStatusString(contractStatus status) internal pure returns (string memory) {
        if (status == contractStatus.SIGNED) return "Signed";
        if (status == contractStatus.APPROVED) return "Approved (Waiting Finalize)";
        if (status == contractStatus.PENDING) return "Pending";
        return "Not Created";
    }

    function pharmacyGetContractInfoByDistributorAddress(address distributorAddress) public view returns(getContractInfoStruct memory) {
        contractStatus status = distributorPharmacyContract[distributorAddress][msg.sender];
        return getContractInfoStruct(distributorAddress, msg.sender, _getStatusString(status));
    }

    function distributorGetContractByPharmacyAddress(address pharmacyAddress) public view returns(getContractInfoStruct memory){
        require(accessControlServiceObj.checkIsDistributor(msg.sender) , "You are not a Distributor");
        contractStatus status = distributorPharmacyContract[msg.sender][pharmacyAddress];
        return getContractInfoStruct(msg.sender, pharmacyAddress, _getStatusString(status));
    }
}