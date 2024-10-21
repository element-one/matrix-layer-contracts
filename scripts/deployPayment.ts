import { readFileSync } from 'fs';
import { deployContract } from './utils';

async function main() {
  // await deployContract('MockUSDT')
  // const tokenAddress = readFileSync('cache/MockUSDT', 'utf-8');
  // const MatrixPhoneAddress = readFileSync('cache/MatrixPhone', 'utf-8');
  // const MatrixAddress = readFileSync('cache/Matrix', 'utf-8');
  // const MatrixAiAgentOneAddress = readFileSync(
  //   'cache/MatrixAiAgentOne',
  //   'utf-8'
  // );
  // const MatrixAiAgentProAddress = readFileSync(
  //   'cache/MatrixAiAgentPro',
  //   'utf-8'
  // );
  // const MatrixAiAgentUltraAddress = readFileSync(
  //   'cache/MatrixAiAgentUltra',
  //   'utf-8'
  // );

  // console.log(
  //   tokenAddress,
  //   MatrixPhoneAddress,
  //   MatrixAddress,
  //   MatrixAiAgentOneAddress,
  //   MatrixAiAgentProAddress,
  //   MatrixAiAgentUltraAddress
  // );

  //   0x9e5aac1ba1a2e6aed6b32689dfcf62a509ca96f3
  //  0x65BfCc2edfa865b3BC5082BC824253AF39F41659
  //  0x3021b28c3B545CC29D140a821d30a2C2747dDE96
  //  0xE8240EEf2E6333bF0Ff656BA1eEFF6E1259a2f96
  //  0x59c96117a7D3E828E0A71437bD1C4046243D3636
  //  0xaAf5ff4188BddF14E9c2363d5cbD637C80bA58C6
  await deployContract('MatrixPayment', [
    '0x55d398326f99059fF775485246999027B3197955',
    [
      '0x65BfCc2edfa865b3BC5082BC824253AF39F41659',
      '0x3021b28c3B545CC29D140a821d30a2C2747dDE96',
      '0xE8240EEf2E6333bF0Ff656BA1eEFF6E1259a2f96',
      '0x59c96117a7D3E828E0A71437bD1C4046243D3636',
      '0xaAf5ff4188BddF14E9c2363d5cbD637C80bA58C6',
    ],
    process.env.SIGNER_ADDRESS,
    process.env.ACCOUNTING_ADDRESS,
  ]);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
