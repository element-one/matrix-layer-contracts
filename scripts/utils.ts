import { writeFileSync } from 'fs'
import { ethers, run } from 'hardhat'

export const delay = 20000

async function verifyContract(
  deployedAddress: string,
  contractPath: string,
  contractName: string,
  constructorArguments: any[]
) {
  try {
    await run('verify:verify', {
      address: deployedAddress,
      constructorArguments,
      contract: `${contractPath}:${contractName}`,
    })

    console.log('Contract verified successfully!\n')
  } catch (error) {
    console.error('Error verifying the contract:', error)
    setTimeout(() => verifyContract(deployedAddress, contractPath, contractName, constructorArguments), delay)
  }
}

export async function deployContract(contractName: string, params: any[] = [], fileName = '') {
  console.log(params)
  const [deployer] = await ethers.getSigners()
  console.log(`Deploying ${contractName} contract with the account:`, deployer.address)

  const Contract = await ethers.getContractFactory(contractName)

  let constructorArguments: any[] = []
  const contract = await Contract.deploy(...params, { gasLimit: 3000000 })
  constructorArguments = params

  await contract.waitForDeployment()

  const deployedAddress = await contract.getAddress()
  console.log(`${fileName || contractName} deployed to: ${deployedAddress}`)
  writeFileSync(`cache/${fileName || contractName}`, deployedAddress)

  console.log('Waiting for the contract data to update...')
  // eslint-disable-next-line no-promise-executor-return
  await new Promise((resolve) => setTimeout(resolve, delay))

  // Verify the contract
  verifyContract(deployedAddress, `contracts/${contractName}.sol`, contractName, constructorArguments)
}
