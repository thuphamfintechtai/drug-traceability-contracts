// SPDX-License-Identifier: UNKNOWN

pragma solidity ^0.8.2;

struct TokenTracking{
    uint256 tokenId ;
    AddressTracking [] addressTrackings;
}

struct AddressTracking{
    bytes userType;
    address userAddress;
}