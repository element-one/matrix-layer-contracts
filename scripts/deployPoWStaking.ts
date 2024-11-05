import { readFileSync } from 'fs';
import { deployContract } from './utils';

async function main() {
  const wlpAddress = process.env.MLP_TOKEN_ADDRESS;
  const MatrixPhoneAddress = process.env.MATRIX_PHONE_ADDRESS;
  const MatrixAddress = process.env.MATRIX_MATRIX_ADDRESS;
  const MatrixAiAgentOneAddress = process.env.MATRIX_AI_AGENT_ONE_ADDRESS;
  const MatrixAiAgentProAddress = process.env.MATRIX_AI_AGENT_PRO_ADDRESS;
  const MatrixAiAgentUltraAddress = process.env.MATRIX_AI_AGENT_ULTRA_ADDRESS;

  await deployContract('MatrixPoWStaking', [
    wlpAddress,
    process.env.SIGNER_ADDRESS,
    process.env.MLP_OWNER_ADDRESS,
    [
      MatrixPhoneAddress,
      MatrixAddress,
      MatrixAiAgentOneAddress,
      MatrixAiAgentProAddress,
      MatrixAiAgentUltraAddress,
    ],
  ]);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
