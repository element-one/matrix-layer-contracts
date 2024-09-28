pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract MatrixStaking is ReentrancyGuard, Ownable, EIP712 {
    using ECDSA for bytes32;

    IERC20 public wlpToken;
    IERC721 public nftContract;

    enum NFTType {
        AiAgentOne,
        AiAgentPro,
        AiAgentUltra,
        AiAgentOrigin
    }

    struct Stake {
        uint256 amount;
        uint256 timestamp;
    }

    struct NFTStake {
        NFTType nftType;
        uint256 tokenId;
        uint256 timestamp;
    }

    mapping(address => Stake) public wlpStakes;
    mapping(address => NFTStake[]) public nftStakes;
    mapping(NFTType => uint256) public nftRewardRates;
    uint256 public wlpRewardRate;

    address public rewardSigner;
    mapping(address => uint256) public nonces;

    bytes32 private constant CLAIM_TYPEHASH =
        keccak256("Claim(address user,uint256 amount,uint256 nonce)");

    event WLPStaked(address indexed user, uint256 amount);
    event WLPUnstaked(address indexed user, uint256 amount);
    event NFTStaked(address indexed user, NFTType nftType, uint256 tokenId);
    event NFTUnstaked(address indexed user, NFTType nftType, uint256 tokenId);
    event RewardClaimed(address indexed user, uint256 amount);

    constructor(
        address _wlpToken,
        address _nftContract,
        address _rewardSigner
    ) Ownable(msg.sender) EIP712("MatrixStaking", "1") {
        wlpToken = IERC20(_wlpToken);
        nftContract = IERC721(_nftContract);
        rewardSigner = _rewardSigner;
    }

    function setRewardRates(
        uint256 _wlpRate,
        uint256[4] memory _nftRates
    ) external onlyOwner {
        wlpRewardRate = _wlpRate;
        nftRewardRates[NFTType.AiAgentOne] = _nftRates[0];
        nftRewardRates[NFTType.AiAgentPro] = _nftRates[1];
        nftRewardRates[NFTType.AiAgentUltra] = _nftRates[2];
        nftRewardRates[NFTType.AiAgentOrigin] = _nftRates[3];
    }

    function stakeWLP(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(
            wlpToken.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );

        wlpStakes[msg.sender].amount += amount;
        wlpStakes[msg.sender].timestamp = block.timestamp;

        emit WLPStaked(msg.sender, amount);
    }

    function unstakeWLP(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(
            wlpStakes[msg.sender].amount >= amount,
            "Insufficient staked amount"
        );

        wlpStakes[msg.sender].amount -= amount;
        require(wlpToken.transfer(msg.sender, amount), "Transfer failed");

        emit WLPUnstaked(msg.sender, amount);
    }

    function stakeNFT(NFTType nftType, uint256 tokenId) external nonReentrant {
        require(
            nftContract.ownerOf(tokenId) == msg.sender,
            "Not the owner of the NFT"
        );
        nftContract.transferFrom(msg.sender, address(this), tokenId);

        nftStakes[msg.sender].push(NFTStake(nftType, tokenId, block.timestamp));

        emit NFTStaked(msg.sender, nftType, tokenId);
    }

    function unstakeNFT(uint256 index) external nonReentrant {
        require(index < nftStakes[msg.sender].length, "Invalid index");

        NFTStake memory stake = nftStakes[msg.sender][index];
        nftContract.transferFrom(address(this), msg.sender, stake.tokenId);

        // Remove the NFT stake from the array
        nftStakes[msg.sender][index] = nftStakes[msg.sender][
            nftStakes[msg.sender].length - 1
        ];
        nftStakes[msg.sender].pop();

        emit NFTUnstaked(msg.sender, stake.nftType, stake.tokenId);
    }

    function claimRewards(
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

        require(
            wlpToken.transfer(msg.sender, amount),
            "Reward transfer failed"
        );

        emit RewardClaimed(msg.sender, amount);
    }
}
