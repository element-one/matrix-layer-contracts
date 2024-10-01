// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

interface IMatrixNFT is IERC721 {
    function mint(address to, uint256 quantity) external;
}

contract MatrixPayment is ReentrancyGuard, Ownable, EIP712 {
    using ECDSA for bytes32;

    IERC20 public immutable usdtToken;
    bool public isPrivateSaleActive;
    bool public isPublicSaleActive;

    address public signerAddress;
    address public accountingAddress;

    bytes32 private constant SALE_TYPEHASH =
        keccak256(
            "Sale(address buyer,uint256 totalAmount,address referral,DeviceOrder[] orders)"
        );
    bytes32 private constant DEVICE_ORDER_TYPEHASH =
        keccak256("DeviceOrder(uint8 deviceType,uint256 quantity)");

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
    mapping(address => uint256) public referralRewards;

    // Immutable device prices (in USDT)
    uint256 public constant PHONE_PRICE = 699 * 10 ** 6; // 699 USDT
    uint256 public constant MATRIX_PRICE = 199 * 10 ** 6; // 199 USDT
    uint256 public constant AI_AGENT_ONE_PRICE = 699 * 10 ** 6; // 699 USDT
    uint256 public constant AI_AGENT_PRO_PRICE = 1299 * 10 ** 6; // 1299 USDT
    uint256 public constant AI_AGENT_ULTRA_PRICE = 899 * 10 ** 6; // 899 USDT

    event PaymentReceived(PaymentData paymentData);
    event PrivateSaleStateChanged(bool isActive);
    event PublicSaleStateChanged(bool isActive);
    event SignerAddressUpdated(address newSigner);
    event NftContractAddressSet(DeviceType deviceType, address contractAddress);
    event AccountingAddressUpdated(address newAccountingAddress);
    event ReferralRewardAdded(address referral, uint256 amount);
    event ReferralRewardClaimed(address referral, uint256 amount);

    constructor(
        address _usdtToken,
        address[] memory _nftContracts,
        address _signerAddress,
        address _accountingAddress
    ) EIP712("MatrixPayment", "1") Ownable(msg.sender) {
        require(
            _nftContracts.length == 5,
            "Must provide 5 NFT contract addresses"
        );
        usdtToken = IERC20(_usdtToken);

        for (uint256 i = 0; i < _nftContracts.length; i++) {
            nftContracts[DeviceType(i)] = _nftContracts[i];
            emit NftContractAddressSet(DeviceType(i), _nftContracts[i]);
        }

        signerAddress = _signerAddress;
        emit SignerAddressUpdated(_signerAddress);

        accountingAddress = _accountingAddress;
        emit AccountingAddressUpdated(_accountingAddress);
    }

    function setPrivateSaleActive(bool _isActive) external onlyOwner {
        isPrivateSaleActive = _isActive;
        emit PrivateSaleStateChanged(_isActive);
    }

    function setPublicSaleActive(bool _isActive) external onlyOwner {
        isPublicSaleActive = _isActive;
        emit PublicSaleStateChanged(_isActive);
    }

    function setSignerAddress(address _signerAddress) external onlyOwner {
        signerAddress = _signerAddress;
        emit SignerAddressUpdated(_signerAddress);
    }

    function setAccountingAddress(
        address _accountingAddress
    ) external onlyOwner {
        accountingAddress = _accountingAddress;
        emit AccountingAddressUpdated(_accountingAddress);
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

    function verifySignature(
        address buyer,
        uint256 totalAmount,
        address referral,
        bytes memory signature
    ) internal view {
        bytes32 structHash = keccak256(
            abi.encode(SALE_TYPEHASH, buyer, totalAmount, referral)
        );
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = hash.recover(signature);
        require(signer == signerAddress, "Invalid signature");
    }

    function getDomainSeparator() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    function processPayment(uint256 totalAmount, address referral) internal {
        uint256 amountToAccounting = totalAmount;
        if (referral != address(0)) {
            amountToAccounting = (totalAmount * 90) / 100;
            uint256 amountToReferral = totalAmount - amountToAccounting;
            referralRewards[referral] += amountToReferral;

            emit ReferralRewardAdded(referral, amountToReferral);
        }

        require(
            usdtToken.transfer(accountingAddress, amountToAccounting),
            "Token transfer to accounting address failed"
        );
    }

    function getDevicePrice(
        DeviceType deviceType
    ) public pure returns (uint256) {
        if (deviceType == DeviceType.Phone) return PHONE_PRICE;
        if (deviceType == DeviceType.Matrix) return MATRIX_PRICE;
        if (deviceType == DeviceType.AiAgentOne) return AI_AGENT_ONE_PRICE;
        if (deviceType == DeviceType.AiAgentPro) return AI_AGENT_PRO_PRICE;
        if (deviceType == DeviceType.AiAgentUltra) return AI_AGENT_ULTRA_PRICE;
        revert("Invalid device type");
    }

    function calculateTotalAmount(
        DeviceOrder[] memory orders
    ) internal pure returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < orders.length; i++) {
            total += getDevicePrice(orders[i].deviceType) * orders[i].quantity;
        }
        return total;
    }

    function payPrivateSale(
        uint256 totalAmount,
        DeviceOrder[] calldata orders,
        address referral,
        bytes memory signature
    ) public nonReentrant {
        require(isPrivateSaleActive, "Private sale is not active");
        require(totalAmount > 0, "Total amount must be greater than zero");
        require(orders.length > 0, "Must order at least one device");

        uint256 calculatedTotal = calculateTotalAmount(orders);
        require(
            calculatedTotal == totalAmount,
            "Total amount does not match order prices"
        );

        verifySignature(msg.sender, totalAmount, referral, signature);

        require(
            usdtToken.transferFrom(msg.sender, address(this), totalAmount),
            "Token transfer failed"
        );

        processPayment(totalAmount, referral);

        for (uint256 i = 0; i < orders.length; i++) {
            address nftContract = nftContracts[orders[i].deviceType];
            require(
                nftContract != address(0),
                "NFT contract not set for device type"
            );

            IMatrixNFT(nftContract).mint(msg.sender, orders[i].quantity);
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
        DeviceOrder[] calldata orders,
        address referral,
        bytes memory signature
    ) public nonReentrant {
        require(isPublicSaleActive, "Public sale is not active");
        require(totalAmount > 0, "Total amount must be greater than zero");
        require(orders.length > 0, "Must order at least one device");

        uint256 calculatedTotal = calculateTotalAmount(orders);
        require(
            calculatedTotal == totalAmount,
            "Total amount does not match order prices"
        );

        verifySignature(msg.sender, totalAmount, referral, signature);

        require(
            usdtToken.transferFrom(msg.sender, address(this), totalAmount),
            "Token transfer failed"
        );

        processPayment(totalAmount, referral);

        for (uint256 i = 0; i < orders.length; i++) {
            address nftContract = nftContracts[orders[i].deviceType];
            require(
                nftContract != address(0),
                "NFT contract not set for device type"
            );

            IMatrixNFT(nftContract).mint(msg.sender, orders[i].quantity);
        }

        PaymentData memory paymentData = PaymentData({
            buyer: msg.sender,
            orders: orders,
            totalAmount: totalAmount
        });

        emit PaymentReceived(paymentData);
    }

    function claimReferralReward() external nonReentrant {
        uint256 reward = referralRewards[msg.sender];
        require(reward > 0, "No rewards to claim");

        referralRewards[msg.sender] = 0;
        require(
            usdtToken.transfer(msg.sender, reward),
            "Token transfer failed"
        );

        emit ReferralRewardClaimed(msg.sender, reward);
    }

    function getReferralRewards(
        address referrer
    ) public view returns (uint256) {
        return referralRewards[referrer];
    }

    function withdrawUsdt(uint256 amount) public onlyOwner {
        require(usdtToken.transfer(owner(), amount), "Token withdrawal failed");
    }

    function withdrawETH(uint256 amount) public onlyOwner {
        payable(owner()).transfer(amount);
    }

    receive() external payable {}
}
