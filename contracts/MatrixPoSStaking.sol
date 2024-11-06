// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "./StakingTypes.sol";

interface IMatrixPoWStaking {
    function hasStakedNFTs(address user) external view returns (bool);
}

contract MatrixPoSStaking is ReentrancyGuard, Ownable, EIP712 {
    using ECDSA for bytes32;

    IERC20 public mlpToken;
    address public powContract;
    address public accountingAddress;

    struct Stake {
        uint256 amount;
        uint256 timestamp;
        uint256 lockPeriod;
    }

    mapping(address => mapping(MiningType => mapping(uint256 => Stake)))
        public stakes;
    mapping(address => mapping(MiningType => uint256)) public stakeCount;
    mapping(uint256 => uint256) public yearlyClaimedNFTRewards; // year => claimed amount
    mapping(uint256 => uint256) public yearlyClaimedMLPRewards; // year => claimed amount
    mapping(address => uint256) public nonces;
    mapping(address => bool) public operators;

    uint256 public rewardPool;
    address public rewardSigner;

    bytes32 private constant CLAIM_TYPEHASH =
        keccak256("Claim(address user,uint256 amount,uint256 nonce)");

    event TokenStaked(address indexed user, uint256 amount, uint256 timestamp);
    event TokenUnstaked(
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );
    event RewardClaimed(
        address indexed user,
        uint256 amount,
        uint256 timestamp,
        MiningType miningType
    );
    event RewardPoolFunded(uint256 amount, uint256 timestamp);
    event EmergencyWithdraw(
        address indexed owner,
        uint256 amount,
        uint256 timestamp
    );
    event StakeCreated(
        address indexed user,
        uint256 amount,
        uint256 timestamp,
        uint256 stakeId,
        uint256 lockPeriod,
        MiningType miningType
    );

    // Replace the constant with a variable
    uint256 public MINIMUM_STAKING_PERIOD = 72 hours;

    // Add enum for time units
    enum TimeUnit {
        Minutes,
        Hours,
        Days
    }

    // Define StakeToken struct
    struct StakeToken {
        NFTType nftType;
        uint256[] tokenIds;
    }

    // Add vesting schedule constants
    uint256 public constant YEAR_DURATION = 365 days;
    uint256[5] public VESTING_PERCENTAGES = [40, 30, 15, 10, 5]; // in percentage points

    // Add vesting variables
    uint256 public vestingStartTime;
    uint256 public totalMlpReward;

    bool public maxClaimableEnabled = true;

    // Add new events
    event MLPBoostedStaked(
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );
    event NFTBoostedStaked(
        address indexed user,
        uint256 tokenId,
        uint256 timestamp
    );

    // Add constants for pool distributions
    uint256 public constant NFT_BOOST_PERCENTAGE = 50;
    uint256 public constant MLP_BOOST_PERCENTAGE = 50;

    // Add staking period constants
    uint256 public constant THIRTY_DAYS = 30 days;
    uint256 public constant SIXTY_DAYS = 60 days;
    uint256 public constant NINETY_DAYS = 90 days;
    uint256 public constant ONE_EIGHTY_DAYS = 180 days;

    // Add the enum at contract level
    enum StakingType {
        FreeWithdraw,
        FullLocked
    }

    // Add state variable for minimum stake amount
    uint256 public minimumStakeAmount = 100 * 10 ** 18; // 100 MLP tokens

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
        address _powContract,
        address _accountingAddress
    ) Ownable(msg.sender) EIP712("MatrixStaking", "1") {
        mlpToken = IERC20(_token);
        rewardSigner = _rewardSigner;
        totalMlpReward = 1_250_000_000 * 10 ** 18; // 1.25B tokens with 18 decimals
        vestingStartTime = block.timestamp;
        powContract = _powContract;
        accountingAddress = _accountingAddress;
    }

    function setRewardSigner(address _rewardSigner) external onlyOwner {
        rewardSigner = _rewardSigner;
    }

    function setOperator(address _operator, bool _status) external onlyOwner {
        operators[_operator] = _status;
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

    // Update claimReward function with daily and cumulative caps
    function claimReward(
        uint256 amount,
        bytes memory signature
    ) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");

        bytes32 structHash = keccak256(
            abi.encode(CLAIM_TYPEHASH, msg.sender, amount, nonces[msg.sender])
        );
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = hash.recover(signature);
        require(signer == rewardSigner, "Invalid signature");

        nonces[msg.sender]++;

        // Check vesting schedule
        uint256 year = getCurrentVestingYear();
        require(year < 5, "Vesting period ended");

        MiningType miningType;
        if (hasNFTBoost(msg.sender)) {
            miningType = MiningType.NFTBoosted;
            yearlyClaimedNFTRewards[year] += amount;
        } else if (hasMLPBoost(msg.sender)) {
            miningType = MiningType.MLPBoosted;
            yearlyClaimedMLPRewards[year] += amount;
        } else {
            revert("No active boost");
        }

        // Only check maxClaimable if enabled
        if (maxClaimableEnabled) {
            uint256 maxClaimable = getMaxClaimableAmount(miningType);
            require(amount <= maxClaimable, "Amount exceeds maximum claimable");
        }

        require(rewardPool >= amount, "Insufficient reward pool balance");
        rewardPool -= amount;

        require(
            mlpToken.transfer(msg.sender, amount),
            "Reward transfer failed"
        );
        emit RewardClaimed(msg.sender, amount, block.timestamp, miningType);
    }

    // Add function to set vesting start time (only owner)
    function setVestingStartTime(uint256 _startTime) external onlyOwner {
        require(_startTime >= block.timestamp, "Start time must be in future");
        vestingStartTime = _startTime;
    }

    // Add view function to get total rewards for current year
    function getCurrentYearTotalRewards() public view returns (uint256) {
        uint256 year = getCurrentVestingYear();
        if (year >= 5) return 0;
        return (totalMlpReward * getCurrentVestingPercentage()) / 100;
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

    // Add helper function to get current daily cap
    function getCurrentDailyCap() public view returns (uint256) {
        uint256 year = getCurrentVestingYear();
        if (year >= 5) return 0;

        // Calculate daily cap based on current year's percentage
        uint256 yearlyAmount = (totalMlpReward *
            getCurrentVestingPercentage()) / 100;
        return yearlyAmount / YEAR_DURATION;
    }

    // Add helper function to get maximum claimable amount
    function getMaxClaimableAmount(
        MiningType miningType
    ) public view returns (uint256) {
        uint256 currentYear = getCurrentVestingYear();
        if (currentYear >= 5) return 0;

        uint256 poolPercentage;
        if (miningType == MiningType.NFTBoosted) {
            poolPercentage = NFT_BOOST_PERCENTAGE;
        } else {
            poolPercentage = MLP_BOOST_PERCENTAGE;
        }

        uint256 totalAllowedClaims = 0;

        // Add up completed years
        for (uint256 year = 0; year < currentYear; year++) {
            totalAllowedClaims +=
                (totalMlpReward * VESTING_PERCENTAGES[year] * poolPercentage) /
                10000;
        }

        // Add current year's claims up to current day
        uint256 currentYearAmount = (totalMlpReward *
            getCurrentVestingPercentage() *
            poolPercentage) / 10000;
        uint256 dailyCap = currentYearAmount / YEAR_DURATION;
        totalAllowedClaims += dailyCap * getCurrentDay();

        // Check claimed rewards for specific pool
        uint256 totalClaimedAllYears = 0;

        for (uint256 year = 0; year <= currentYear; year++) {
            if (miningType == MiningType.NFTBoosted) {
                totalClaimedAllYears += yearlyClaimedNFTRewards[year];
            } else {
                totalClaimedAllYears += yearlyClaimedMLPRewards[year];
            }
        }

        if (totalClaimedAllYears >= totalAllowedClaims) return 0;
        return totalAllowedClaims - totalClaimedAllYears;
    }

    // Add helper function to get current year's total claimed rewards
    function getCurrentYearClaimedRewards(
        MiningType miningType
    ) public view returns (uint256) {
        uint256 year = getCurrentVestingYear();
        return
            miningType == MiningType.NFTBoosted
                ? yearlyClaimedNFTRewards[year]
                : yearlyClaimedMLPRewards[year];
    }

    function getCurrentDay() public view returns (uint256) {
        return
            ((block.timestamp - vestingStartTime) % YEAR_DURATION) / 1 days + 1;
    }

    // Add function to set minimum staking period
    function setMinimumStakingPeriod(
        uint256 amount,
        TimeUnit unit
    ) external onlyOwner {
        if (unit == TimeUnit.Minutes) {
            MINIMUM_STAKING_PERIOD = amount * 1 minutes;
        } else if (unit == TimeUnit.Hours) {
            MINIMUM_STAKING_PERIOD = amount * 1 hours;
        } else {
            MINIMUM_STAKING_PERIOD = amount * 1 days;
        }
    }

    function enableMaxClaimable() external onlyOwner {
        maxClaimableEnabled = !maxClaimableEnabled;
    }

    // Add setter function for owner
    function setMinimumStakeAmount(uint256 _amount) external onlyOwner {
        minimumStakeAmount = _amount;
    }

    // Update staking functions to check minimum amount
    function stakeMlpBoosted(
        uint256 amount,
        uint256 stakingPeriod,
        StakingType stakingType
    ) external nonReentrant {
        require(amount >= minimumStakeAmount, "Amount below minimum stake");
        require(amount > 0, "Amount must be greater than 0");
        require(
            stakingPeriod == THIRTY_DAYS ||
                stakingPeriod == SIXTY_DAYS ||
                stakingPeriod == NINETY_DAYS ||
                stakingPeriod == ONE_EIGHTY_DAYS,
            "Invalid staking period"
        );

        require(
            mlpToken.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );

        uint256 stakeId = stakeCount[msg.sender][MiningType.MLPBoosted]++;
        stakes[msg.sender][MiningType.MLPBoosted][stakeId] = Stake({
            amount: amount,
            timestamp: block.timestamp,
            lockPeriod: stakingType == StakingType.FullLocked
                ? stakingPeriod
                : 0 // Only set lock period for FullLocked
        });
        emit StakeCreated(
            msg.sender,
            amount,
            block.timestamp,
            stakeId,
            stakingPeriod, // Always emit the actual staking period
            MiningType.MLPBoosted
        );
    }

    function stakeNFTBoosted(uint256 amount) external nonReentrant {
        require(amount >= minimumStakeAmount, "Amount below minimum stake");
        require(amount > 0, "Amount must be greater than 0");

        IMatrixPoWStaking pow = IMatrixPoWStaking(powContract);
        require(pow.hasStakedNFTs(msg.sender), "Must have valid staked NFTs");

        require(
            mlpToken.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );

        uint256 stakeId = stakeCount[msg.sender][MiningType.NFTBoosted]++;
        stakes[msg.sender][MiningType.NFTBoosted][stakeId] = Stake({
            amount: amount,
            timestamp: block.timestamp,
            lockPeriod: 0 // No lock period for NFT boosted stakes
        });
        emit StakeCreated(
            msg.sender,
            amount,
            block.timestamp,
            stakeId,
            0, // Lock period is 0
            MiningType.NFTBoosted
        );
    }

    // Add boost check functions
    function hasNFTBoost(address user) public view returns (bool) {
        uint256 total = getTotalStaked(user, MiningType.NFTBoosted);
        return total > 0;
    }

    function hasMLPBoost(address user) public view returns (bool) {
        uint256 total = getTotalStaked(user, MiningType.MLPBoosted);
        return total > 0;
    }

    function unstakeNFTBoosted(uint256 stakeId) external nonReentrant {
        Stake storage stake = stakes[msg.sender][MiningType.NFTBoosted][
            stakeId
        ];
        require(stake.amount > 0, "No stake found");
        require(
            block.timestamp >= stake.timestamp + stake.lockPeriod,
            "Lock period not ended"
        );

        uint256 amount = stake.amount;
        delete stakes[msg.sender][MiningType.NFTBoosted][stakeId];

        require(mlpToken.transfer(msg.sender, amount), "Transfer failed");
        emit TokenUnstaked(msg.sender, amount, block.timestamp);
    }

    function unstakeMLPBoosted(uint256 stakeId) external nonReentrant {
        Stake storage stake = stakes[msg.sender][MiningType.MLPBoosted][
            stakeId
        ];
        require(stake.amount > 0, "No stake found");

        if (stake.lockPeriod > 0) {
            // FullLocked type
            require(
                block.timestamp >= stake.timestamp + stake.lockPeriod,
                "Lock period not ended"
            );
        }

        uint256 amount = stake.amount;
        delete stakes[msg.sender][MiningType.MLPBoosted][stakeId];

        require(mlpToken.transfer(msg.sender, amount), "Transfer failed");
        emit TokenUnstaked(msg.sender, amount, block.timestamp);
    }

    // Add helper to get total staked amount for a user and mining type
    function getTotalStaked(
        address user,
        MiningType miningType
    ) public view returns (uint256) {
        uint256 total = 0;
        uint256 count = stakeCount[user][miningType];
        for (uint256 i = 0; i < count; i++) {
            total += stakes[user][miningType][i].amount;
        }
        return total;
    }

    function getUserStakes(
        address user,
        MiningType miningType
    )
        external
        view
        returns (
            uint256[] memory stakeIds,
            uint256[] memory amounts,
            uint256[] memory timestamps,
            uint256[] memory lockPeriods,
            bool[] memory isUnlocked
        )
    {
        uint256 count = stakeCount[user][miningType];
        stakeIds = new uint256[](count);
        amounts = new uint256[](count);
        timestamps = new uint256[](count);
        lockPeriods = new uint256[](count);
        isUnlocked = new bool[](count);

        for (uint256 i = 0; i < count; i++) {
            Stake storage stake = stakes[user][miningType][i];
            if (stake.amount > 0) {
                stakeIds[i] = i;
                amounts[i] = stake.amount;
                timestamps[i] = stake.timestamp;
                lockPeriods[i] = stake.lockPeriod;
                isUnlocked[i] =
                    block.timestamp >= stake.timestamp + stake.lockPeriod;
            }
        }

        return (stakeIds, amounts, timestamps, lockPeriods, isUnlocked);
    }

    function getStakingDetail(
        address user,
        uint256 stakeId,
        MiningType miningType
    )
        external
        view
        returns (
            uint256 amount,
            uint256 timestamp,
            uint256 lockPeriod,
            uint256 remainingTime,
            bool isUnlocked
        )
    {
        Stake storage stake = stakes[user][miningType][stakeId];
        require(stake.amount > 0, "No stake found");

        uint256 endTime = stake.timestamp + stake.lockPeriod;
        remainingTime = block.timestamp >= endTime
            ? 0
            : endTime - block.timestamp;
        isUnlocked = block.timestamp >= endTime;

        return (
            stake.amount,
            stake.timestamp,
            stake.lockPeriod,
            remainingTime,
            isUnlocked
        );
    }
}
