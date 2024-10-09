import { expect } from 'chai';
import { ethers } from 'hardhat';
import { keccak256 } from 'ethers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { Contract } from 'ethers';

describe('MatrixPayment', function () {
  let MatrixPayment: Contract;
  let matrixPayment: Contract;
  let usdt: Contract;
  let MockNFT: Contract;
  let nftContracts: string[];
  let owner: SignerWithAddress;
  let addr1: SignerWithAddress;
  let addr2: SignerWithAddress;
  let addr3: SignerWithAddress;
  let signer: SignerWithAddress;
  let signerAddress: string;

  const SALE_TYPEHASH = keccak256(
    'Sale(address buyer,uint256 totalAmount,address referral)'
  );

  beforeEach(async function () {
    [owner, addr1, addr2, addr3, signer] = await ethers.getSigners();
    signerAddress = signer.address;

    // Deploy mock USDT token
    const USDTFactory = await ethers.getContractFactory('MockUSDT');
    await usdt.deployed();

    // Deploy mock NFT contracts
    const MockNFTFactory = await ethers.getContractFactory('MockNFT');
    nftContracts = [];
    for (let i = 0; i < 5; i++) {
      const nft = await MockNFTFactory.deploy();
      await nft.deployed();
      nftContracts.push(nft.address);
    }

    // Deploy MatrixPayment contract
    const MatrixPaymentFactory = await ethers.getContractFactory(
      'MatrixPayment'
    );
    matrixPayment = await MatrixPaymentFactory.deploy(
      usdt.address,
      nftContracts,
      signerAddress
    );
    await matrixPayment.deployed();

    // Mint USDT tokens for testing
    await usdt.mint(addr1.address, ethers.utils.parseEther('1000'));
    await usdt.mint(addr2.address, ethers.utils.parseEther('1000'));
    await usdt.mint(addr3.address, ethers.utils.parseEther('1000'));
  });

  async function getSignature(
    buyer: string,
    totalAmount: string,
    referral: string,
    signer: SignerWithAddress
  ) {
    const domain = {
      name: 'MatrixPayment',
      version: '1',
      chainId: (await ethers.provider.getNetwork()).chainId,
      verifyingContract: matrixPayment.address,
    };

    const types = {
      Sale: [
        { name: 'buyer', type: 'address' },
        { name: 'totalAmount', type: 'uint256' },
        { name: 'referral', type: 'address' },
      ],
    };

    const value = {
      buyer: buyer,
      totalAmount: totalAmount,
      referral: referral,
    };

    return await signer._signTypedData(domain, types, value);
  }

  it('Should set the correct USDT token address', async function () {
    expect(await matrixPayment.usdtToken()).to.equal(usdt.address);
  });

  it('Should set the correct NFT contract addresses', async function () {
    for (let i = 0; i < 5; i++) {
      expect(await matrixPayment.getNftContractAddress(i)).to.equal(
        nftContracts[i]
      );
    }
  });

  it('Should process a private sale payment correctly', async function () {
    const totalAmount = ethers.utils.parseEther('100');
    const orders = [
      { deviceType: 0, quantity: 1 },
      { deviceType: 1, quantity: 2 },
    ];
    const referral = addr2.address;

    const signature = await getSignature(
      addr1.address,
      totalAmount.toString(),
      referral,
      signer
    );

    await matrixPayment.setPrivateSaleActive(true);

    await usdt.connect(addr1).approve(matrixPayment.address, totalAmount);

    await expect(
      matrixPayment
        .connect(addr1)
        .payPrivateSale(totalAmount, orders, referral, signature)
    )
      .to.emit(matrixPayment, 'PaymentReceived')
      .withArgs({
        buyer: addr1.address,
        orders: orders,
        totalAmount: totalAmount,
      });

    expect(await usdt.balanceOf(matrixPayment.address)).to.equal(totalAmount);
  });

  it('Should process a public sale payment correctly', async function () {
    const totalAmount = ethers.utils.parseEther('200');
    const orders = [
      { deviceType: 2, quantity: 1 },
      { deviceType: 3, quantity: 1 },
    ];
    const referral = addr3.address;

    const signature = await getSignature(
      addr2.address,
      totalAmount.toString(),
      referral,
      signer
    );

    await matrixPayment.setPublicSaleActive(true);

    await usdt.connect(addr2).approve(matrixPayment.address, totalAmount);

    await expect(
      matrixPayment
        .connect(addr2)
        .payPublicSale(totalAmount, orders, referral, signature)
    )
      .to.emit(matrixPayment, 'PaymentReceived')
      .withArgs({
        buyer: addr2.address,
        orders: orders,
        totalAmount: totalAmount,
      });

    expect(await usdt.balanceOf(matrixPayment.address)).to.equal(totalAmount);
  });

  it('Should fail if the signature is invalid', async function () {
    const totalAmount = ethers.utils.parseEther('100');
    const orders = [{ deviceType: 0, quantity: 1 }];
    const referral = addr2.address;

    const invalidSignature = await getSignature(
      addr1.address,
      totalAmount.toString(),
      referral,
      addr3 // Using a different signer to create an invalid signature
    );

    await matrixPayment.setPrivateSaleActive(true);

    await usdt.connect(addr1).approve(matrixPayment.address, totalAmount);

    await expect(
      matrixPayment
        .connect(addr1)
        .payPrivateSale(totalAmount, orders, referral, invalidSignature)
    ).to.be.revertedWith('Invalid signature');
  });
});
