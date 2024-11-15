# matrix-contracts

- MockUSDT: 0x71a46a9d630fC43DE8EA2302b2490ee2F969aDEd
- MatrixPayment: 0x28e719a4212f03f8cd95c87607c997E5594a9BDd
- Matrix: 0x2d42584cc4409C656F7298634150233695d2011d
- MatrixPhone: 0xEC0165627093276F8CC58be9c668a6Dca36a75BA
- MatrixAiAgentOne: 0xb9206f335Ec58AF0385EdeDF4B95365910D570C8
- MatrixAiAgentPro: 0x7B44294E963191D9fD0D86A89489c85144002fe6
- MatrixAiAgentUltra: 0x33762F9188206d720C1ddC09C770a6da2E52964f

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
