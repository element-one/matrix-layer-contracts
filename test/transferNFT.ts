import { ethers, JsonRpcProvider } from 'ethers';
import 'dotenv/config';
import abi from '../scripts/abi';

async function transferNFT() {
  const privateKey = process.env.TESTNET_PRIVATE_KEY!;
  const rpcURL = process.env.TESTNET_BSC_RPC_URL!;
  const provider = new JsonRpcProvider(rpcURL);
  const ownerWallet = new ethers.Wallet(privateKey, provider);

  const MatrixAiAgentOneContract = new ethers.Contract(
    process.env.MATRIX_AI_AGENT_ONE_ADDRESS!,
    abi,
    ownerWallet
  );

  const fromAddress = '0x625cb73b8f106bc7B5016723Aad1BEfe0086A0E3';
  const toAddress = '0x3571674e85f3E900a94364Bbb44b7F97cd991ed9';
  const tokenId = 20; 

  try {
    const tx = await MatrixAiAgentOneContract['safeTransferFrom(address,address,uint256)'](
      fromAddress,
      toAddress,
      tokenId,
      { gasLimit: 1000000 }
    );
    await tx.wait();
    console.log(`NFT with tokenId ${tokenId} transferred from ${fromAddress} to ${toAddress}`);
  } catch (error) {
    console.error('Error transferring NFT:', error);
  }
}

transferNFT().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});