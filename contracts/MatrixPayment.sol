// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract MatrixPayment is ReentrancyGuard, Ownable {
    IERC20 public usdtToken;
    bool public isPrivateSaleActive;
    bool public isPublicSaleActive;

    bytes32 public whitelistRoot;

    enum DeviceType {
        Phone,
        Matrix,
        AiAgentOne,
        AiAgentPro,
        AiAgentUltra
    }

    struct DeviceOrder {
        DeviceType deviceType;
        uint256 quantity;
    }

    struct PaymentData {
        address buyer;
        DeviceOrder[] orders;
        uint256 totalAmount;
    }

    mapping(DeviceType => address) public nftContracts;

    event PaymentReceived(PaymentData paymentData);
    event UsdtTokenAddressSet(address tokenAddress);
    event PrivateSaleStateChanged(bool isActive);
    event PublicSaleStateChanged(bool isActive);
    event WhitelistRootUpdated(bytes32 newRoot);
    event NftContractAddressSet(DeviceType deviceType, address contractAddress);

    constructor(
        address tokenAddress,
        address[] memory nftAddresses
    ) Ownable(msg.sender) {
        require(
            nftAddresses.length == 5,
            "Must provide 5 NFT contract addresses"
        );
        usdtToken = IERC20(tokenAddress);
        emit UsdtTokenAddressSet(tokenAddress);

        for (uint256 i = 0; i < nftAddresses.length; i++) {
            nftContracts[DeviceType(i)] = nftAddresses[i];
            emit NftContractAddressSet(DeviceType(i), nftAddresses[i]);
        }
    }

    function setUsdtTokenAddress(address tokenAddress) external onlyOwner {
        usdtToken = IERC20(tokenAddress);
        emit UsdtTokenAddressSet(tokenAddress);
    }

    function setPrivateSaleActive(bool _isActive) external onlyOwner {
        isPrivateSaleActive = _isActive;
        emit PrivateSaleStateChanged(_isActive);
    }

    function setPublicSaleActive(bool _isActive) external onlyOwner {
        isPublicSaleActive = _isActive;
        emit PublicSaleStateChanged(_isActive);
    }

    function setWhitelistRoot(bytes32 _whitelistRoot) external onlyOwner {
        whitelistRoot = _whitelistRoot;
        emit WhitelistRootUpdated(_whitelistRoot);
    }

    function setNftContractAddresses(
        address[] calldata nftAddresses
    ) external onlyOwner {
        require(
            nftAddresses.length == 5,
            "Must provide 5 NFT contract addresses"
        );
        for (uint256 i = 0; i < nftAddresses.length; i++) {
            nftContracts[DeviceType(i)] = nftAddresses[i];
            emit NftContractAddressSet(DeviceType(i), nftAddresses[i]);
        }
    }

    function getNftContractAddress(
        DeviceType deviceType
    ) external view returns (address) {
        return nftContracts[deviceType];
    }

    function payPrivateSale(
        uint256 totalAmount,
        DeviceOrder[] calldata orders,
        bytes32[] calldata proof
    ) public nonReentrant {
        require(isPrivateSaleActive, "Private sale is not active");
        require(totalAmount > 0, "Total amount must be greater than zero");
        require(orders.length > 0, "Must order at least one device");
        require(
            MerkleProof.verify(
                proof,
                whitelistRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Invalid whitelist proof"
        );

        require(
            usdtToken.transferFrom(msg.sender, address(this), totalAmount),
            "Token transfer failed"
        );

        for (uint256 i = 0; i < orders.length; i++) {
            address nftContract = nftContracts[orders[i].deviceType];
            require(
                nftContract != address(0),
                "NFT contract not set for device type"
            );

            for (uint256 j = 0; j < orders[i].quantity; j++) {
                IERC721(nftContract).safeTransferFrom(
                    address(this),
                    msg.sender,
                    j
                );
            }
        }

        PaymentData memory paymentData = PaymentData({
            buyer: msg.sender,
            orders: orders,
            totalAmount: totalAmount
        });

        emit PaymentReceived(paymentData);
    }

    function payPublicSale(
        uint256 totalAmount,
        DeviceOrder[] calldata orders
    ) public nonReentrant {
        require(isPublicSaleActive, "Public sale is not active");
        require(totalAmount > 0, "Total amount must be greater than zero");
        require(orders.length > 0, "Must order at least one device");

        require(
            usdtToken.transferFrom(msg.sender, address(this), totalAmount),
            "Token transfer failed"
        );

        for (uint256 i = 0; i < orders.length; i++) {
            address nftContract = nftContracts[orders[i].deviceType];
            require(
                nftContract != address(0),
                "NFT contract not set for device type"
            );

            for (uint256 j = 0; j < orders[i].quantity; j++) {
                IERC721(nftContract).safeTransferFrom(
                    address(this),
                    msg.sender,
                    j
                );
            }
        }

        PaymentData memory paymentData = PaymentData({
            buyer: msg.sender,
            orders: orders,
            totalAmount: totalAmount
        });

        emit PaymentReceived(paymentData);
    }

    function withdrawUsdt(uint256 amount) public onlyOwner {
        require(usdtToken.transfer(owner(), amount), "Token withdrawal failed");
    }

    function withdrawETH(uint256 amount) public onlyOwner {
        payable(owner()).transfer(amount);
    }

    receive() external payable {}
}
