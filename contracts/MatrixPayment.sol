// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MatrixPayment {
    address public owner;
    IERC20 public usdtToken;
    bool public isPrivateSaleActive;
    bool public isPublicSaleActive;
    bytes32 public whitelistRoot;

    enum DeviceType {
        Phone,
        AiAgentOrigin,
        AiAgentOne,
        AiAgentPro,
        AiAgentUltra
    }

    struct PaymentDetails {
        address from;
        uint256 amount;
        DeviceType deviceType;
        uint256 quantity;
    }

    struct DeviceOrder {
        DeviceType deviceType;
        uint256 quantity;
    }

    event PaymentReceived(
        address from,
        uint256 amount,
        DeviceType deviceType,
        uint256 quantity
    );

    event UsdtTokenAddressSet(address indexed tokenAddress);
    event PrivateSaleToggled(bool isActive);
    event PublicSaleToggled(bool isActive);
    event WhitelistRootUpdated(bytes32 whitelistRoot);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor(address tokenAddress) {
        owner = msg.sender;
        usdtToken = IERC20(tokenAddress);
        emit UsdtTokenAddressSet(tokenAddress);
    }

    function setUsdtTokenAddress(address tokenAddress) public onlyOwner {
        usdtToken = IERC20(tokenAddress);
        emit UsdtTokenAddressSet(tokenAddress);
    }

    function togglePrivateSale() external onlyOwner {
        isPrivateSaleActive = !isPrivateSaleActive;
        emit PrivateSaleToggled(isPrivateSaleActive);
    }

    function togglePublicSale() external onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
        emit PublicSaleToggled(isPublicSaleActive);
    }

    function updateWhitelistRoot(bytes32 _whitelistRoot) external onlyOwner {
        whitelistRoot = _whitelistRoot;
        emit WhitelistRootUpdated(_whitelistRoot);
    }

    function payPrivateSale(
        uint256 totalAmount,
        DeviceOrder[] calldata orders,
        bytes32[] calldata merkleProof
    ) public {
        require(isPrivateSaleActive, "Private sale is not active");
        require(totalAmount > 0, "Total amount must be greater than zero");
        require(orders.length > 0, "Must order at least one device");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(merkleProof, whitelistRoot, leaf),
            "Invalid proof"
        );

        require(
            usdtToken.transferFrom(msg.sender, address(this), totalAmount),
            "Token transfer failed"
        );

        for (uint256 i = 0; i < orders.length; i++) {
            emit PaymentReceived(
                msg.sender,
                0,
                orders[i].deviceType,
                orders[i].quantity
            );
        }
    }

    function payPublicSale(
        uint256 totalAmount,
        DeviceOrder[] calldata orders
    ) public {
        require(isPublicSaleActive, "Public sale is not active");
        require(totalAmount > 0, "Total amount must be greater than zero");
        require(orders.length > 0, "Must order at least one device");

        require(
            usdtToken.transferFrom(msg.sender, address(this), totalAmount),
            "Token transfer failed"
        );

        for (uint256 i = 0; i < orders.length; i++) {
            emit PaymentReceived(
                msg.sender,
                0,
                orders[i].deviceType,
                orders[i].quantity
            );
        }
    }

    function withdrawUsdt(uint256 amount) public onlyOwner {
        require(usdtToken.transfer(owner, amount), "Token withdrawal failed");
    }

    function withdrawETH(uint256 amount) public onlyOwner {
        payable(owner).transfer(amount);
    }

    receive() external payable {}
}
