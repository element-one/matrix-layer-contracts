import { ethers, JsonRpcProvider } from 'ethers'
import 'dotenv/config'
import { mlinkAiAgentABI, mlinkWifi } from './abi'

async function setOperator() {
  const privateKey = process.env.NODE_ENV === 'production' ? process.env.MAINNET_PRIVATE_KEY : process.env.TESTNET_PRIVATE_KEY

  const provider = new JsonRpcProvider('https://mainnet.rpc.metabitglobal.com/')
  const ownerWallet = new ethers.Wallet(privateKey!, provider)
  
  const MLinkAiAgentContract = new ethers.Contract(process.env.MLINK_AI_AGENT_ADDRESS!, mlinkAiAgentABI, ownerWallet)
  const MLinkWifiContract = new ethers.Contract(process.env.MLINK_WIFI_ADDRESS!, mlinkWifi, ownerWallet)
  const operatorAddress = process.env.OPERATOR_ADDRESS!
  try {
    let tx = await MLinkAiAgentContract.setOperator(operatorAddress)
    await tx.wait()
    tx = await MLinkWifiContract.setOperator(operatorAddress)
    await tx.wait()
    console.log(`Operator set to ${operatorAddress}`)
  } catch (error) {
    console.error('Error setting operator:', error)
  }
}

setOperator().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
