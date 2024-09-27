import { deployContract } from './utils'

async function main() {
  await deployContract('MatrixPhone', '', true)
  await deployContract('MatrixAiAgentOne', '', true)
  await deployContract('MatrixAiAgentPro', '', true)
  return deployContract('MatrixAiAgentUltra', '', true)
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
