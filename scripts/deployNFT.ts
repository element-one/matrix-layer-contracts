import { deployContract } from './utils';

async function main() {
  const [deployer] = await ethers.getSigners();
  const matrixPhoneAddress = await deployContract(
    'MatrixNFT',
    ['Phone', 'Phone', deployer.address],
    'MatrixPhone'
  );
  const matrixAddress = await deployContract(
    'MatrixNFT',
    ['Matrix', 'MTX', deployer.address],
    'Matrix'
  );
  const matrixAiAgentOneAddress = await deployContract(
    'MatrixNFT',
    ['AI Agent One', 'AAO', deployer.address],
    'MatrixAiAgentOne'
  );
  const matrixAiAgentProAddress = await deployContract(
    'MatrixNFT',
    ['AI Agent Pro', 'AAP', deployer.address],
    'MatrixAiAgentPro'
  );
  const matrixAiAgentUltraAddress = await deployContract(
    'MatrixNFT',
    ['AI Agent Ultra', 'AAU', deployer.address],
    'MatrixAiAgentUltra'
  );

  console.log(`
    MATRIX_ADDRESS=${matrixAddress}
    MATRIX_PHONE_ADDRESS=${matrixPhoneAddress}
    MATRIX_AI_AGENT_ONE_ADDRESS=${matrixAiAgentOneAddress}
    MATRIX_AI_AGENT_PRO_ADDRESS=${matrixAiAgentProAddress}
    MATRIX_AI_AGENT_ULTRA_ADDRESS=${matrixAiAgentUltraAddress}
    
    - Matrix: ${matrixAddress}
    - MatrixPhone: ${matrixPhoneAddress}
    - MatrixAiAgentOne: ${matrixAiAgentOneAddress}
    - MatrixAiAgentPro: ${matrixAiAgentProAddress}
    - MatrixAiAgentUltra: ${matrixAiAgentUltraAddress}
    `);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
