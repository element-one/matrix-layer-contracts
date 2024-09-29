import { deployContract } from './utils';

async function main() {
  const [deployer] = await ethers.getSigners();
  await deployContract('MatrixNFT', ['Matrix', 'MTX', deployer.address], false);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
