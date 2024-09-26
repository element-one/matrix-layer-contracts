import { deployContract } from './utils'

async function main() {
  await deployContract('MLinkPhone', '', true)
  await deployContract('MLinkAiAgentOne', '', true)
  await deployContract('MLinkAiAgentPro', '', true)
  return deployContract('MLinkAiAgentUltra', '', true)
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
