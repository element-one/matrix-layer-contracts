import { expect } from 'chai';
import { readFileSync } from 'fs';
import hre from 'hardhat';

describe('POW', function () {
  it('Should deploy the contract', async function () {
    const wlpAddress = await hre.ethers.deployContract(
      'MatrixLayerProtocolToken',
      []
    );
    const MatrixPhoneAddress = '0xC886CB469C20c9D7f43440ba33F89aD772412b47';
    const MatrixAddress = '0xEF944DFaE77F8CcA948ae0202737a610e0EA7478';
    const MatrixAiAgentOneAddress =
      '0x0B76B7243cdC729695CD4cD36aBA3937516E9Cf3';
    const MatrixAiAgentProAddress =
      '0x40E694853044C8cF40Cb7Cd2D952d609090d801e';
    const MatrixAiAgentUltraAddress =
      '0x1a2e32e9d39AFBd2Ca93385f220248ffca5bC569';

    await hre.ethers.deployContract('MatrixPoWStaking', [
      wlpAddress,
      process.env.SIGNER_ADDRESS,
      [
        MatrixPhoneAddress,
        MatrixAddress,
        MatrixAiAgentOneAddress,
        MatrixAiAgentProAddress,
        MatrixAiAgentUltraAddress,
      ],
    ]);
  });
});
