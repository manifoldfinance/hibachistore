pragma solidity ^0.6.2;

import {DSMath} from "./libraries/DSMath.sol";

contract GovernanceData is DSMath {
    address public admin;

    address public hibachiStore;
    address public randomness;

    uint public fee;
    uint public hibachiPrice;
    uint public profitShare;
    uint public kingrollDuration;

    address public lendingProxy;
    address public kingrollSwap;
    address public hibachiStoreArbs;

    modifier isAdmin {
        require(admin == msg.sender, "not-a-admin");
        _;
    }

    function changeFee(uint _fee) external isAdmin {
        require(_fee < 5 * 10 ** 15, "governance/over-fee"); // 0.5% Max Fee.
        fee = _fee;
    }

    function changeCandyPrice(uint _price) external isAdmin {
        require(_price < 1 * WAD, "governance/over-price"); // 1$ Max Price.
        hibachiPrice = _price;
    }

    function changeDuration(uint _time) external isAdmin {
        require(_time <= 30 days, "governance/over-price"); // 30 days Max duration
        // require(_time >= 7 days, "governance/over-price"); // 7 days min duration
        kingrollDuration = _time;
    }

    function changelendingProxy(address _proxy) external isAdmin {
        require(_proxy != address(0), "governance/no-deposit-proxy-address");
        require(_proxy != lendingProxy, "governance/same-deposit-proxy-address");
        lendingProxy = _proxy;
    }

    function changeArbs(address _arbs) external isAdmin {
        require(_arbs != address(0), "governance/no-deposit-arbs-address");
        require(_arbs != hibachiStoreArbs, "governance/same-deposit-arbs-address");
        hibachiStoreArbs = _arbs;
    }

    function changeRandom(address _randomness) external isAdmin {
        require(_randomness != address(0), "governance/no-randomnesss-address");
        require(_randomness != randomness, "governance/same-randomnesss-address");
        randomness = _randomness;
    }

    function changeSwap(address _proxy) external isAdmin {
        require(_proxy != address(0), "governance/no-swap-proxy-address");
        require(_proxy != kingrollSwap, "governance/same-swap-proxy-address");
        kingrollSwap = _proxy;
    }

    function changeAdmin(address _admin) external isAdmin {
        require(_admin != address(0), "governance/no-admin-address");
        require(admin != _admin, "governance/same-admin");
        admin = _admin;
    }
}

contract Governance is GovernanceData {
    constructor (
        address _admin,
        uint _fee,
        uint _hibachiPrice,
        uint _duration,
        address _lendingProxy
    ) public {
        assert(_admin != address(0));
        assert(_fee != 0);
        assert(_hibachiPrice != 0);
        assert(_duration != 0);
        assert(_lendingProxy != address(0));
        admin = _admin;
        fee = _fee;
        hibachiPrice = _hibachiPrice;
        kingrollDuration = _duration;
        lendingProxy = _lendingProxy;
        
    }

    function init(address _hibachiStore, address _randomness, address _swap) public isAdmin {
        require(_randomness != address(0), "governance/no-randomnesss-address");
        require(_hibachiStore != address(0));
        require(_swap != address(0), "governance/no-swapLottery-address");
        randomness = _randomness;
        hibachiStore = _hibachiStore;
        kingrollSwap = _swap;
    }
}