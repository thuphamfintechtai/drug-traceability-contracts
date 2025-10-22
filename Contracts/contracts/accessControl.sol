// SPDX-License-Identifier: UNKNOWN

pragma solidity ^0.8.2;

import "./libraries/structsLibrary.sol";


contract accessControlService{

                    /*           CONTRUCTOR           */

    constructor(){
       owner = msg.sender;
    }

                /*             EVENTS           */
    
                        /*     Permission Events     */

    event grantPermissonEvent(address granter, address reciver);

    event PermissionRemoveEvent(address granter , address reciver);

                        /*       Authority Events     */

    event manufactureAuthorityEvent(address ManufactorAddress , address DistributorAddress);

    event distributorAuthorityEvent(address DistributorAddress , address PharmacyAddress);

    event manufactureUnauthorityEvent(address ManufactorAddress , address DistributorAddress);

    event distributorUnauthorityEvent(address DistributorAddress , address PharmacyAddress);

                /*            MAPPING             */

    mapping(address => bool) public isManufacture;

    mapping(address => bool) public isDistributor;

    mapping(address => bool) public isPharmacy;

    mapping(address => mapping(address => bool)) public 
    manufactureAuthorityDistributor;

    mapping(address => mapping(address => bool)) public 
    distributorAuthorityPharmacy;

    /*            ADDRESS             */


    address private owner;

    /*             MODIFIER             */

    modifier onlyManufacture{
        require(isManufacture[msg.sender] , "Invalid Role only Manufacture can call this");
        _;
    }

    modifier onlyDistributor{
        require(isDistributor[msg.sender] , "Invalid Role Only Distributor can call this");
        _;
    }

    modifier onlyPharmacy{
        require(isPharmacy[msg.sender] , "Invalid Role Only Pharmacy can call this");
        _;
    }

    modifier onlyOwner{
        require(msg.sender == owner , "Invalid Role Only Owner can call this Function");
        _;
    }

    /*          PERMISSIONS FUNCTION        */

    function addManufacture(address _Manufacture) public onlyOwner{
        isManufacture[_Manufacture] = true;
        emit grantPermissonEvent(_Manufacture, msg.sender);
    }
    function addPharmacy(address _Pharmacy) public onlyDistributor{
        isPharmacy[_Pharmacy] = true;
        emit grantPermissonEvent(_Pharmacy, msg.sender);
    }

    function addDistributor(address _Distributor) public onlyManufacture{
        isDistributor[_Distributor] = true;
        emit grantPermissonEvent(_Distributor, msg.sender);
    }

    function removeManufacture(address _Manufacture) public onlyOwner{
        isManufacture[_Manufacture] = false;
        emit PermissionRemoveEvent(_Manufacture, msg.sender);
    }

    function removePharmacy(address _Pharmacy) public onlyDistributor{
        isPharmacy[_Pharmacy] = false;
        emit PermissionRemoveEvent(_Pharmacy, msg.sender);
    }

    function removeDistributor(address _Distributor) public onlyManufacture{
        isDistributor[_Distributor] = false;
        emit PermissionRemoveEvent(_Distributor, msg.sender);
    }

    function ManufactureAuthorityDistributorFun(address _DistributorAddress) public onlyManufacture
    {
        manufactureAuthorityDistributor[msg.sender][_DistributorAddress] = true;
        emit manufactureAuthorityEvent(msg.sender, _DistributorAddress);
    }

    function DistributorAuthorityPharmacyFun(address _PharmacyAddress) public onlyDistributor
    {
        distributorAuthorityPharmacy[msg.sender][_PharmacyAddress] = true;
        emit distributorAuthorityEvent(msg.sender, _PharmacyAddress);
    }

    function ManufactureUnauthorityDistributorFun(address _DistributorAddress) public onlyManufacture
    {
        manufactureAuthorityDistributor[msg.sender][_DistributorAddress] = false;
        emit manufactureUnauthorityEvent(msg.sender , _DistributorAddress);
    }


    function DistributorUnauthorityPharmacyFun(address _PharmacyAddress) public onlyDistributor
    {
        distributorAuthorityPharmacy[msg.sender][_PharmacyAddress] = false;
        emit distributorUnauthorityEvent(msg.sender, _PharmacyAddress);
    }


    /*          CHECK IF IT'S ADMIN OR NOT               */


    function isAdmin(address _adminAddress) public view returns(bool) {
        if (owner == _adminAddress) {
            return true;
        } else {
            return false;
        }
    }

    /*          CHECK IF IT'S DISTRIBUTOR OR NOT        */


    function checkIsDistributor(address _DistributorAddress) public view returns(bool) {
        if (isDistributor[_DistributorAddress]) {
            return true;
        } else {
            return false;
        }
    }

    /*          CHECK IF IT'S PHARMACY OR NOT           */

    function checkIsPharmacy(address _PharmacyAddress) public view returns(bool){
        if(isPharmacy[_PharmacyAddress])
        {
            return true;
        }else{
            return false;
        }
    }


    /*          CHECK IF IT'S MANUFACTOR OR NOT           */

    function checkIsManufactor(address _ManufactorAddress) public view returns(bool){
        if(isManufacture[_ManufactorAddress])
        {
            return true;
        }else{
            return false;
        }
    }



    /*          CHECK IF THE ROLE IS VALID OR NOT           */


    function checkManufactorAuthorityDistributor(address _DistributorAddress) public view returns(bool){
        if(manufactureAuthorityDistributor[msg.sender][_DistributorAddress]){
            return true;
        }else{
            return false;
        }
    }

    function checkDistributorAuthorityPharmacy(address _PharmacyAddress) public view returns(bool){
        if(distributorAuthorityPharmacy[msg.sender][_PharmacyAddress]){
            return true;
        }else{
            return false;
        }
    }

}