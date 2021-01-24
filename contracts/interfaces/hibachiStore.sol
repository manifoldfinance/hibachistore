pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

interface HibachiStoreInterface {
    function buyHibachi(address token, uint amt, address to, bool lottery) external;
}