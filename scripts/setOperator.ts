import { ethers, JsonRpcProvider } from 'ethers';
import 'dotenv/config';
import abi from './abi';

async function setOperator() {
  const privateKey = process.env.NODE_ENV === 'production' ? process.env.MAINNET_PRIVATE_KEY : process.env.TESTNET_PRIVATE_KEY;
  const rpcURL = process.env.NODE_ENV === 'production' ? process.env.MAINNET_BSC_RPC_URL : process.env.TESTNET_BSC_RPC_URL;
  const provider = new JsonRpcProvider(rpcURL);
  const ownerWallet = new ethers.Wallet(privateKey!, provider);
  
  const MatrixContract = new ethers.Contract(process.env.MATRIX_ADDRESS!, abi, ownerWallet);
  const MatrixPhoneContract = new ethers.Contract(process.env.MATRIX_PHONE_ADDRESS!, abi, ownerWallet);
  const MatrixAiAgentOneContract = new ethers.Contract(process.env.MATRIX_AI_AGENT_ONE_ADDRESS!, abi, ownerWallet);
  const MatrixAiAgentProContract = new ethers.Contract(process.env.MATRIX_AI_AGENT_PRO_ADDRESS!, abi, ownerWallet);
  const MatrixAiAgentUltraContract = new ethers.Contract(process.env.MATRIX_AI_AGENT_ULTRA_ADDRESS!, abi, ownerWallet);
  const operatorAddress = process.env.OPERATOR_ADDRESS!;

  try {
    let tx = await MatrixContract.setOperator(operatorAddress, { gasLimit: 1000000 });
    await tx.wait();
    tx = await MatrixPhoneContract.setOperator(operatorAddress, { gasLimit: 1000000 });
    await tx.wait();
    tx = await MatrixAiAgentOneContract.setOperator(operatorAddress, { gasLimit: 1000000 });
    await tx.wait();
    tx = await MatrixAiAgentProContract.setOperator(operatorAddress, { gasLimit: 1000000 });
    await tx.wait();
    tx = await MatrixAiAgentUltraContract.setOperator(operatorAddress, { gasLimit: 1000000 });
    await tx.wait();
    console.log(`Operator set to ${operatorAddress}`);
  } catch (error) {
    console.error('Error setting operator:', error);
  }
}

setOperator().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});