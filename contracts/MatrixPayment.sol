// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MatrixPayment is ReentrancyGuard, EIP712, Ownable {
    using ECDSA for bytes32;

    IERC20 public usdtToken;
    bool public isPrivateSaleActive;
    bool public isPublicSaleActive;

    address public orderSigner;
    mapping(uint256 => bool) public usedOrderIds;

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

    bytes32 private constant ORDER_TYPEHASH =
        keccak256("Order(uint256 orderId,address user,uint256 totalAmount)");

    event PaymentReceived(
        address indexed user,
        uint256 indexed orderId,
        DeviceType deviceType,
        uint256 quantity,
        uint256 amount
    );
    event UsdtTokenAddressSet(address tokenAddress);
    event PrivateSaleStateChanged(bool isActive);
    event PublicSaleStateChanged(bool isActive);

    constructor(
        address tokenAddress,
        address _orderSigner
    ) EIP712("MatrixPayment", "1") Ownable(msg.sender) {
        usdtToken = IERC20(tokenAddress);
        orderSigner = _orderSigner;
        emit UsdtTokenAddressSet(tokenAddress);
    }

    function setOrderSigner(address _orderSigner) external onlyOwner {
        orderSigner = _orderSigner;
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

    function verifyOrderSignature(
        uint256 orderId,
        uint256 totalAmount,
        bytes memory signature
    ) internal view {
        bytes32 structHash = keccak256(
            abi.encode(ORDER_TYPEHASH, orderId, msg.sender, totalAmount)
        );
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = hash.recover(signature);
        require(signer == orderSigner, "Invalid signature");
    }

    function payPrivateSale(
        uint256 orderId,
        uint256 totalAmount,
        DeviceOrder[] calldata orders,
        bytes memory signature
    ) public nonReentrant {
        require(isPrivateSaleActive, "Private sale is not active");
        require(totalAmount > 0, "Total amount must be greater than zero");
        require(orders.length > 0, "Must order at least one device");
        require(!usedOrderIds[orderId], "Order ID already used");

        verifyOrderSignature(orderId, totalAmount, signature);

        require(
            usdtToken.transferFrom(msg.sender, address(this), totalAmount),
            "Token transfer failed"
        );

        usedOrderIds[orderId] = true;

        emit PaymentReceived(msg.sender, orderId, orders, totalAmount);
    }

    function payPublicSale(
        uint256 orderId,
        uint256 totalAmount,
        DeviceOrder[] calldata orders,
        bytes memory signature
    ) public nonReentrant {
        require(isPublicSaleActive, "Public sale is not active");
        require(totalAmount > 0, "Total amount must be greater than zero");
        require(orders.length > 0, "Must order at least one device");
        require(!usedOrderIds[orderId], "Order ID already used");

        verifyOrderSignature(orderId, totalAmount, signature);

        require(
            usdtToken.transferFrom(msg.sender, address(this), totalAmount),
            "Token transfer failed"
        );

        usedOrderIds[orderId] = true;

        emit PaymentReceived(msg.sender, orderId, orders, totalAmount);
    }

    function withdrawUsdt(uint256 amount) public onlyOwner {
        require(usdtToken.transfer(owner, amount), "Token withdrawal failed");
    }

    function withdrawETH(uint256 amount) public onlyOwner {
        payable(owner).transfer(amount);
    }

    receive() external payable {}
}
