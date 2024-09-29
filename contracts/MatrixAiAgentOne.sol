// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MatrixAiAgentOne is ERC721, Ownable {
    uint256 public tokenCounter;
    string private baseTokenURI;
    address public operator;
    mapping(address => bool) public whitelistedAddresses;

    constructor(
        address initialOwner
    ) ERC721("AI Agent One", "AAO") Ownable(initialOwner) {
        tokenCounter = 0;
    }

    modifier onlyOwnerOrOperator() {
        require(
            msg.sender == owner() || msg.sender == operator,
            "Caller is not the owner or operator"
        );
        _;
    }

    function setOperator(address _operator) external onlyOwner {
        operator = _operator;
    }

    function setWhitelistedAddress(
        address _address,
        bool _status
    ) external onlyOwner {
        whitelistedAddresses[_address] = _status;
    }

    function mint(address to, uint256 quantity) external onlyOwnerOrOperator {
        require(quantity > 0, "Quantity must be greater than zero");
        for (uint256 i = 0; i < quantity; i++) {
            _mintToken(to);
        }
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
    ) internal override(ERC721) returns (address) {
        address from = _ownerOf(tokenId);
        if (
            from != adreess(0) && to != address(0) && !whitelistedAddresses[to]
        ) {
            revert("This token is soulbound and cannot be transferred");
        } else if (from != address(0) && !whitelistedAddresses[from]) {
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
}
