// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MatrixNFT is
    Initializable,
    ERC721Upgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using MerkleProof for bytes32[];

    uint256 public tokenCounter;
    string private baseTokenURI;
    mapping(address => bool) public operators;

    bytes32 public whitelistRoot;
    bool public isWhitelistActive;

    event WhitelistStatusChanged(bool isActive);
    event MerkleRootChanged(bytes32 newMerkleRoot);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory name,
        string memory symbol,
        address initialOwner
    ) public initializer {
        __ERC721_init(name, symbol);
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();

        tokenCounter = 0;
        isWhitelistActive = false;
    }

    modifier onlyOwnerOrOperator() {
        require(
            msg.sender == owner() || operators[msg.sender],
            "Caller is not the owner or an operator"
        );
        _;
    }

    function setOperator(address _operator, bool _status) external onlyOwner {
        operators[_operator] = _status;
    }

    function setMerkleRoot(bytes32 _whitelistRoot) external onlyOwner {
        whitelistRoot = _whitelistRoot;
        emit MerkleRootChanged(_whitelistRoot);
    }

    function setWhitelistStatus(bool _isActive) external onlyOwner {
        isWhitelistActive = _isActive;
        emit WhitelistStatusChanged(_isActive);
    }

    function mint(address to, uint256 quantity) external onlyOwnerOrOperator {
        require(quantity > 0, "Quantity must be greater than zero");
        for (uint256 i = 0; i < quantity; i++) {
            _mintToken(to);
        }
    }

    function whitelistMint(address to, bytes32[] calldata proof) external {
        require(isWhitelistActive, "Whitelist minting is not active");
        require(
            MerkleProof.verify(
                proof,
                whitelistRoot,
                keccak256(abi.encodePacked(to))
            ),
            "Not in whitelist"
        );
        _mintToken(to);
    }

    function _mintToken(address to) internal {
        _safeMint(to, tokenCounter);
        tokenCounter += 1;
    }

    function tokensOwned(
        address owner
    ) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        uint256 index = 0;
        for (uint256 tokenId = 0; tokenId < tokenCounter; tokenId++) {
            if (ownerOf(tokenId) == owner) {
                tokenIds[index] = tokenId;
                index += 1;
            }
        }
        return tokenIds;
    }

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721Upgradeable) returns (address) {
        address from = _ownerOf(tokenId);
        if (from != address(0)) {
            revert("This token is soulbound and cannot be transferred");
        }

        return super._update(to, tokenId, auth);
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(
            ownerOf(tokenId) != address(0),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return baseTokenURI;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
