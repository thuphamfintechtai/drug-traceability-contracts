// SPDX-License-Identifier: UNKNOWN

pragma solidity ^0.8.2;


contract drugContractService{
    
    event grantPermissonEvent(address granter, address reciver);

    event PermissionRemoveEvent(address granter , address reciver);

    address private owner;

    constructor(){
       owner = msg.sender;
    }

    mapping(address => bool) public isManufacture;

    mapping(address => bool) public isDistributor;

    mapping(address => bool) public isPharmacy;

    // Transactions Caller
    // Hàm này để chỉ ra là cái token nó đã đi qua ai rồi 

    mapping(uint256 => address) public tokenIdTravelInfos;


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


}