// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

// inserted interface here to prevent compiler version conflict with older versions.abi
// assuming interface not changing anymore
interface IMultiFeeDistribution {
    function addReward(address rewardsToken) external;
    function mint(address user, uint256 amount, bool withPenalty) external;
}

// set deposit token during creation
// set minter during creation
// keep track max sales total
// users deposit and receive vesting, ACCUMULATIVE
// owner able to withdraw
// set exchange rate
// set min deposit
// duration can only be set during construction

contract LgeVesting is Ownable {
    using SafeERC20 for IERC20;

    bool public hasStarted=false;
    uint256 public constant duration = 86400 * 30 * 6;  // 6 mths
    uint256 public immutable maxMintableTokens;
    uint256 public minDeposit=0;
    uint256 public totalDeposit=0;
    uint256 public totalSold=0;
    uint256 public mintedTokens=0;
    uint8 public exchangeRate=0;    // e.g. +5% bonus is 105 (ie 1.05)
    IMultiFeeDistribution public minter;
    mapping(address => Vest) public vests;
    address public depositToken;

    event Started();

    event Stopped();

    event Deposited(
        address user,
        uint256 depositAmount,
        uint256 receivedAmount
    );

    event Sold(
        uint256 amount,
        uint256 totalAmount
    );

    event Claimed(
        address user,
        uint256 amount
    );

    event Withdrawn(
        address user,
        uint256 amount
    );

    event RateChanged(
        uint256 rate
    );

    event MinChanged(
        uint256 min
    );

    struct Vest {
        uint256 startTime;
        uint256 total;
        uint256 claimed;
    }

    constructor(
        address _depositToken,    
        uint256 _min,
        uint8 _rate,
        IMultiFeeDistribution _minter,
        uint256 _maxMintable,
        address _delegate
    ) Ownable(_delegate) {
        require(_min > 0, 'minimum deposit must be more than 0');
        require(_rate > 0, 'exchange rate must be more than 0');
        require(_maxMintable > _min * _rate / 100, 'max mintable must be more than minimum deposit * rate');
        require(address(_minter) != address(0), 'minter address must not be 0x0');

        depositToken = _depositToken;
        minter = _minter;
        maxMintableTokens = _maxMintable;
        exchangeRate = _rate;
        minDeposit = _min;
    }

    // *********************
    // **** ADMIN START ****
    // *********************
    function start() external onlyOwner {
        require(!hasStarted, 'lge has already started');
        hasStarted = true;
        emit Started();
    }

    function stop() external onlyOwner {
        require(hasStarted, 'lge has already stopped');
        hasStarted = false;
        emit Stopped();
    }

    function setMinDeposit(uint256 _min) external onlyOwner {
        require(_min > 0, 'minimum deposit must be more than 0');
        minDeposit = _min;
        emit MinChanged(minDeposit);
    }

    function setExchangeRate(uint8 _rate) external onlyOwner {
        require(_rate > 0, 'exchange rate must be more than 0');
        exchangeRate = _rate;
        emit RateChanged(exchangeRate);
    }

    // owner withdraw deposit
    // TEST :: withdraw more than deposited
    function withdraw(uint256 amount) external onlyOwner {
        IERC20(depositToken).safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }
    // *******************
    // **** ADMIN END ****
    // *******************

    // ********************
    // **** USER START ****
    // ********************
    // depositor deposit payment
    // claims duration remains the same for total amount
    // TEST :: selling more than allocated
    function deposit(uint256 depositAmount) external {
        require(hasStarted, 'lge has not started');
        require(depositAmount >= minDeposit, 'deposit is less than minimum required');

        // assume minted token is 18 decimals
        uint256 tokenAmount = depositAmount * exchangeRate * 1e18 / 10**ERC20(depositToken).decimals() / 100;
        require(tokenAmount > 0, 'amount sold is zero');
        require(totalSold + tokenAmount <= maxMintableTokens, 'max tokens available for sale exceeded');

        Vest storage v = vests[msg.sender];
        if (v.startTime == 0) {
            // create new entry
            v.startTime = block.timestamp;
            v.total = tokenAmount;
        } else {
            // accumulate if already bought before
            v.total += tokenAmount;
        }

        totalDeposit += depositAmount;
        totalSold += tokenAmount;

        IERC20(depositToken).safeTransferFrom(msg.sender, address(this), depositAmount);

        emit Deposited(msg.sender, depositAmount, tokenAmount);
        emit Sold(tokenAmount, totalSold);
    }

    // TEST :: multiple periods of buys and claims
    // show amount depositor can claim
    function claimable(address _claimer) external view returns (uint256) {
        Vest storage v = vests[_claimer];
        if (v.startTime == 0) return 0;

        uint256 elapsedTime = block.timestamp - v.startTime;
        if (elapsedTime > duration) elapsedTime = duration;
        uint256 amount = v.total * elapsedTime / duration;
        return amount - v.claimed;
    }

    // depositor claim token
    function claim(address _receiver) external {
        Vest storage v = vests[msg.sender];
        uint256 elapsedTime = block.timestamp - v.startTime;

        if (elapsedTime > duration) elapsedTime = duration;
        uint256 totalClaimable = v.total * elapsedTime / duration;
        if (totalClaimable > v.claimed) {
            uint256 amount = totalClaimable - v.claimed;
            mintedTokens += amount;
            
            require(mintedTokens <= maxMintableTokens, 'cannot claim more than max mintable');
            
            minter.mint(_receiver, amount, false);
            v.claimed = totalClaimable;

            emit Claimed(_receiver, amount);
        }
    }
    // ******************
    // **** USER END ****
    // ******************
}
