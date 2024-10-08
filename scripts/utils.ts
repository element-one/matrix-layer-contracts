import { BaseContract } from 'ethers'
import { writeFileSync } from 'fs'
import { ethers, run, upgrades } from 'hardhat'

export const delay = 20000

async function verifyImplementation(implementationAddress: string) {
  try {
    //  Call the Hardhat verification plugin to verify the implementation contract
    await run('verify:verify', {
      address: implementationAddress,
      constructorArguments: [],
    })
    console.log('Contract verified successfully!\n')
  } catch (error: any) {
    if (error.message.includes('Already Verified')) {
      console.log('Contract already verified!\n')
      return
    }

    console.error('Error verifying the contract:', error)
    setTimeout(() => verifyImplementation(implementationAddress), delay)
  }
}

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
  } catch (error: any) {
    console.error('Error verifying the contract:', error)
    if (error.message.includes('Already Verified')) {
      console.log(error.message)
      console.log('Contract already verified!\n')
      return
    }

    setTimeout(() => verifyContract(deployedAddress, contractPath, contractName, constructorArguments), delay)
  }
}

export async function deployContract(contractName: string, params: any[] = [], fileName = '', isNFT = false) {
  const [deployer] = await ethers.getSigners()
  console.log(`Deploying ${contractName} contract with the account:`, deployer.address)

  const Contract = await ethers.getContractFactory(contractName)

  let constructorArguments: any[] = []
  let deployedAddress = ''
  let contract: BaseContract
  if (isNFT) {
    console.log('Deploying NFT contract...')
    contract = await upgrades.deployProxy(Contract, params, {
      initializer: 'initialize',
      txOverrides: { gasLimit: 5000000 },
    })
    constructorArguments = [] // For proxy contracts, constructor arguments should be empty
  } else {
    console.log('Deploying regular contract...')
    contract = await Contract.deploy(...params, { gasLimit: 5000000 })
    constructorArguments = params
  }

  await contract.waitForDeployment()

  deployedAddress = await contract.getAddress()

  console.log(`${fileName || contractName} deployed to: ${deployedAddress}`)
  writeFileSync(`cache/${fileName || contractName}`, deployedAddress)

  console.log('Waiting for the contract data to update...')
  // eslint-disable-next-line no-promise-executor-return
  await new Promise((resolve) => setTimeout(resolve, delay))

  // Verify the contract
  verifyContract(deployedAddress, `contracts/${contractName}.sol`, contractName, constructorArguments)
}

export async function upgradeContract(proxyAddress: string, contractName: string) {
  const Contract = await ethers.getContractFactory(contractName)

  // Upgrade the proxy contract to the new implementation
  const upgraded = await upgrades.upgradeProxy(proxyAddress, Contract, {
    txOverrides: { gasLimit: 5000000 },
  })

  // Get the address of the upgraded contract (this address remains unchanged and is still the proxy contract address)
  const upgradedAddress = await upgraded.getAddress()

  console.log(`${contractName} contract upgraded successfully at: ${upgradedAddress}`)

  const implementationAddress = await upgrades.erc1967.getImplementationAddress(proxyAddress)
  console.log(`New implementation address: ${implementationAddress}`)

  // Verify the new implementation contract
  await verifyImplementation(implementationAddress)
}
