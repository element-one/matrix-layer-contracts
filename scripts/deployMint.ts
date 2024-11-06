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
        txOverrides: { gasLimit: 6000000 },
      }
    );

    console.log('Waiting for deployment...');
    await matrixMint.waitForDeployment();

    const matrixMintAddress = await matrixMint.getAddress();
    console.log('MatrixMint deployed to:', matrixMintAddress);

    console.log('Getting implementation address...');
    const implementationAddress =
      await upgrades.erc1967.getImplementationAddress(matrixMintAddress);
    console.log('Implementation contract address:', implementationAddress);

    console.log('Verifying implementation contract on Etherscan...');
    try {
      await hre.run('verify:verify', {
        address: implementationAddress,
        contract: `contracts/MatrixMint.sol:MatrixMint`,
        constructorArguments: ['MatrixMint', 'MTX', deployer.address],
      });
      console.log('Implementation contract verified successfully');
    } catch (error) {
      console.error('Verification failed:', error);
    }
  } catch (error) {
    console.error('Deployment failed:', error);
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
