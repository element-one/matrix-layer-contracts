import { deployContract } from './utils'

async function main() {
  await deployContract('MLinkAiAgent', '', true)
  return deployContract('MLinkWifi', '', true)
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
