// SPDX-License-Identifier: UNKNOWN
pragma solidity ^0.8.2;

contract accessControlService {

    /*          ADDRESS             */
    address private owner;

    /*          CONSTRUCTOR           */

    constructor() {
        owner = msg.sender;
    }

    /*          ENUMS           */

    enum ApprovalStatus {
        NONE,       
        PENDING,   
        APPROVED,   
        REJECTED    
    }

    /*              EVENTS           */
    
    event PermissionGranted(address indexed granter, address indexed receiver, bytes32 indexed role);
    event PermissionRevoked(address indexed granter, address indexed receiver, bytes32 indexed role);

    event RelationshipRequested(address indexed requester, address indexed approver, bytes32 relationshipType);
    event RelationshipApproved(address indexed approver, address indexed requester, bytes32 relationshipType);
    event RelationshipRejected(address indexed party1, address indexed party2, bytes32 relationshipType);
    event RelationshipRemoved(address indexed remover, address indexed otherParty, bytes32 relationshipType);

    bytes32 public constant MANUFACTURER_ROLE = keccak256("MANUFACTURER_ROLE");
    bytes32 public constant DISTRIBUTOR_ROLE = keccak256("DISTRIBUTOR_ROLE");
    bytes32 public constant PHARMACY_ROLE = keccak256("PHARMACY_ROLE");

    bytes32 public constant MANU_DIST_RELATION = keccak256("MANUFACTURER_DISTRIBUTOR_RELATION");
    bytes32 public constant DIST_PHAR_RELATION = keccak256("DISTRIBUTOR_PHARMACY_RELATION");



    mapping(address => bool) public isManufacturer;
    mapping(address => bool) public isDistributor;
    mapping(address => bool) public isPharmacy;

    mapping(address => mapping(address => ApprovalStatus)) public manufacturerDistributorStatus;

    mapping(address => mapping(address => ApprovalStatus)) public distributorPharmacyStatus;


    /*          MODIFIER             */

    modifier onlyManufacturer {
        require(isManufacturer[msg.sender], "Invalid Role: Only Manufacturer can call this");
        _;
    }

    modifier onlyDistributor {
        require(isDistributor[msg.sender], "Invalid Role: Only Distributor can call this");
        _;
    }

    modifier onlyPharmacy {
        require(isPharmacy[msg.sender], "Invalid Role: Only Pharmacy can call this");
        _;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Invalid Role: Only Owner can call this Function");
        _;
    }

    /*      PERMISSIONS FUNCTIONS       */

    function addManufacturer(address _manufacturer) public onlyOwner {
        require(!isManufacturer[_manufacturer], "Address is already a Manufacturer");
        isManufacturer[_manufacturer] = true;
        emit PermissionGranted(msg.sender, _manufacturer, MANUFACTURER_ROLE);
    }

    function addPharmacy(address _pharmacy) public onlyOwner {
        require(!isPharmacy[_pharmacy], "Address is already a Pharmacy");
        isPharmacy[_pharmacy] = true;
        emit PermissionGranted(msg.sender, _pharmacy, PHARMACY_ROLE);
    }

    function addDistributor(address _distributor) public onlyOwner {
        require(!isDistributor[_distributor], "Address is already a Distributor");
        isDistributor[_distributor] = true;
        emit PermissionGranted(msg.sender, _distributor, DISTRIBUTOR_ROLE);
    }

    function removeManufacturer(address _manufacturer) public onlyOwner {
        require(isManufacturer[_manufacturer], "Address is not a Manufacturer");
        isManufacturer[_manufacturer] = false;
        emit PermissionRevoked(msg.sender, _manufacturer, MANUFACTURER_ROLE);
    }

    function removePharmacy(address _pharmacy) public onlyOwner {
        require(isPharmacy[_pharmacy], "Address is not a Pharmacy");
        isPharmacy[_pharmacy] = false;
        emit PermissionRevoked(msg.sender, _pharmacy, PHARMACY_ROLE);
    }

    function removeDistributor(address _distributor) public onlyOwner {
        require(isDistributor[_distributor], "Address is not a Distributor");
        isDistributor[_distributor] = false;
        emit PermissionRevoked(msg.sender, _distributor, DISTRIBUTOR_ROLE);
    }

    /* A        UTHORITIES FUNCTIONS            */



    function manufacturerRequestDistributor(address _distributor) public onlyManufacturer {
        require(isDistributor[_distributor], "Target is not a Distributor");
        require(manufacturerDistributorStatus[msg.sender][_distributor] == ApprovalStatus.NONE, "Request already exists");
        
        manufacturerDistributorStatus[msg.sender][_distributor] = ApprovalStatus.PENDING;
        emit RelationshipRequested(msg.sender, _distributor, MANU_DIST_RELATION);
    }

    function distributorRequestManufacturer(address _manufacturer) public onlyDistributor {
        require(isManufacturer[_manufacturer], "Target is not a Manufacturer");
        require(manufacturerDistributorStatus[_manufacturer][msg.sender] == ApprovalStatus.NONE, "Request already exists");

        manufacturerDistributorStatus[_manufacturer][msg.sender] = ApprovalStatus.PENDING;
        emit RelationshipRequested(msg.sender, _manufacturer, MANU_DIST_RELATION);
    }

    function manufacturerApproveDistributor(address _distributor) public onlyManufacturer {
        require(manufacturerDistributorStatus[msg.sender][_distributor] == ApprovalStatus.PENDING, "No pending request");
        
        manufacturerDistributorStatus[msg.sender][_distributor] = ApprovalStatus.APPROVED;
        emit RelationshipApproved(msg.sender, _distributor, MANU_DIST_RELATION);
    }

    function distributorApproveManufacturer(address _manufacturer) public onlyDistributor {
        require(manufacturerDistributorStatus[_manufacturer][msg.sender] == ApprovalStatus.PENDING, "No pending request");

        manufacturerDistributorStatus[_manufacturer][msg.sender] = ApprovalStatus.APPROVED;
        emit RelationshipApproved(msg.sender, _manufacturer, MANU_DIST_RELATION);
    }

    function removeManufacturerDistributorLink(address _otherParty) public {
        ApprovalStatus status1 = manufacturerDistributorStatus[msg.sender][_otherParty];
        ApprovalStatus status2 = manufacturerDistributorStatus[_otherParty][msg.sender];

        require(isManufacturer[msg.sender] || isDistributor[msg.sender], "Not authorized");
        
        require(isManufacturer[_otherParty] || isDistributor[_otherParty], "Invalid target");

        require(status1 != ApprovalStatus.NONE || status2 != ApprovalStatus.NONE, "No relationship exists");

        if (status1 != ApprovalStatus.NONE) {
            manufacturerDistributorStatus[msg.sender][_otherParty] = ApprovalStatus.NONE;
        }
        if (status2 != ApprovalStatus.NONE) {
            manufacturerDistributorStatus[_otherParty][msg.sender] = ApprovalStatus.NONE;
        }

        emit RelationshipRemoved(msg.sender, _otherParty, MANU_DIST_RELATION);
    }


    // --- Distributor <-> Pharmacy  ---

    function distributorRequestPharmacy(address _pharmacy) public onlyDistributor {
        require(isPharmacy[_pharmacy], "Target is not a Pharmacy");
        require(distributorPharmacyStatus[msg.sender][_pharmacy] == ApprovalStatus.NONE, "Request already exists");
        
        distributorPharmacyStatus[msg.sender][_pharmacy] = ApprovalStatus.PENDING;
        emit RelationshipRequested(msg.sender, _pharmacy, DIST_PHAR_RELATION);
    }

    function pharmacyRequestDistributor(address _distributor) public onlyPharmacy {
        require(isDistributor[_distributor], "Target is not a Distributor");
        require(distributorPharmacyStatus[_distributor][msg.sender] == ApprovalStatus.NONE, "Request already exists");

        distributorPharmacyStatus[_distributor][msg.sender] = ApprovalStatus.PENDING;
        emit RelationshipRequested(msg.sender, _distributor, DIST_PHAR_RELATION);
    }

    function distributorApprovePharmacy(address _pharmacy) public onlyDistributor {
        require(distributorPharmacyStatus[msg.sender][_pharmacy] == ApprovalStatus.PENDING, "No pending request");

        distributorPharmacyStatus[msg.sender][_pharmacy] = ApprovalStatus.APPROVED;
        emit RelationshipApproved(msg.sender, _pharmacy, DIST_PHAR_RELATION);
    }

    function pharmacyApproveDistributor(address _distributor) public onlyPharmacy {
        require(distributorPharmacyStatus[_distributor][msg.sender] == ApprovalStatus.PENDING, "No pending request");

        distributorPharmacyStatus[_distributor][msg.sender] = ApprovalStatus.APPROVED;
        emit RelationshipApproved(msg.sender, _distributor, DIST_PHAR_RELATION);
    }

    function removeDistributorPharmacyLink(address _otherParty) public {
        ApprovalStatus status1 = distributorPharmacyStatus[msg.sender][_otherParty];
        ApprovalStatus status2 = distributorPharmacyStatus[_otherParty][msg.sender];

        require(isDistributor[msg.sender] || isPharmacy[msg.sender], "Not authorized");
        require(isDistributor[_otherParty] || isPharmacy[_otherParty], "Invalid target");
        require(status1 != ApprovalStatus.NONE || status2 != ApprovalStatus.NONE, "No relationship exists");

        if (status1 != ApprovalStatus.NONE) {
            distributorPharmacyStatus[msg.sender][_otherParty] = ApprovalStatus.NONE;
        }
        if (status2 != ApprovalStatus.NONE) {
            distributorPharmacyStatus[_otherParty][msg.sender] = ApprovalStatus.NONE;
        }
        
        emit RelationshipRemoved(msg.sender, _otherParty, DIST_PHAR_RELATION);
    }


    /*              CHECK FUNCTIONS          */

    function isAdmin(address _adminAddress) public view returns (bool) {
        return (owner == _adminAddress);
    }

    function checkIsDistributor(address _distributorAddress) public view returns (bool) {
        return isDistributor[_distributorAddress];
    }

    function checkIsPharmacy(address _pharmacyAddress) public view returns (bool) {
        return isPharmacy[_pharmacyAddress];
    }

    function checkIsManufacturer(address _manufacturerAddress) public view returns (bool) {
        return isManufacturer[_manufacturerAddress];
    }

    function isManufacturerDistributorApproved(address _manufacturer, address _distributor) public view returns (bool) {
        bool direction1 = (manufacturerDistributorStatus[_manufacturer][_distributor] == ApprovalStatus.APPROVED);
        bool direction2 = (manufacturerDistributorStatus[_distributor][_manufacturer] == ApprovalStatus.APPROVED);
        return direction1 || direction2;
    }

    function isDistributorPharmacyApproved(address _distributor, address _pharmacy) public view returns (bool) {
        bool direction1 = (distributorPharmacyStatus[_distributor][_pharmacy] == ApprovalStatus.APPROVED);
        bool direction2 = (distributorPharmacyStatus[_pharmacy][_distributor] == ApprovalStatus.APPROVED);
        return direction1 || direction2;
    }
}