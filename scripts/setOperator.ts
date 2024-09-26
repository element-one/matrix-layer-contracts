import { ethers, JsonRpcProvider } from 'ethers';
import 'dotenv/config';
import { mlinkAiAgentOneABI, mlinkPhoneABI, mlinkAiAgentUltraABI, mlinkAiAgentProABI } from './abi';

async function setOperator() {
  const privateKey = process.env.NODE_ENV === 'production' ? process.env.MAINNET_PRIVATE_KEY : process.env.TESTNET_PRIVATE_KEY;
  const rpcURL = process.env.NODE_ENV === 'production' ? process.env.MAINNET_BSC_RPC_URL : process.env.TESTNET_BSC_RPC_URL;
  const provider = new JsonRpcProvider(rpcURL);
  const ownerWallet = new ethers.Wallet(privateKey!, provider);
  
  const MLinkPhoneContract = new ethers.Contract(process.env.MLINK_PHONE_ADDRESS!, mlinkPhoneABI, ownerWallet);
  const MLinkAiAgentOneContract = new ethers.Contract(process.env.MLINK_AI_AGENT_ONE_ADDRESS!, mlinkAiAgentOneABI, ownerWallet);
  const MLinkAiAgentProContract = new ethers.Contract(process.env.MLINK_AI_AGENT_PRO_ADDRESS!, mlinkAiAgentProABI, ownerWallet);
  const MLinkAiAgentUltraContract = new ethers.Contract(process.env.MLINK_AI_AGENT_ULTRA_ADDRESS!, mlinkAiAgentUltraABI, ownerWallet);
  const operatorAddress = process.env.OPERATOR_ADDRESS!;

  try {
    let tx = await MLinkPhoneContract.setOperator(operatorAddress, { gasLimit: 1000000 });
    await tx.wait();
    tx = await MLinkAiAgentOneContract.setOperator(operatorAddress, { gasLimit: 1000000 });
    await tx.wait();
    tx = await MLinkAiAgentProContract.setOperator(operatorAddress, { gasLimit: 1000000 });
    await tx.wait();
    tx = await MLinkAiAgentUltraContract.setOperator(operatorAddress, { gasLimit: 1000000 });
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