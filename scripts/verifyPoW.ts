import { ethers } from 'hardhat';

async function main() {
  const contractAddress = '0x3548939B235FEF39727607D1538b74945842347C';
  const contractName = 'MatrixPoWStaking'; // e.g., "MatrixPhone"

  // Define the constructor arguments used to deploy the contract
  const constructorArguments = [
    process.env.MLP_TOKEN_ADDRESS,
    process.env.SIGNER_ADDRESS,
    [
      '0x65BfCc2edfa865b3BC5082BC824253AF39F41659',
      '0x018A02Bb36dE21e5644342bd26d8c31a5631326e',
      '0xE8240EEf2E6333bF0Ff656BA1eEFF6E1259a2f96',
      '0x59c96117a7D3E828E0A71437bD1C4046243D3636',
      '0xaAf5ff4188BddF14E9c2363d5cbD637C80bA58C6',
    ],
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
