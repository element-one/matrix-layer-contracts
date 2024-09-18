import { readFileSync } from 'fs'
import { deployContract } from './utils'

async function main() {
  await deployContract('MockUSDT')
  return deployContract('Payment', readFileSync('cache/MockUSDT', 'utf-8'))
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
