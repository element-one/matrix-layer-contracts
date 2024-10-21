import { ethers } from 'hardhat';

async function main() {
  const contractAddress = '0xAC8C0063b69586F196D6ee9efB85f09c83905Ba6';
  const contractName = 'MatrixPayment'; // e.g., "MatrixPhone"

  // Define the constructor arguments used to deploy the contract
  const constructorArguments = [
    '0x9e5aac1ba1a2e6aed6b32689dfcf62a509ca96f3',
    [
      '0x65BfCc2edfa865b3BC5082BC824253AF39F41659',
      '0x3021b28c3B545CC29D140a821d30a2C2747dDE96',
      '0xE8240EEf2E6333bF0Ff656BA1eEFF6E1259a2f96',
      '0x59c96117a7D3E828E0A71437bD1C4046243D3636',
      '0xaAf5ff4188BddF14E9c2363d5cbD637C80bA58C6',
    ],
    process.env.SIGNER_ADDRESS,
    process.env.ACCOUNTING_ADDRESS,
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
