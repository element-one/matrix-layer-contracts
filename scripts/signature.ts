const { ethers } = require('ethers');

// Example private key (use an appropriate one)
// const privateKey =
//   '503f38a9c967ed597e47fe25643985f032b072db8075426a92110f82df48dfcb';
const privateKey =
  '641c13a4e6eee4cb119d971f94dab38beb51c6cfea85f2d4f83846501f017822';

// Signer from the private key
const signer = new ethers.Wallet(privateKey);

// EIP-712 domain
const domain = {
  name: 'MatrixPayment',
  version: '1',
  chainId: 97,
  verifyingContract: '0xf26C9342d58f98B449Ef932D0f51dC7eBF353060',
};

// EIP712 types
const types = {
  Sale: [
    { name: 'buyer', type: 'address' },
    { name: 'totalAmount', type: 'uint256' }, // 10e6
    { name: 'referral', type: 'address' }, // 0x0000000000000000000000000000000000000000 no referral
    { name: 'isWhitelisted', type: 'bool' },
  ],
};

// The data to sign
const value = {
  buyer: '0xe273f8beEb0ca112292c4aC407c35EE604E54cD2',
  totalAmount: '199000000',
  referral: '0xe273f8beEb0ca112292c4aC407c35EE604E54cD2',
  isWhitelisted: true, // is team wallet
};

async function signTypedData() {
  // Generate the signature
  const signature = await signer.signTypedData(domain, types, value);
  console.log('Signature:', signature);
}

signTypedData().catch(console.error);
