import { deployContract } from './utils'

async function main() {
  await deployContract('MatrixAiAgentOne', undefined, true)
  await deployContract('MatrixAiAgentPro', undefined, true)
  await deployContract('MatrixAiAgentUltra', undefined, true)
  await deployContract('MatrixPhone', undefined, true)
  await deployContract('Matrix', undefined, true)
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
