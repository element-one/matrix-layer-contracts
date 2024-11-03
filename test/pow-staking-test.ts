import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Contract } from 'ethers';
import { SignerWithAddress } from '@nomicfoundation/hardhat-ethers/signers';

describe('PoW Staking', function () {
  let powStaking: any;
  let mlpToken: any;
  let phoneNFT: any;
  let matrixNFT: any;
  let aiAgentOneNFT: any;
  let aiAgentProNFT: any;
  let aiAgentUltraNFT: any;
  let owner: SignerWithAddress;
  let user: SignerWithAddress;

  beforeEach(async function () {
    [owner, user] = await ethers.getSigners();

    // Deploy necessary contracts
    const MLPToken = await ethers.getContractFactory(
      'MatrixLayerProtocolToken'
    );
    mlpToken = await MLPToken.deploy();

    console.log(owner.address);
    console.log(user.address);

    const NFT = await ethers.getContractFactory('MatrixNFT');
    phoneNFT = await NFT.deploy('phone', 'phone', owner.address);
    matrixNFT = await NFT.deploy('matrix', 'matrix', owner.address);
    aiAgentOneNFT = await NFT.deploy('aiAgentOne', 'aiAgentOne', owner.address);
    aiAgentProNFT = await NFT.deploy('aiAgentPro', 'aiAgentPro', owner.address);
    aiAgentUltraNFT = await NFT.deploy(
      'aiAgentUltra',
      'aiAgentUltra',
      owner.address
    );

    console.log('mlpToken.address', mlpToken.target);
    console.log('phoneNFT.address', phoneNFT.target);
    console.log('matrixNFT.address', matrixNFT.target);
    console.log('aiAgentOneNFT.address', aiAgentOneNFT.target);
    console.log('aiAgentProNFT.address', aiAgentProNFT.target);
    console.log('aiAgentUltraNFT.address', aiAgentUltraNFT.target);

    const PoWStaking = await ethers.getContractFactory('MatrixPoWStaking');
    powStaking = await PoWStaking.deploy(mlpToken.target, owner.address, [
      phoneNFT.target,
      matrixNFT.target,
      aiAgentOneNFT.target,
      aiAgentProNFT.target,
      aiAgentUltraNFT.target,
    ]);
  });

  it('should allow staking', async function () {
    await phoneNFT.mint(user.address, 1);
    await matrixNFT.mint(user.address, 1);
    await aiAgentOneNFT.mint(user.address, 1);
    await aiAgentProNFT.mint(user.address, 1);
    await aiAgentUltraNFT.mint(user.address, 1);

    const balanceOfPhone = await phoneNFT.balanceOf(user.address);
    const balanceOfMatrix = await matrixNFT.balanceOf(user.address);
    const balanceOfAiAgentOne = await aiAgentOneNFT.balanceOf(user.address);
    const balanceOfAiAgentPro = await aiAgentProNFT.balanceOf(user.address);
    const balanceOfAiAgentUltra = await aiAgentUltraNFT.balanceOf(user.address);

    const phoneOwned = await phoneNFT.tokensOwned(user.address);
    const matrixOwned = await matrixNFT.tokensOwned(user.address);
    const aiAgentOneOwned = await aiAgentOneNFT.tokensOwned(user.address);
    const aiAgentProOwned = await aiAgentProNFT.tokensOwned(user.address);
    const aiAgentUltraOwned = await aiAgentUltraNFT.tokensOwned(user.address);

    console.log('balanceOfPhone', balanceOfPhone);
    console.log('balanceOfMatrix', balanceOfMatrix);
    console.log('balanceOfAiAgentOne', balanceOfAiAgentOne);
    console.log('balanceOfAiAgentPro', balanceOfAiAgentPro);
    console.log('balanceOfAiAgentUltra', balanceOfAiAgentUltra);
    console.log('phoneOwned', phoneOwned);
    console.log('matrixOwned', matrixOwned);
    console.log('aiAgentOneOwned', aiAgentOneOwned);
    console.log('aiAgentProOwned', aiAgentProOwned);
    console.log('aiAgentUltraOwned', aiAgentUltraOwned);

    await phoneNFT.connect(user).approve(powStaking.target, 0);
    await matrixNFT.connect(user).approve(powStaking.target, 0);
    await aiAgentOneNFT.connect(user).approve(powStaking.target, 0);
    await aiAgentProNFT.connect(user).approve(powStaking.target, 0);
    await aiAgentUltraNFT.connect(user).approve(powStaking.target, 0);
  });

  it('should calculate rewards correctly', async function () {});

  it('should calculate signature and claim rewards', async function () {
    await mlpToken
      .connect(owner)
      .approve(powStaking.target, ethers.parseEther('1250000000'));
    await powStaking
      .connect(owner)
      .fundRewardPool(ethers.parseEther('1250000000'));

    const domain = {
      name: 'MatrixStaking',
      version: '1',
      chainId: 31337, // Hardhat's default chainId
      verifyingContract: powStaking.target,
    };

    const types = {
      Claim: [
        { name: 'user', type: 'address' },
        { name: 'amount', type: 'uint256' },
        { name: 'nonce', type: 'uint256' },
      ],
    };

    const amount = ethers.parseEther('100');
    const nonce = 0;
    const value = {
      user: user.address,
      amount: amount,
      nonce: nonce,
    };

    // Log the data being signed
    console.log('Domain:', domain);
    console.log('Types:', types);
    console.log('Value:', value);

    // Sign the typed data
    const signature = await owner.signTypedData(domain, types, value);
    console.log('Signature:', signature);
    console.log('Signer address:', owner.address);

    // Claim rewards using the signature
    await powStaking.connect(user).claimReward(amount, signature);
  });

  it('should failed to claim rewards over max claimable amount', async function () {
    await mlpToken
      .connect(owner)
      .approve(powStaking.target, ethers.parseEther('1250000000'));
    await powStaking
      .connect(owner)
      .fundRewardPool(ethers.parseEther('1250000000'));

    const domain = {
      name: 'MatrixStaking',
      version: '1',
      chainId: 31337, // Hardhat's default chainId
      verifyingContract: powStaking.target,
    };

    const types = {
      Claim: [
        { name: 'user', type: 'address' },
        { name: 'amount', type: 'uint256' },
        { name: 'nonce', type: 'uint256' },
      ],
    };

    const amount = ethers.parseEther('1369863');
    const nonce = 0;
    const value = {
      user: user.address,
      amount: amount,
      nonce: nonce,
    };

    // Log the data being signed
    console.log('Domain:', domain);
    console.log('Types:', types);
    console.log('Value:', value);

    // Sign the typed data
    const signature = await owner.signTypedData(domain, types, value);
    console.log('Signature:', signature);
    console.log('Signer address:', owner.address);

    // Claim rewards using the signature
    await powStaking.connect(user).claimReward(amount, signature);
  });
});
