pragma solidity ^0.6.12;

interface compoundTokenInterface {
    function allocateTo(address _owner, uint256 value) external;
}

interface TokenInterface {
    function approve(address, uint256) external;

    function transfer(address, uint256) external;

    function transferFrom(
        address,
        address,
        uint256
    ) external;

    function deposit() external payable;

    function withdraw(uint256) external;

    function balanceOf(address) external view returns (uint256);
}

interface AaveTokenInterface {
    function mint(uint256 value) external returns (bool);
}

interface HibachiStoreInterface {
    function buyHibachi(
        address token,
        uint256 amount,
        address to,
        bool kingroll
    ) external returns (uint256 hibachis);

    function depositSponsor(address token, uint256 amt) external;
}

contract User {
    address public aaveDai = 0xf80A32A835F79D7787E8a8ee5721D0fEaFd78108;
    address public compoundDai = 0xB5E5D0F8C0cbA267CD3D7035d6AdC8eBA7Df7Cdd;

    constructor() public {
        AaveTokenInterface(aaveDai).mint(10**24);
        compoundTokenInterface(compoundDai).allocateTo(address(this), 10**24);
    }

    function swap1(
        address hibachiStoreAddr,
        uint256 amt,
        address x
    ) external {
        TokenInterface(aaveDai).approve(hibachiStoreAddr, 2**255);
        HibachiStoreInterface(hibachiStoreAddr).buyHibachi(aaveDai, amt, x, true);
    }

    function swap2(
        address hibachiStoreAddr,
        uint256 amt,
        address x
    ) external {
        TokenInterface(compoundDai).approve(hibachiStoreAddr, 2**255);
        HibachiStoreInterface(hibachiStoreAddr).buyHibachi(compoundDai, amt, x, true);
    }

    function getToken(uint256 id, address user) external {
        if (id == 1) {
            compoundTokenInterface(compoundDai).allocateTo(address(this), 10**24);
            TokenInterface(compoundDai).transfer(user, 10**24);
        } else {
            AaveTokenInterface(aaveDai).mint(10**24);
            TokenInterface(aaveDai).transfer(user, 10**24);
        }
    }

    function deposit(
        uint256 id,
        address hibachiStoreAddr,
        uint256 amt
    ) external {
        if (id == 1) {
            compoundTokenInterface(compoundDai).allocateTo(address(this), 10**24);
            TokenInterface(compoundDai).approve(hibachiStoreAddr, 2**255);
            HibachiStoreInterface(hibachiStoreAddr).depositSponsor(compoundDai, amt);
        } else {
            AaveTokenInterface(aaveDai).mint(10**24);
            TokenInterface(compoundDai).approve(hibachiStoreAddr, 2**255);
            HibachiStoreInterface(hibachiStoreAddr).depositSponsor(aaveDai, amt);
        }
    }
}
