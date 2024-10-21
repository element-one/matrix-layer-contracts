import { ethers } from 'hardhat';

async function main() {
  const contractAddress = '0xe8240eef2e6333bf0ff656ba1eeff6e1259a2f96';
  const contractName = 'MatrixNFT'; // e.g., "MatrixPhone"

  // Define the constructor arguments used to deploy the contract
  const constructorArguments = [
    'AI Agent One',
    'AAO',
    '0x39A3cc8Da350b3c6B436Cb47FeAEE8aae54ACD28',
  ];

  console.log('Verifying contract...');
  try {
    await hre.run('verify:verify', {
      address: contractAddress,
      contract: `contracts/${contractName}.sol:${contractName}`,
      constructorArguments: constructorArguments,
    });
    console.log('Contract verified successfully');
  } catch (error) {
    console.error('Verification failed:', error);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error: Error) => {
    console.error(error);
    process.exit(1);
  });
