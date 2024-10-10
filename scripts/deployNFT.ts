import { deployContract } from './utils'

async function main() {
  const [deployer] = await ethers.getSigners()
  await deployContract('MatrixNFT', ['Phone', 'Phone', deployer.address], 'MatrixPhone')
  await deployContract('MatrixNFT', ['Matrix', 'MTX', deployer.address], 'Matrix')
  await deployContract('MatrixNFT', ['AI Agent One', 'AAO', deployer.address], 'MatrixAiAgentOne')
  await deployContract('MatrixNFT', ['AI Agent Pro', 'AAP', deployer.address], 'MatrixAiAgentPro')
  await deployContract('MatrixNFT', ['AI Agent Ultra', 'AAU', deployer.address], 'MatrixAiAgentUltra')
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
