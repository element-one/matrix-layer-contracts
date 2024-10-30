// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract MatrixPoWStaking is ReentrancyGuard, Ownable, EIP712 {
    using ECDSA for bytes32;

    IERC20 public mlpToken;

    enum NFTType {
        Phone,
        Matrix,
        AiAgentOne,
        AiAgentPro,
        AiAgentUltra
    }

    mapping(NFTType => IERC721) public nftContracts;

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
    event NFTStaked(
        address indexed user,
        NFTType nftType,
        uint256 tokenId,
        uint256 timestamp
    );
    event NFTUnstaked(
        address indexed user,
        NFTType nftType,
        uint256 tokenId,
        uint256 timestamp
    );
    event RewardClaimed(
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );
    event NFTContractSet(NFTType nftType, address contractAddress);
    event RewardPoolFunded(uint256 amount, uint256 timestamp);
    event EmergencyWithdraw(
        address indexed owner,
        uint256 amount,
        uint256 timestamp
    );

    // Add constant for minimum staking period (72 hours in seconds)
    uint256 public constant MINIMUM_STAKING_PERIOD = 72 hours;

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

    constructor(
        address _token,
        address _rewardSigner,
        address[5] memory _nftContracts
    ) Ownable(msg.sender) EIP712("MatrixStaking", "1") {
        mlpToken = IERC20(_token);
        rewardSigner = _rewardSigner;
        totalMlpReward = 1_250_000_000 * 10 ** 18; // 1.25B tokens with 18 decimals
        vestingStartTime = block.timestamp;

        for (uint i = 0; i < 5; i++) {
            nftContracts[NFTType(i)] = IERC721(_nftContracts[i]);
            emit NFTContractSet(NFTType(i), _nftContracts[i]);
        }
    }

    function setRewardSigner(address _rewardSigner) external onlyOwner {
        rewardSigner = _rewardSigner;
    }

    function fundRewardPool(uint256 amount) external onlyOwner {
        require(
            mlpToken.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );
        rewardPool += amount;
        emit RewardPoolFunded(amount, block.timestamp);
    }

    // Single NFT stake function
    function stakeNFT(NFTType nftType, uint256 tokenId) external nonReentrant {
        IERC721 nftContract = nftContracts[nftType];
        require(address(nftContract) != address(0), "NFT type not supported");
        require(
            nftContract.ownerOf(tokenId) == msg.sender,
            "Not the owner of the NFT"
        );
        require(
            nftStakes[msg.sender][nftType][tokenId] == 0,
            "NFT already staked"
        );

        // Add approval check
        require(
            nftContract.isApprovedForAll(msg.sender, address(this)) ||
                nftContract.getApproved(tokenId) == address(this),
            "Contract not approved"
        );

        // Transfer NFT to staking contract
        nftContract.transferFrom(msg.sender, address(this), tokenId);

        uint256 timestamp = block.timestamp;
        nftStakes[msg.sender][nftType][tokenId] = timestamp;
        totalStakedNFTs[nftType]++;
        userTotalStakedNFTs[msg.sender]++;

        emit NFTStaked(msg.sender, nftType, tokenId, timestamp);
    }

    // Batch stake function
    function stakeNFTs(StakeToken[] calldata _stakes) external nonReentrant {
        require(_stakes.length > 0, "Empty stake array");
        uint256 timestamp = block.timestamp;

        for (uint256 i = 0; i < _stakes.length; i++) {
            NFTType nftType = _stakes[i].nftType;
            uint256[] memory tokenIds = _stakes[i].tokenIds;

            require(tokenIds.length > 0, "Empty tokenIds array");
            IERC721 nftContract = nftContracts[nftType];
            require(
                address(nftContract) != address(0),
                "NFT type not supported"
            );

            // Add approval check for batch - can optimize if isApprovedForAll is true
            bool isApprovedForAll = nftContract.isApprovedForAll(
                msg.sender,
                address(this)
            );

            for (uint256 j = 0; j < tokenIds.length; j++) {
                uint256 tokenId = tokenIds[j];
                require(
                    nftContract.ownerOf(tokenId) == msg.sender,
                    "Not the owner of the NFT"
                );
                require(
                    nftStakes[msg.sender][nftType][tokenId] == 0,
                    "NFT already staked"
                );

                // Check individual token approval only if not approved for all
                if (!isApprovedForAll) {
                    require(
                        nftContract.getApproved(tokenId) == address(this),
                        "Contract not approved"
                    );
                }

                // Transfer NFT to staking contract
                nftContract.transferFrom(msg.sender, address(this), tokenId);

                nftStakes[msg.sender][nftType][tokenId] = timestamp;
                totalStakedNFTs[nftType]++;
                userTotalStakedNFTs[msg.sender]++;

                emit NFTStaked(msg.sender, nftType, tokenId, timestamp);
            }
        }
    }

    function unstakeNFT(
        NFTType nftType,
        uint256 tokenId
    ) external nonReentrant {
        IERC721 nftContract = nftContracts[nftType];
        require(address(nftContract) != address(0), "NFT type not supported");

        uint256 stakeTimestamp = nftStakes[msg.sender][nftType][tokenId];
        require(stakeTimestamp != 0, "NFT not staked");

        require(
            block.timestamp >= stakeTimestamp + MINIMUM_STAKING_PERIOD,
            "Cannot unstake before 72 hours"
        );

        // Verify the NFT is owned by the contract
        require(
            nftContract.ownerOf(tokenId) == address(this),
            "NFT not in staking contract"
        );

        uint256 timestamp = block.timestamp;

        // Transfer NFT back to user
        nftContract.transferFrom(address(this), msg.sender, tokenId);

        if (nftType != NFTType.Phone && nftType != NFTType.Matrix) {
            delete nftStakes[msg.sender][nftType][tokenId];
        }

        totalStakedNFTs[nftType]--;
        userTotalStakedNFTs[msg.sender]--;

        emit NFTUnstaked(msg.sender, nftType, tokenId, timestamp);
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

    // Add function to get current vesting year and percentage
    function getCurrentVestingInfo()
        public
        view
        returns (uint256 year, uint256 percentage)
    {
        if (block.timestamp < vestingStartTime) return (0, 0);

        uint256 timePassed = block.timestamp - vestingStartTime;
        year = timePassed / YEAR_DURATION;

        if (year >= 5) return (5, 0);
        percentage = VESTING_PERCENTAGES[year];
        return (year, percentage);
    }

    // Update claimReward function with daily and cumulative caps
    function claimReward(
        uint256 amount,
        bytes memory signature
    ) external nonReentrant {
        bytes32 structHash = keccak256(
            abi.encode(CLAIM_TYPEHASH, msg.sender, amount, nonces[msg.sender])
        );
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = hash.recover(signature);
        require(signer == rewardSigner, "Invalid signature");

        nonces[msg.sender]++;

        // Check vesting schedule
        (uint256 year, ) = getCurrentVestingInfo();
        require(year < 5, "Vesting period ended");

        uint256 maxClaimable = getMaxClaimableAmount();
        require(amount <= maxClaimable, "Amount exceeds maximum claimable");

        require(rewardPool >= amount, "Insufficient reward pool balance");
        rewardPool -= amount;
        yearlyClaimedRewards[year] += amount;

        require(
            mlpToken.transfer(msg.sender, amount),
            "Reward transfer failed"
        );
        emit RewardClaimed(msg.sender, amount, block.timestamp);
    }

    // Add function to set vesting start time (only owner)
    function setVestingStartTime(uint256 _startTime) external onlyOwner {
        require(_startTime >= block.timestamp, "Start time must be in future");
        vestingStartTime = _startTime;
    }

    // Add view function to get total rewards for current year
    function getCurrentYearTotalRewards() public view returns (uint256) {
        (uint256 year, uint256 percentage) = getCurrentVestingInfo();
        if (year >= 5) return 0;
        return (totalMlpReward * percentage) / 100;
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
        (uint256 year, uint256 percentage) = getCurrentVestingInfo();
        if (year >= 5) return 0;

        // Calculate daily cap based on current year's percentage
        uint256 yearlyAmount = (totalMlpReward * percentage) / 100;
        return yearlyAmount / YEAR_DURATION;
    }

    // Add helper function to get maximum claimable amount
    function getMaxClaimableAmount() public view returns (uint256) {
        (uint256 currentYear, uint256 percentage) = getCurrentVestingInfo();
        if (currentYear >= 5) return 0;

        uint256 totalAllowedClaims = 0;

        // Add up completed years
        for (uint256 year = 0; year < currentYear; year++) {
            totalAllowedClaims +=
                (totalMlpReward * VESTING_PERCENTAGES[year]) /
                100;
        }

        // Add current year's claims up to current day
        uint256 currentYearAmount = (totalMlpReward * percentage) / 100;
        uint256 dailyCap = currentYearAmount / YEAR_DURATION;
        totalAllowedClaims += dailyCap * getCurrentDay();

        uint256 totalClaimedAllYears = 0;
        for (uint256 year = 0; year <= currentYear; year++) {
            totalClaimedAllYears += yearlyClaimedRewards[year];
        }

        if (totalClaimedAllYears >= totalAllowedClaims) return 0;
        return totalAllowedClaims - totalClaimedAllYears;
    }

    // Add helper function to get current year's total claimed rewards
    function getCurrentYearClaimedRewards() public view returns (uint256) {
        (uint256 year, ) = getCurrentVestingInfo();
        return yearlyClaimedRewards[year];
    }

    function getCurrentDay() public view returns (uint256) {
        return
            ((block.timestamp - vestingStartTime) % YEAR_DURATION) / 1 days + 1;
    }
}
