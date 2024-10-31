import { readFileSync } from 'fs'
import { deployContract } from './utils'

async function main() {
  const wlpAddress = await deployContract('MatrixLayerProtocolToken', [], 'MatrixLayerProtocolToken')
  const MatrixPhoneAddress = readFileSync('cache/MatrixPhone', 'utf-8')
  const MatrixAddress = readFileSync('cache/Matrix', 'utf-8')
  const MatrixAiAgentOneAddress = readFileSync('cache/MatrixAiAgentOne', 'utf-8')
  const MatrixAiAgentProAddress = readFileSync('cache/MatrixAiAgentPro', 'utf-8')
  const MatrixAiAgentUltraAddress = readFileSync('cache/MatrixAiAgentUltra', 'utf-8')

  await deployContract('MatrixPoWStaking', [
    wlpAddress,
    process.env.SIGNER_ADDRESS,
    [MatrixPhoneAddress, MatrixAddress, MatrixAiAgentOneAddress, MatrixAiAgentProAddress, MatrixAiAgentUltraAddress],
  ])
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
