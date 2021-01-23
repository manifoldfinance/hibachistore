/// SPDX-Licesne-Identifier: SSPL-1.0
pragma solidity >=0.6.2 <0.8.0;

/// @title Randomness
// Provides the injection of a psudo random number generator for
// a lottery style distrbituion scheme

import { GovernanceInterface } from "./interfaces/governance.sol";
import { VRFConsumerBase } from "./vrf/VRFConsumerBase.sol";

contract Randomness is VRFConsumerBase {
    GovernanceInterface public governanceContract;
    // Mapping of kingroll id => randomness number
    mapping(uint256 => uint256) public randomNumber;
    mapping(bytes32 => uint256) public requestIds;

    constructor(
        address _governance,
        address _vrfCoordinator,
        address _link
    ) public VRFConsumerBase(_vrfCoordinator, _link) {
        governanceContract = GovernanceInterface(_governance);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) external override {
        require(vrfCoordinator == msg.sender, "not-vrf-coordinator");
        require(requestIds[requestId] != 0, "request-id-not-vaild");
        uint256 kingrollId = requestIds[requestId];
        randomNumber[kingrollId] = randomness;
    }

    function getRandom(uint256 kingrollId, uint256 seed) external {
        require(randomNumber[kingrollId] == 0, "Already-found-random");
        require(governanceContract.hibachiStore() == msg.sender, "not-hibachiStore-address");
        // TODO - check time
        uint256 linkFee = 10**18;
        LINK.transferFrom(governanceContract.admin(), address(this), linkFee);

        bytes32 _requestId =
            requestRandomness(0xced103054e349b8dfb51352f0f8fa9b5d20dde3d06f9f43cb2b85bc64b238205, linkFee, seed);
        requestIds[_requestId] = kingrollId;
    }
}
