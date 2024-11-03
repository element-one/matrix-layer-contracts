// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "./StakingTypes.sol";

import "hardhat/console.sol";

interface IMatrixNFT is IERC721 {
    function tokensOwned(
        address owner
    ) external view returns (uint256[] memory);
}

contract MatrixPoSStaking is ReentrancyGuard, Ownable, EIP712 {
    using ECDSA for bytes32;

    IERC20 public mlpToken;

    address public nftStaking;

    struct Stake {
        uint256 amount;
        uint256 timestamp;
    }

    mapping(address => Stake) public tokenStakes;
    mapping(address => mapping(NFTType => mapping(uint256 => uint256)))
        public nftStakes; // user => NFTType => tokenId => stakeTimestamp
    mapping(NFTType => uint256) public totalStakedNFTs; // Total staked NFTs for each type
    mapping(address => uint256) public userTotalStakedNFTs; // Total staked NFTs for each user

    uint256 public rewardPool;

    address public rewardSigner;
    mapping(address => uint256) public nonces;

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
    mapping(uint256 => uint256) public yearlyClaimedRewards; // year => claimed amount

    mapping(address => bool) public operators;

    bool public maxClaimableEnabled = true;

    // Add new mappings for boosted stakes
    mapping(address => uint256) public mlpStakes;

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
        address _staking
    ) Ownable(msg.sender) EIP712("MatrixStaking", "1") {
        mlpToken = IERC20(_token);
        rewardSigner = _rewardSigner;
        totalMlpReward = 1_250_000_000 * 10 ** 18; // 1.25B tokens with 18 decimals
        vestingStartTime = block.timestamp;
        nftStaking = _staking;
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

    // Add helper function to check remaining lock time
    function getRemainingLockTime(
        NFTType nftType,
        uint256 tokenId,
        address user
    ) external view returns (uint256) {
        uint256 stakeTimestamp = nftStakes[user][nftType][tokenId];
        if (stakeTimestamp == 0) return 0;

        uint256 unlockTime = stakeTimestamp + MINIMUM_STAKING_PERIOD;
        if (block.timestamp >= unlockTime) return 0;

        return unlockTime - block.timestamp;
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

        // Only check maxClaimable if enabled
        if (maxClaimableEnabled) {
            uint256 maxClaimable = getMaxClaimableAmount();
            console.log("maxClaimable", maxClaimable);
            console.log("amount", amount);
            require(amount <= maxClaimable, "Amount exceeds maximum claimable");
        }

        require(rewardPool >= amount, "Insufficient reward pool balance");
        rewardPool -= amount;
        yearlyClaimedRewards[year] += amount;

        require(
            mlpToken.transfer(msg.sender, amount),
            "Reward transfer failed"
        );
        emit RewardClaimed(msg.sender, amount, block.timestamp, MiningType.POW);
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

    function getTotalStakedNFTs() public view returns (uint256[5] memory) {
        uint256[5] memory result;
        for (uint i = 0; i < 5; i++) {
            result[i] = totalStakedNFTs[NFTType(i)];
        }
        return result;
    }

    function getUserStakedNFTs(address user) public view returns (uint256) {
        return userTotalStakedNFTs[user];
    }

    // Emergency withdrawal function for MLP tokens
    function emergencyWithdrawMlpToken(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(
            amount <= mlpToken.balanceOf(address(this)),
            "Insufficient balance"
        );

        require(mlpToken.transfer(msg.sender, amount), "Transfer failed");

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
    function getMaxClaimableAmount() public view returns (uint256) {
        uint256 currentYear = getCurrentVestingYear();
        if (currentYear >= 5) return 0;

        uint256 totalAllowedClaims = 0;

        // Add up completed years
        for (uint256 year = 0; year < currentYear; year++) {
            totalAllowedClaims +=
                (totalMlpReward * VESTING_PERCENTAGES[year]) /
                100;
        }
        console.log("totalAllowedClaims", totalAllowedClaims);

        // Add current year's claims up to current day
        uint256 currentYearAmount = (totalMlpReward *
            getCurrentVestingPercentage()) / 100;
        console.log("currentYearAmount", currentYearAmount);
        uint256 dailyCap = currentYearAmount / YEAR_DURATION;
        console.log("dailyCap", dailyCap);
        totalAllowedClaims += dailyCap * getCurrentDay();
        console.log("totalAllowedClaims", totalAllowedClaims);
        uint256 totalClaimedAllYears = 0;
        for (uint256 year = 0; year <= currentYear; year++) {
            totalClaimedAllYears += yearlyClaimedRewards[year];
        }
        console.log("totalClaimedAllYears", totalClaimedAllYears);
        if (totalClaimedAllYears >= totalAllowedClaims) return 0;
        console.log(
            "totalAllowedClaims - totalClaimedAllYears",
            totalAllowedClaims - totalClaimedAllYears
        );
        return totalAllowedClaims - totalClaimedAllYears;
    }

    // Add helper function to get current year's total claimed rewards
    function getCurrentYearClaimedRewards() public view returns (uint256) {
        uint256 year = getCurrentVestingYear();
        return yearlyClaimedRewards[year];
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

    // Add new staking functions
    function stakeMlpBoosted(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(
            mlpToken.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );

        mlpStakes[msg.sender] += amount;
        emit MLPBoostedStaked(msg.sender, amount, block.timestamp);
    }

    function stakeNFTBoosted(uint256 tokenId) external nonReentrant {
        require(nftToken.ownerOf(tokenId) == msg.sender, "Not the owner");
        require(tokenStaker[tokenId] == address(0), "NFT already staked");

        nftToken.transferFrom(msg.sender, address(this), tokenId);

        userTotalStakedNFTs[msg.sender]++;
        tokenStaker[tokenId] = msg.sender;
        userStakedNFTCount[msg.sender][tokenId]++;

        emit NFTBoostedStaked(msg.sender, tokenId, block.timestamp);
    }

    // Add boost check functions
    function hasNFTBoost(address user) public view returns (bool) {
        return userTotalStakedNFTs[user] > 0;
    }

    function hasMLPBoost(address user) public view returns (bool) {
        return mlpStakes[user] > 0;
    }

    // Add withdrawal functions
    function withdrawMlpStake(uint256 amount) external nonReentrant {
        require(mlpStakes[msg.sender] >= amount, "Insufficient staked amount");
        mlpStakes[msg.sender] -= amount;
        require(mlpToken.transfer(msg.sender, amount), "Transfer failed");
    }

    function withdrawNFTStake(uint256 tokenId) external nonReentrant {
        require(
            tokenStaker[tokenId] == msg.sender,
            "Not the staker of this NFT"
        );
        require(
            userStakedNFTCount[msg.sender][tokenId] > 0,
            "NFT not staked by user"
        );

        userTotalStakedNFTs[msg.sender]--;
        tokenStaker[tokenId] = address(0);
        userStakedNFTCount[msg.sender][tokenId]--;

        nftToken.transferFrom(address(this), msg.sender, tokenId);
    }
}
