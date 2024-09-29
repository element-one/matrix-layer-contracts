// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract MatrixStaking is ReentrancyGuard, Ownable, EIP712 {
    using ECDSA for bytes32;

    IERC20 public token;

    enum NFTType {
        Phone,
        Matrix,
        AiAgentOne,
        AiAgentPro,
        AiAgentUltra
    }
    enum RewardType {
        Basic,
        Accelerate,
        Ecosystem
    }

    mapping(NFTType => IERC721) public nftContracts;

    struct Stake {
        uint256 amount;
        uint256 timestamp;
    }

    struct NFTStake {
        uint256 stakeTimestamp;
        uint256 firstStakeTimestamp;
    }

    mapping(address => Stake) public tokenStakes;
    mapping(address => mapping(NFTType => mapping(uint256 => NFTStake)))
        public nftStakes; // user => NFTType => tokenId => NFTStake
    mapping(NFTType => uint256) public totalStakedNFTs; // Total staked NFTs for each type
    mapping(address => uint256) public userTotalStakedNFTs; // Total staked NFTs for each user

    mapping(RewardType => uint256) public rewardPools;

    address public rewardSigner;
    mapping(address => mapping(RewardType => uint256)) public nonces;

    uint256 public constant PHONE_STAKE_LOCK_PERIOD = 30 days;

    bytes32 private constant CLAIM_TYPEHASH =
        keccak256(
            "Claim(address user,uint256 amount,uint256 nonce,RewardType rewardType)"
        );

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
        uint256 timestamp,
        uint256 firstStakeTimestamp
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
        RewardType rewardType,
        uint256 timestamp
    );
    event NFTContractSet(NFTType nftType, address contractAddress);
    event RewardPoolFunded(
        RewardType rewardType,
        uint256 amount,
        uint256 timestamp
    );

    constructor(
        address _token,
        address _rewardSigner,
        address[5] memory _nftContracts
    ) Ownable(msg.sender) EIP712("MatrixStaking", "1") {
        token = IERC20(_token);
        rewardSigner = _rewardSigner;

        for (uint i = 0; i < 5; i++) {
            nftContracts[NFTType(i)] = IERC721(_nftContracts[i]);
            emit NFTContractSet(NFTType(i), _nftContracts[i]);
        }
    }

    function setRewardSigner(address _rewardSigner) external onlyOwner {
        rewardSigner = _rewardSigner;
    }

    function fundRewardPool(
        RewardType rewardType,
        uint256 amount
    ) external onlyOwner {
        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );
        rewardPools[rewardType] += amount;
        emit RewardPoolFunded(rewardType, amount, block.timestamp);
    }

    function stakeToken(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );

        uint256 timestamp = block.timestamp;
        tokenStakes[msg.sender].amount += amount;
        tokenStakes[msg.sender].timestamp = timestamp;

        emit TokenStaked(msg.sender, amount, timestamp);
    }

    function unstakeToken(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(
            tokenStakes[msg.sender].amount >= amount,
            "Insufficient staked amount"
        );

        tokenStakes[msg.sender].amount -= amount;
        require(token.transfer(msg.sender, amount), "Transfer failed");

        uint256 timestamp = block.timestamp;
        emit TokenUnstaked(msg.sender, amount, timestamp);
    }

    function stakeNFT(NFTType nftType, uint256 tokenId) external nonReentrant {
        IERC721 nftContract = nftContracts[nftType];
        require(address(nftContract) != address(0), "NFT type not supported");
        require(
            nftContract.ownerOf(tokenId) == msg.sender,
            "Not the owner of the NFT"
        );
        require(
            nftStakes[msg.sender][nftType][tokenId].stakeTimestamp == 0,
            "NFT already staked"
        );

        uint256 timestamp = block.timestamp;

        if (nftType == NFTType.Phone) {
            require(
                nftStakes[msg.sender][nftType][tokenId].firstStakeTimestamp ==
                    0 ||
                    timestamp <=
                    nftStakes[msg.sender][nftType][tokenId]
                        .firstStakeTimestamp +
                        PHONE_STAKE_LOCK_PERIOD,
                "Phone NFT can't be restaked after 30 days from first stake"
            );

            if (
                nftStakes[msg.sender][nftType][tokenId].firstStakeTimestamp == 0
            ) {
                nftStakes[msg.sender][nftType][tokenId]
                    .firstStakeTimestamp = timestamp;
            }
        }

        nftContract.transferFrom(msg.sender, address(this), tokenId);
        nftStakes[msg.sender][nftType][tokenId].stakeTimestamp = timestamp;

        totalStakedNFTs[nftType]++;
        userTotalStakedNFTs[msg.sender]++;

        emit NFTStaked(
            msg.sender,
            nftType,
            tokenId,
            timestamp,
            nftStakes[msg.sender][nftType][tokenId].firstStakeTimestamp
        );
    }

    function unstakeNFT(
        NFTType nftType,
        uint256 tokenId
    ) external nonReentrant {
        IERC721 nftContract = nftContracts[nftType];
        require(address(nftContract) != address(0), "NFT type not supported");
        require(
            nftStakes[msg.sender][nftType][tokenId].stakeTimestamp != 0,
            "NFT not staked"
        );

        uint256 timestamp = block.timestamp;
        uint256 firstStakeTimestamp = nftStakes[msg.sender][nftType][tokenId]
            .firstStakeTimestamp;

        delete nftStakes[msg.sender][nftType][tokenId].stakeTimestamp;
        nftContract.transferFrom(address(this), msg.sender, tokenId);

        totalStakedNFTs[nftType]--;
        userTotalStakedNFTs[msg.sender]--;

        emit NFTUnstaked(msg.sender, nftType, tokenId, timestamp);
    }

    function claimReward(
        uint256 amount,
        RewardType rewardType,
        bytes memory signature
    ) external nonReentrant {
        bytes32 structHash = keccak256(
            abi.encode(
                CLAIM_TYPEHASH,
                msg.sender,
                amount,
                nonces[msg.sender][rewardType],
                rewardType
            )
        );
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = hash.recover(signature);
        require(signer == rewardSigner, "Invalid signature");

        nonces[msg.sender][rewardType]++;

        require(
            rewardPools[rewardType] >= amount,
            "Insufficient reward pool balance"
        );
        rewardPools[rewardType] -= amount;
        require(token.transfer(msg.sender, amount), "Reward transfer failed");

        emit RewardClaimed(msg.sender, amount, rewardType, block.timestamp);
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
}
