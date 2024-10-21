import { ethers, upgrades } from 'hardhat';

async function main() {
  try {
    const [deployer] = await ethers.getSigners();
    console.log('Deploying MatrixMint with account:', deployer.address);

    const MatrixMint = await ethers.getContractFactory('MatrixMint');
    console.log('Contract factory created');

    console.log('Deploying proxy...');
    const matrixMint = await upgrades.deployProxy(
      MatrixMint,
      [
        'MatrixMint', // name
        'MTX', // symbol
        deployer.address, // initialOwner
      ],
      {
        initializer: 'initialize',
      }
    );

    console.log('Waiting for deployment...');
    await matrixMint.deployed();

    console.log('MatrixMint deployed to:', matrixMint.address);

    console.log('Getting implementation address...');
    const implementationAddress =
      await upgrades.erc1967.getImplementationAddress(matrixMint.address);
    console.log('Implementation contract address:', implementationAddress);

    console.log('Verifying implementation contract on Etherscan...');
    try {
      await run('verify:verify', {
        address: implementationAddress,
      });
      console.log('Implementation contract verified successfully');
    } catch (error) {
      console.error('Verification failed:', error);
    }
  } catch (error) {
    console.error('Deployment failed:', error);
    if (error instanceof Error) {
      console.error(error.message);
      console.error(error.stack);
    }
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
