const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('MatrixPayment', function () {
  let MatrixPayment;
  let matrixPayment;
  let PaymentToken;
  let paymentToken;
  let owner;
  let addr1;
  let addr2;

  beforeEach(async function () {
    // Deploy the payment token (e.g., a simple ERC20 token)
    PaymentToken = await ethers.getContractFactory('MockUSDT');
    paymentToken = await PaymentToken.deploy('Payment Token', 'PAY');
    await paymentToken.deployed();

    // Deploy the MatrixPayment contract
    MatrixPayment = await ethers.getContractFactory('MatrixPayment');
    matrixPayment = await MatrixPayment.deploy(paymentToken.address);
    await matrixPayment.deployed();

    [owner, addr1, addr2] = await ethers.getSigners();

    // Mint some tokens for testing
    await paymentToken.mint(addr1.address, ethers.utils.parseEther('1000'));
    await paymentToken.mint(addr2.address, ethers.utils.parseEther('1000'));
  });

  describe('Deployment', function () {
    it('Should set the right owner', async function () {
      expect(await matrixPayment.owner()).to.equal(owner.address);
    });

    it('Should set the correct payment token', async function () {
      expect(await matrixPayment.paymentToken()).to.equal(paymentToken.address);
    });
  });

  describe('Public Sale Payment', function () {
    it('Should process a public sale payment correctly', async function () {
      const orderId = 1;
      const orders = [
        { deviceType: 'Phone', quantity: 2 },
        { deviceType: 'Matrix', quantity: 1 },
      ];

      // Approve tokens for payment
      await paymentToken
        .connect(addr1)
        .approve(matrixPayment.address, ethers.utils.parseEther('1000'));

      // Process payment
      await expect(matrixPayment.connect(addr1).payPublicSale(orderId, orders))
        .to.emit(matrixPayment, 'PaymentReceived')
        .withArgs(
          addr1.address,
          orderId,
          [
            ['Phone', 2, ethers.utils.parseEther('200')],
            ['Matrix', 1, ethers.utils.parseEther('100')],
          ],
          ethers.utils.parseEther('300')
        );

      // Check token balance after payment
      const balance = await paymentToken.balanceOf(matrixPayment.address);
      expect(balance).to.equal(ethers.utils.parseEther('300'));
    });

    it('Should fail if payment amount is insufficient', async function () {
      const orderId = 2;
      const orders = [
        { deviceType: 'Phone', quantity: 1000 }, // Intentionally large quantity
      ];

      // Approve tokens for payment (but not enough)
      await paymentToken
        .connect(addr2)
        .approve(matrixPayment.address, ethers.utils.parseEther('1000'));

      // Attempt to process payment
      await expect(
        matrixPayment.connect(addr2).payPublicSale(orderId, orders)
      ).to.be.revertedWith('Payment transfer failed');
    });
  });

  // Add more test cases as needed
});
