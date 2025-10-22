// SPDX-License-Identifier: UNKNOWN

pragma solidity ^0.8.2;

struct AddressTracking{
    bytes32 fromUserType;
    bytes32 toUserType;
    address fromUserAddress;
    address toUserAddress;
    uint recivedtimeSpan;
}