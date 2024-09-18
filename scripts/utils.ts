import { writeFileSync } from 'fs'
import { ethers, run } from 'hardhat'

export const delay = 20000

async function verifyContract(
  deployedAddress: string,
  contractPath: string,
  contractName: string,
  constructorArguments: string[]
) {
  try {
    await run('verify:verify', {
      address: deployedAddress,
      constructorArguments,
      contract: `${contractPath}:${contractName}`,
    })

    console.log('Contract verified successfully')
  } catch (error) {
    console.error('Error verifying the contract:', error)
    setTimeout(() => verifyContract(deployedAddress, contractPath, contractName, constructorArguments), delay)
  }
}

export async function deployContract(contractName: string, tokenAddress?: string, disableVerify?: boolean) {
  const [deployer] = await ethers.getSigners()
  console.log(`Deploying ${contractName} contract with the account:`, deployer.address)

  const Contract = await ethers.getContractFactory(contractName)

  let contract
  let constructorArguments: string[] = []
  if (tokenAddress) {
    contract = await Contract.deploy(tokenAddress, { gasLimit: 3000000 })
    constructorArguments = [tokenAddress]
  } else if (contractName === 'MockUSDT') {
    contract = await Contract.deploy({ gasLimit: 3000000 })
  } else {
    contract = await Contract.deploy(deployer.address, { gasLimit: 3000000 })
    constructorArguments = [deployer.address]
  }

  await contract.waitForDeployment()

  const deployedAddress = await contract.getAddress()
  console.log(`${contractName} deployed to: ${deployedAddress}`)
  writeFileSync(`cache/${contractName}`, deployedAddress)

  if (!disableVerify) {
    console.log('Waiting for the contract data to update...')
    // eslint-disable-next-line no-promise-executor-return
    await new Promise((resolve) => setTimeout(resolve, delay))

    // Verify the contract
    verifyContract(deployedAddress, `contracts/${contractName}.sol`, contractName, constructorArguments)
  }
}
