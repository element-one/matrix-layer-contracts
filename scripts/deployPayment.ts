import { readFileSync } from 'fs';
import { deployContract } from './utils';

async function main() {
  await deployContract('MockUSDT')
  const tokenAddress = readFileSync('cache/MockUSDT', 'utf-8');
  const MatrixPhoneAddress = readFileSync('cache/MatrixPhone', 'utf-8');
  const MatrixAddress = readFileSync('cache/Matrix', 'utf-8');
  const MatrixAiAgentOneAddress = readFileSync(
    'cache/MatrixAiAgentOne',
    'utf-8'
  );
  const MatrixAiAgentProAddress = readFileSync(
    'cache/MatrixAiAgentPro',
    'utf-8'
  );
  const MatrixAiAgentUltraAddress = readFileSync(
    'cache/MatrixAiAgentUltra',
    'utf-8'
  );

  await deployContract('MatrixPayment', [
    tokenAddress,
    [MatrixPhoneAddress, MatrixAddress, MatrixAiAgentOneAddress, MatrixAiAgentProAddress, MatrixAiAgentUltraAddress],
    process.env.SIGNER_ADDRESS,
    process.env.ACCOUNTING_ADDRESS
  ])
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
