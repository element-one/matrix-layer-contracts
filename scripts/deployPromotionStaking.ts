import { deployContract } from './utils'

async function main() {
  await deployContract('MatrixPromotionStaking', [
    process.env.MLP_TOKEN_ADDRESS,
    process.env.SIGNER_ADDRESS,
    process.env.ACCOUNTING_ADDRESS,
  ])
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
