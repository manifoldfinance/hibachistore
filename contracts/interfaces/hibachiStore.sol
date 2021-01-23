/// SPDX-License-Identifier: SSPL-1.0
/// @title Hibachi Store Interface to KingRoll
/// @version 2021-01-23
/// @security ops@manifoldfinance.com

pragma solidity >=0.6.2 <0.8.0;
pragma experimental ABIEncoderV2;

interface HibachiStoreInterface {
    // State of the kingroll.
    enum LotteryState { draw, committed, rewarded }
    struct LendingBalance {
        uint256 userAmount; // token amount collected from fee/arbs profit from swapping.
        uint256 sponsorAmount; // token amount deposited by sponsor.
    }
    
    // @dev KingRoll Data
    // Trying to keep the naming consistent, however for the kingroll 
    // logic, we favor understandability over procedure
    struct LotteryData {
        address lendingProxy; // Proxy contract for interaction with Lending protocols.
        address swapProxy; // Swap contract for interaction with Dex.
        uint256 kingrollId; // Lottery Id.
        uint256 fee; // Swapping fee
        uint256 hibachiPrice; // Price
        LotteryState state; // State of the kingroll.
        uint256 winners;
        uint256 totalHibachi; // Total hibachis distributed.
        uint256 startTime; // Start time of Lottery.
        uint256 duration; // Duration of each phase in the kingroll.
        uint256[] kingrollWinners; // Winners of this kingroll.
    }

    struct StableCoin {
        bool isEnabled;
        uint256 lendingId;
    }

    struct SponsorData {
        address token;
        uint256 principalAmt;
    }

    // Current Lottery ID
    function openDraw() external view returns (uint256);

    // Lottery Details
    function kingroll(uint256) external view returns (LotteryData memory);

    // Token Amount locked in specific kingroll.
    function getAssetLocked(uint256 kingrollId, address token)
        external
        view
        returns (
            uint256 _userAmt,
            uint256 _sponsorAmt,
            uint256 _prizeAmt
        );

    // Total no of stable coins enabled
    function totalStableCoins() external view returns (uint256);

    // Total no of kingroll users for a specific kingroll
    function totalUsers(uint256 kingrollId) external view returns (uint256);

    // Total no of kingroll sponsor for a specific kingroll
    function totalSponsors(uint256 kingrollId) external view returns (uint256);

    // Stable coins array
    function stableCoinsArr(uint256 id) external view returns (address);

    // Stable coin data
    function stableCoins(uint256 kingrollId) external view returns (StableCoin memory);

    // kingroll hibachis for a user for a specific kingroll.
    function kingrollTickets(uint256 kingrollId, address user) external view returns (uint256 hibachis);

    // Sponsor balance for a specific kingroll.
    function sponsorBalance(uint256 kingrollId, address sponsor) external view returns (SponsorData memory);

    // To buy candy.(Can only be called by arbs contract)
    function buyHibachi(
        address token,
        uint256 amt,
        address to,
        bool lottert
    ) external returns (uint256 hibachis);
}
