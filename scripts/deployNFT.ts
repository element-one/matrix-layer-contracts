import { deployContract } from './utils'

async function main() {
  const [deployer] = await ethers.getSigners()
  await deployContract('MatrixNFT', ['Phone', 'Phone', deployer.address], 'MatrixPhone', true)
  await deployContract('MatrixNFT', ['Matrix', 'MTX', deployer.address], 'Matrix', true)
  await deployContract('MatrixNFT', ['AI Agent One', 'AAO', deployer.address], 'MatrixAiAgentOne', true)
  await deployContract('MatrixNFT', ['AI Agent Pro', 'AAP', deployer.address], 'MatrixAiAgentPro', true)
  await deployContract('MatrixNFT', ['AI Agent Ultra', 'AAU', deployer.address], 'MatrixAiAgentUltra', true)
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
