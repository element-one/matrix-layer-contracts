import { deployContract } from './utils';

async function main() {
  const [deployer] = await ethers.getSigners();
  const wlpAddress = await deployContract(
    'MatrixLayerProtocolToken',
    [],
    'MatrixLayerProtocolToken'
  );

  console.log(`token deployed to: ${wlpAddress}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
