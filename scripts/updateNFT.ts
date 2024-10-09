import { upgradeContract } from './utils';
import { readFileSync } from 'fs';

async function main() {
  // 
  // Read the proxy addresses of all deployed contracts
  const proxyAddresses = {
    MatrixPhone: readFileSync('cache/MatrixPhone', 'utf-8').trim(),
    Matrix: readFileSync('cache/Matrix', 'utf-8').trim(),
    MatrixAiAgentOne: readFileSync('cache/MatrixAiAgentOne', 'utf-8').trim(),
    MatrixAiAgentPro: readFileSync('cache/MatrixAiAgentPro', 'utf-8').trim(),
    MatrixAiAgentUltra: readFileSync('cache/MatrixAiAgentUltra', 'utf-8').trim(),
  };

  // Upgrade all deployed MatrixNFT contracts
  for (const [name, proxyAddress] of Object.entries(proxyAddresses)) {
    console.log(`Upgrading ${name} at proxy address: ${proxyAddress}`);
    await upgradeContract(proxyAddress, 'MatrixNFT');
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});