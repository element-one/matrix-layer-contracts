import { ethers, JsonRpcProvider } from 'ethers'
import 'dotenv/config'
import abi from './abi'

async function setOperator() {
  const privateKey =
    process.env.NODE_ENV === 'production' ? process.env.MAINNET_PRIVATE_KEY : process.env.TESTNET_PRIVATE_KEY
  const rpcURL =
    process.env.NODE_ENV === 'production' ? process.env.MAINNET_BSC_RPC_URL : process.env.TESTNET_BSC_RPC_URL
  const provider = new JsonRpcProvider(rpcURL)
  const ownerWallet = new ethers.Wallet(privateKey!, provider)

  const MatrixContract = new ethers.Contract(process.env.MATRIX_ADDRESS!, abi, ownerWallet)
  const MatrixPhoneContract = new ethers.Contract(process.env.MATRIX_PHONE_ADDRESS!, abi, ownerWallet)
  const MatrixAiAgentOneContract = new ethers.Contract(process.env.MATRIX_AI_AGENT_ONE_ADDRESS!, abi, ownerWallet)
  const MatrixAiAgentProContract = new ethers.Contract(process.env.MATRIX_AI_AGENT_PRO_ADDRESS!, abi, ownerWallet)
  const MatrixAiAgentUltraContract = new ethers.Contract(process.env.MATRIX_AI_AGENT_ULTRA_ADDRESS!, abi, ownerWallet)
  const operatorAddress = process.env.OPERATOR_ADDRESS
  const paymentAddress = process.env.PAYMENT_ADDRESS
  
  try {
    let tx

    // Set operatorAddress for all contracts
    tx = await MatrixContract.setOperator(operatorAddress, true, { gasLimit: 1000000 })
    await tx.wait()
    tx = await MatrixPhoneContract.setOperator(operatorAddress, true, { gasLimit: 1000000 })
    await tx.wait()
    tx = await MatrixAiAgentOneContract.setOperator(operatorAddress, true, { gasLimit: 1000000 })
    await tx.wait()
    tx = await MatrixAiAgentProContract.setOperator(operatorAddress, true, { gasLimit: 1000000 })
    await tx.wait()
    tx = await MatrixAiAgentUltraContract.setOperator(operatorAddress, true, { gasLimit: 1000000 })
    await tx.wait()

    // Set paymentAddress for all contracts
    tx = await MatrixContract.setOperator(paymentAddress, true, { gasLimit: 1000000 })
    await tx.wait()
    tx = await MatrixPhoneContract.setOperator(paymentAddress, true, { gasLimit: 1000000 })
    await tx.wait()
    tx = await MatrixAiAgentOneContract.setOperator(paymentAddress, true, { gasLimit: 1000000 })
    await tx.wait()
    tx = await MatrixAiAgentProContract.setOperator(paymentAddress, true, { gasLimit: 1000000 })
    await tx.wait()
    tx = await MatrixAiAgentUltraContract.setOperator(paymentAddress, true, { gasLimit: 1000000 })
    await tx.wait()

    console.log(`Operator set to ${operatorAddress} and ${paymentAddress}`)
  } catch (error) {
    console.error('Error setting operator:', error)
  }
}

setOperator().catch((error) => {
  console.error(error)
  process.exitCode = 1
})