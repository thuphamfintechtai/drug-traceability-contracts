// SPDX-License-Identifier: UNKNOWN

import "./enumsLibrary.sol";


pragma solidity ^0.8.2;

struct AddressTracking{
    // Người đến dạng Bytes 
    bytes32 fromUserType;
    // Người nhận dạng Bytes 
    bytes32 toUserType;
    // Người gửi Wallet Adderess
    address fromUserAddress;
    // Người nhận Wallet Address
    address toUserAddress;
    
    uint recivedtimeSpan;
}

struct allRoleBaseStruct{
    bool isActive;
    string taxCode;
    string licenseNo;
}


