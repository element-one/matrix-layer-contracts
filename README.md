# matrix-contracts

- MockUSDT: 0xa2b85544f0F0722C47576E08c3766a66AfF7378e
- MatrixPayment: 0x45915a87d9c79318AF4a936E2a656891fc334Bce
- Matrix: 0xEF944DFaE77F8CcA948ae0202737a610e0EA7478
- MatrixPhone: 0xC886CB469C20c9D7f43440ba33F89aD772412b47
- MatrixAiAgentOne: 0x0B76B7243cdC729695CD4cD36aBA3937516E9Cf3
- MatrixAiAgentPro: 0x40E694853044C8cF40Cb7Cd2D952d609090d801e
- MatrixAiAgentUltra: 0x1a2e32e9d39AFBd2Ca93385f220248ffca5bC569


## MatrixMint NFT Contract Guide

MatrixMint is an upgradeable ERC721 token contract with additional features like whitelist minting and public minting. This guide explains how to interact with the contract and upgrade it.

### Interacting with MatrixMint NFT

#### Initialization

The contract is initialized with the following parameters:

- `name`: The name of the NFT collection
- `symbol`: The symbol of the NFT collection
- `initialOwner`: The address that will be set as the initial owner of the contract

#### Main Functions

1. **mint**

   - Description: Mints new tokens to a specified address
   - Parameters:
     - `to`: Address to receive the minted tokens
     - `quantity`: Number of tokens to mint
   - Authority: Only the owner or approved operators can call this function

2. **whitelistMint**

   - Description: Allows whitelisted addresses to mint tokens
   - Parameters:
     - `to`: Address to receive the minted tokens
     - `quantity`: Number of tokens to mint
     - `proof`: Merkle proof to verify the address is whitelisted
   - Authority: Any whitelisted address can call this function when whitelist minting is active

3. **setWhitelistRoot**

   - Description: Sets the Merkle root for the whitelist
   - Parameters:
     - `_whitelistRoot`: New Merkle root
   - Authority: Only the owner can call this function

4. **setWhitelistStatus**

   - Description: Activates or deactivates whitelist minting
   - Parameters:
     - `_isActive`: Boolean to set the whitelist status
   - Authority: Only the owner can call this function

5. **setPublicMintStatus**

   - Description: Activates or deactivates public minting
   - Parameters:
     - `_isActive`: Boolean to set the public mint status
   - Authority: Only the owner can call this function

6. **setMaxMintLimits**

   - Description: Sets the maximum minting limits
   - Parameters:
     - `_perTransaction`: Maximum number of tokens that can be minted in a single transaction
     - `_perWallet`: Maximum number of tokens that can be minted per wallet
   - Authority: Only the owner can call this function

7. **setOperator**

   - Description: Adds or removes an operator
   - Parameters:
     - `_operator`: Address of the operator
     - `_status`: Boolean to set the operator status
   - Authority: Only the owner can call this function

8. **setBaseTokenURI**

   - Description: Sets the base URI for token metadata
   - Parameters:
     - `_baseTokenURI`: New base URI
   - Authority: Only the owner can call this function

9. **tokensOwned**
   - Description: Retrieves all token IDs owned by a specific address
   - Parameters:
     - `owner`: Address to check for token ownership
   - Authority: Anyone can call this function

### Upgrading the NFT Contract

MatrixMint is an upgradeable contract using the UUPS (Universal Upgradeable Proxy Standard) pattern. To upgrade the contract:

1. Deploy a new implementation of the MatrixMint contract.
2. Call the `upgradeTo` or `upgradeToAndCall` function on the proxy contract, passing the address of the new implementation.

Only the owner of the contract can initiate an upgrade. The `_authorizeUpgrade` function in the contract ensures that only the owner can perform upgrades.

### Important Notes

- The NFTs minted by this contract are soulbound, meaning they cannot be transferred once minted.
- The contract includes both whitelist and public minting functionalities, which can be activated or deactivated by the owner.
- Operators can be assigned by the owner to assist with minting operations.
- The contract uses a Merkle tree for efficient whitelist verification.

Always ensure you're interacting with the correct contract address and have the necessary permissions before calling any functions.

## MatrixNFT Contract

MatrixNFT is a non-upgradeable ERC721 contract with soulbound functionality. Here's how to interact with its main functions:

**MatrixNFT is call by the MatrixPayment contract, meaning that MatrixPayment contract need to be deployed first and set as operator to each of those NFT contracts.**

1. **mint**

   - Description: Mints new tokens
   - Parameters:
     - `to`: Address to receive the minted tokens
     - `quantity`: Number of tokens to mint
   - Authority: Only the owner or an approved operator can call this function

2. **setOperator**

   - Description: Adds or removes an operator
   - Parameters:
     - `_operator`: Address of the operator
     - `_status`: Boolean to set the operator status
   - Authority: Only the owner can call this function

3. **setBaseTokenURI**

   - Description: Sets the base URI for token metadata
   - Parameters:
     - `_baseTokenURI`: New base URI
   - Authority: Only the owner can call this function

4. **tokensOwned**
   - Description: Retrieves all token IDs owned by a specific address
   - Parameters:
     - `owner`: Address to check for token ownership
   - Authority: Anyone can call this function

### Important Notes

- The NFTs minted by this contract are soulbound, meaning they cannot be transferred once minted.
- Unlike MatrixMint, this contract does not include whitelist or public minting functionalities.
- Operators can be assigned by the owner to assist with minting operations.
- This contract is not upgradeable, so any changes would require deploying a new contract.

Always ensure you're interacting with the correct contract address and have the necessary permissions before calling any functions.

## MatrixPayment Contract Guide

MatrixPayment is a contract that handles payments for device purchases, manages referral rewards, and interacts with NFT contracts for minting. Here's how to interact with its main functions:

### Initialization

The contract is initialized with the following parameters:

- `_usdtToken`: Address of the USDT token contract
- `_nftContracts`: Array of 5 NFT contract addresses for each device type
- `_signerAddress`: Address authorized to sign sale messages
- `_accountingAddress`: Address to receive accounting payments

### Main Functions

1. **payPrivateSale** and **payPublicSale**

   - Description: Processes a sale payment, including referral rewards and NFT minting
   - Parameters:
     - `totalAmount`: Total amount of the purchase in USDT
     - `orders`: Array of DeviceOrder structs (deviceType and quantity)
     - `directReferral`: Address of the direct referrer
     - `directPercentage`: Percentage for direct referral reward
     - `levelReferrals`: Array of 5 addresses for level referrals
     - `levelPercentages`: Array of 5 percentages for level referral rewards
     - `isWhitelisted`: Boolean indicating if the buyer is whitelisted
     - `signature`: Signature to verify the sale
   - Authority: Anyone can call these functions when the respective sale is active

2. **claimReferralReward**

   - Description: Allows a user to claim their accumulated referral rewards
   - Authority: Anyone with accumulated rewards can call this function

3. **setPrivateSaleActive** and **setPublicSaleActive**

   - Description: Activates or deactivates the private or public sale
   - Parameters:
     - `_isActive`: Boolean to set the sale status
   - Authority: Only the owner can call these functions

4. **setSignerAddress**

   - Description: Updates the address authorized to sign sale messages
   - Parameters:
     - `_signerAddress`: New signer address
   - Authority: Only the owner can call this function

5. **setAccountingAddress**

   - Description: Updates the address to receive accounting payments
   - Parameters:
     - `_accountingAddress`: New accounting address
   - Authority: Only the owner can call this function

6. **setNftContractAddresses**

   - Description: Updates the NFT contract addresses for each device type
   - Parameters:
     - `nftAddresses`: Array of 5 new NFT contract addresses
   - Authority: Only the owner can call this function

7. **withdrawUsdt** and **withdrawETH**
   - Description: Allows the owner to withdraw USDT or ETH from the contract
   - Parameters:
     - `amount`: Amount to withdraw
   - Authority: Only the owner can call these functions

### View Functions

1. **getNftContractAddress**

   - Description: Returns the NFT contract address for a given device type
   - Parameters:
     - `deviceType`: Enum value representing the device type

2. **getDevicePrice**

   - Description: Returns the price of a device based on its type
   - Parameters:
     - `deviceType`: Enum value representing the device type

3. **getReferralRewards**
   - Description: Returns the accumulated referral rewards for a given address
   - Parameters:
     - `referrer`: Address to check for rewards

### Important Notes

- The contract uses EIP-712 for signature verification of sales.
- Referral rewards are stored in the contract and can be claimed by referrers.
- The contract interacts with multiple NFT contracts, one for each device type.
- Both private and public sales can be activated or deactivated by the owner.
- The contract handles payments in USDT.

Always ensure you're interacting with the correct contract address and have the necessary permissions before calling any functions.
