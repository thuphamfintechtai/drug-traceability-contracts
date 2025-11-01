// SPDX-License-Identifier: UNKNOWN
pragma solidity ^0.8.2;
import "./libraries/structsLibrary.sol";
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

    event regrantPermisson(address indexed granter, address indexed receiver, bytes32 indexed role);


    bytes32 public constant MANUFACTURER_ROLE = keccak256("MANUFACTURER_ROLE");
    bytes32 public constant DISTRIBUTOR_ROLE = keccak256("DISTRIBUTOR_ROLE");
    bytes32 public constant PHARMACY_ROLE = keccak256("PHARMACY_ROLE");

    bytes32 public constant MANU_DIST_RELATION = keccak256("MANUFACTURER_DISTRIBUTOR_RELATION");
    bytes32 public constant DIST_PHAR_RELATION = keccak256("DISTRIBUTOR_PHARMACY_RELATION");



    mapping(address => allRoleBaseStruct) public isManufacturer;
    mapping(address => allRoleBaseStruct) public isDistributor;
    mapping(address => allRoleBaseStruct) public isPharmacy;

    /*          MODIFIER             */

    modifier onlyManufacturer {
        require(isManufacturer[msg.sender].isActive, "Invalid Role: Only Manufacturer can call this");
        _;
    }

    modifier onlyDistributor {
        require(isDistributor[msg.sender].isActive, "Invalid Role: Only Distributor can call this");
        _;
    }

    modifier onlyPharmacy {
        require(isPharmacy[msg.sender].isActive, "Invalid Role: Only Pharmacy can call this");
        _;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Invalid Role: Only Owner can call this Function");
        _;
    }

    /*          PERMISSIONS FUNCTIONS           */

    function addManufacturer(address _manufacturer , 
    string memory taxCode ,
    string memory lisenceNo) public onlyOwner {
        require(!isManufacturer[_manufacturer].isActive, "Address is already a Manufacturer");
        isManufacturer[_manufacturer] = allRoleBaseStruct(
            true ,
            taxCode ,
            lisenceNo
        );
        
        emit PermissionGranted(msg.sender, _manufacturer, MANUFACTURER_ROLE);
    }

    function addPharmacy(address _pharmacy ,
    string memory taxCode ,
    string memory lisenceNo) public onlyOwner {
        require(!isPharmacy[_pharmacy].isActive, "Address is already a Pharmacy");
        isPharmacy[_pharmacy] = allRoleBaseStruct(
            true,
            taxCode,
            lisenceNo
        );
        emit PermissionGranted(msg.sender, _pharmacy, PHARMACY_ROLE);
    }

    function addDistributor(address _distributor
    , string memory taxCode ,
    string memory lisenceNo) public onlyOwner {
        require(!isDistributor[_distributor].isActive, "Address is already a Distributor");
        isDistributor[_distributor] = allRoleBaseStruct(
            true ,
            taxCode,
            lisenceNo
        );
        emit PermissionGranted(msg.sender, _distributor, DISTRIBUTOR_ROLE);
    }

    /*          ReGrant Roles         */

    function regrantManufacture(address _manufacturer) public onlyOwner {
        require(!isManufacturer[_manufacturer].isActive, "Manufacture Address is already granted");
        isManufacturer[_manufacturer].isActive = true;
        
        emit regrantPermisson(msg.sender, _manufacturer, MANUFACTURER_ROLE);
    }

    function regrantPharmacy(address _pharmacy) public onlyOwner {
        require(!isPharmacy[_pharmacy].isActive, "Pharmacy Address is already granted");
        isPharmacy[_pharmacy].isActive = true;

        emit regrantPermisson(msg.sender, _pharmacy, PHARMACY_ROLE);
    }

    function regrantDistributor(address _distributor
    , string memory taxCode ,
    string memory lisenceNo) public onlyOwner {
        require(!isDistributor[_distributor].isActive, "Distributor Address is already granted");
        isDistributor[_distributor] = allRoleBaseStruct(
            true ,
            taxCode,
            lisenceNo
        );
        emit regrantPermisson(msg.sender, _distributor, DISTRIBUTOR_ROLE);
    }

    /*              Remove Roles                */

    function removeManufacturer(address _manufacturer) public onlyOwner {
        require(isManufacturer[_manufacturer].isActive, "Address is not a Manufacturer");
        isManufacturer[_manufacturer].isActive = false;
        emit PermissionRevoked(msg.sender, _manufacturer, MANUFACTURER_ROLE);
    }

    function removePharmacy(address _pharmacy) public onlyOwner {
        require(isPharmacy[_pharmacy].isActive, "Address is not a Pharmacy");
        isPharmacy[_pharmacy].isActive = false;
        emit PermissionRevoked(msg.sender, _pharmacy, PHARMACY_ROLE);
    }

    function removeDistributor(address _distributor) public onlyOwner {
        require(isDistributor[_distributor].isActive, "Address is not a Distributor");
        isDistributor[_distributor].isActive = false;
        emit PermissionRevoked(msg.sender, _distributor, DISTRIBUTOR_ROLE);
    }


    /*              CHECK FUNCTIONS          */

    function isAdmin(address _adminAddress) public view returns (bool) {
        return (owner == _adminAddress);
    }

    function checkIsDistributor(address _distributorAddress) public view returns (bool) {
        return isDistributor[_distributorAddress].isActive;
    }

    function checkIsPharmacy(address _pharmacyAddress) public view returns (bool) {
        return isPharmacy[_pharmacyAddress].isActive;
    }

    function checkIsManufacturer(address _manufacturerAddress) public view returns (bool) {
        return isManufacturer[_manufacturerAddress].isActive;
    }

    /*          GET FUNCTIONS         */

    function getManufacture(address _manufacturerAddress) public view returns(allRoleBaseStruct memory)
    {
        require(isManufacturer[_manufacturerAddress].isActive , "Role is not Valid");
        return isManufacturer[_manufacturerAddress];
    }

    function getDistributor(address _distributorAddress) public view returns(allRoleBaseStruct memory)
    {
        require(isDistributor[_distributorAddress].isActive , "Role is not Valid");
        return isDistributor[_distributorAddress];
    }

    function getPharma(address _pharmaAddress) public view returns(allRoleBaseStruct memory)
    {
        require(isPharmacy[_pharmaAddress].isActive , "Role is not Valid");
        return isPharmacy[_pharmaAddress];
    }
}