/// SPDX-License-Identifier: SSPL-1.0
/// @title Governance Interface for MultiSig
/// @version 2021-01-23
/// @description Hibachi Store and KingRoll Governance 
pragma solidity >=0.6.2 <0.8..0;

interface GovernanceInterface {
    function lendingProxy() external view returns (address);

    function kingrollSwap() external view returns (address);

    function hibachiStoreArbs() external view returns (address);

    function hibachiStore() external view returns (address);

    function randomness() external view returns (address);

    function kingrollDuration() external view returns (uint256);

    function admin() external view returns (address);

    function hibachiPrice() external view returns (uint256);

    function profitShare() external view returns (uint256);

    function fee() external view returns (uint256);
}
