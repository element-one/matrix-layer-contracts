// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract MatrixPromotionStaking is ReentrancyGuard, Ownable, EIP712 {
    using ECDSA for bytes32;

    IERC20 public mlpToken;
    address public accountingAddress;

    address public rewardSigner;
    mapping(address => uint256) public nonces;

    uint256 public rewardPool;

    // Vesting logic
    uint256 public constant YEAR_DURATION = 365 days;
    uint256[5] public VESTING_PERCENTAGES = [40, 30, 15, 10, 5]; // in percentage points
    uint256 public vestingStartTime;
    uint256 public totalMlpReward = 1_250_000_000 * 10 ** 18; // Example total reward

    // Max claimable logic
    bool public maxClaimableEnabled = true;

    bytes32 private constant CLAIM_TYPEHASH =
        keccak256("Claim(address user,uint256 amount,uint256 nonce)");

    event RewardClaimed(
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );
    event RewardPoolFunded(uint256 amount, uint256 timestamp);
    event EmergencyWithdraw(
        address indexed owner,
        uint256 amount,
        uint256 timestamp
    );

    mapping(address => bool) public operators;

    // New mappings for daily reward tracking
    mapping(address => uint256) public lastClaimTimestamp;
    mapping(address => uint256) public dailyClaimedAmount;
    mapping(address => uint256) public totalClaimedAmount;

    // Mapping for yearly claimed rewards
    mapping(uint256 => uint256) public yearlyClaimedRewards; // year => claimed amount

    modifier onlyOwnerOrOperator() {
        require(
            msg.sender == owner() || operators[msg.sender],
            "Caller is not the owner or an operator"
        );
        _;
    }

    constructor(
        address _token,
        address _rewardSigner,
        address _accountingAddress
    ) Ownable(msg.sender) EIP712("MatrixPromotionStaking", "1") {
        mlpToken = IERC20(_token);
        rewardSigner = _rewardSigner;
        accountingAddress = _accountingAddress;
        vestingStartTime = block.timestamp;
    }

    function setRewardSigner(address _rewardSigner) external onlyOwner {
        rewardSigner = _rewardSigner;
    }

    function setOperator(address _operator, bool _status) external onlyOwner {
        operators[_operator] = _status;
    }

    function toggleMaxClaimable() external onlyOwner {
        maxClaimableEnabled = !maxClaimableEnabled;
    }

    function fundRewardPool(uint256 amount) external onlyOwnerOrOperator {
        require(
            mlpToken.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );
        rewardPool += amount;
        emit RewardPoolFunded(amount, block.timestamp);
    }

    // Get current vesting year (0-5)
    function getCurrentVestingYear() public view returns (uint256) {
        if (block.timestamp < vestingStartTime) return 0;

        uint256 timePassed = block.timestamp - vestingStartTime;
        uint256 year = timePassed / YEAR_DURATION;

        return year >= 5 ? 5 : year;
    }

    // Get current vesting percentage (40,30,15,10,5,0)
    function getCurrentVestingPercentage() public view returns (uint256) {
        uint256 year = getCurrentVestingYear();
        if (year >= 5) return 0;

        return VESTING_PERCENTAGES[year];
    }

    // Calculate the maximum claimable amount based on vesting
    function getMaxClaimableAmount(address user) public view returns (uint256) {
        uint256 year = getCurrentVestingYear();
        if (year >= 5) return 0;

        uint256 totalAllowedClaims = 0;

        // Add up completed years
        for (uint256 i = 0; i < year; i++) {
            totalAllowedClaims +=
                (totalMlpReward * VESTING_PERCENTAGES[i]) /
                100;
        }

        // Add current year's claims up to current day
        uint256 currentYearAmount = (totalMlpReward *
            getCurrentVestingPercentage()) / 100;
        uint256 dailyCap = currentYearAmount / YEAR_DURATION;
        uint256 daysPassed = (block.timestamp - vestingStartTime) %
            YEAR_DURATION;
        totalAllowedClaims += dailyCap * daysPassed;

        uint256 totalClaimed = totalClaimedAmount[user];
        if (totalClaimed >= totalAllowedClaims) return 0;
        return totalAllowedClaims - totalClaimed;
    }

    function claimReward(
        uint256 amount,
        bytes memory signature
    ) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");

        // Vesting logic
        uint256 year = getCurrentVestingYear();
        require(year < 5, "Vesting period ended");

        if (maxClaimableEnabled) {
            uint256 maxClaimable = getMaxClaimableAmount(msg.sender);
            require(amount <= maxClaimable, "Exceeds vested amount");
        }

        bytes32 structHash = keccak256(
            abi.encode(CLAIM_TYPEHASH, msg.sender, amount, nonces[msg.sender])
        );
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = hash.recover(signature);
        require(signer == rewardSigner, "Invalid signature");

        nonces[msg.sender]++;

        require(rewardPool >= amount, "Insufficient reward pool balance");
        rewardPool -= amount;

        require(
            mlpToken.transfer(msg.sender, amount),
            "Reward transfer failed"
        );

        // Update daily claimed amount and timestamp
        dailyClaimedAmount[msg.sender] += amount;
        lastClaimTimestamp[msg.sender] = block.timestamp;
        totalClaimedAmount[msg.sender] += amount;

        // Update yearly claimed rewards
        yearlyClaimedRewards[year] += amount;

        emit RewardClaimed(msg.sender, amount, block.timestamp);
    }

    // Emergency withdrawal function for MLP tokens
    function emergencyWithdrawMlpToken(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(
            amount <= mlpToken.balanceOf(address(this)),
            "Insufficient balance"
        );

        require(
            mlpToken.transfer(accountingAddress, amount),
            "Transfer failed"
        );

        // Update reward pool balance
        if (amount <= rewardPool) {
            rewardPool -= amount;
        } else {
            rewardPool = 0;
        }

        emit EmergencyWithdraw(msg.sender, amount, block.timestamp);
    }
}
