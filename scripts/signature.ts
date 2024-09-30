const { ethers } = require('ethers');

// Example private key (use an appropriate one)
const privateKey =
  '641c13a4e6eee4cb119d971f94dab38beb51c6cfea85f2d4f83846501f017822';

// Signer from the private key
const signer = new ethers.Wallet(privateKey);

// EIP-712 domain
const domain = {
  name: 'MatrixPayment',
  version: '1',
  chainId: 97,
  verifyingContract: '0x2E3bE631883802FeD0D36690a74a4a234122a830',
};

// EIP712 types
const types = {
  Sale: [
    { name: 'buyer', type: 'address' },
    { name: 'totalAmount', type: 'uint256' },
    { name: 'referral', type: 'address' },
  ],
};

// The data to sign
const value = {
  buyer: '0xe273f8beEb0ca112292c4aC407c35EE604E54cD2',
  totalAmount: '600000000',
  referral: '0x9A7e139fA1292a4E83BCA8d39AFe4cB5dC343D6D',
};

async function signTypedData() {
  // Generate the signature
  const signature = await signer.signTypedData(domain, types, value);
  console.log('Signature:', signature);
}

signTypedData().catch(console.error);
