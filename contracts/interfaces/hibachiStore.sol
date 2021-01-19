// SPDX-License-Identifier:  GPL-2.0-Only
pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

interface HibachiStoreInterface {
    function buyHibachi(
        address token,
        uint256 amt,
        address to,
        bool kingRoll
    ) external;
}
