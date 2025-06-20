const { ethers } = require("hardhat");

async function main() {
  // Get the contract factory
  const DecentralizedEventInsurance = await ethers.getContractFactory("DecentralizedEventInsurance");
  
  console.log("Deploying DecentralizedEventInsurance contract...");
  
  // Deploy the contract
  const decentralizedEventInsurance = await DecentralizedEventInsurance.deploy();
  
  // Wait for the deployment to be confirmed
  await decentralizedEventInsurance.deployed();
  
  console.log("DecentralizedEventInsurance contract deployed to:", decentralizedEventInsurance.address);
  console.log("Transaction hash:", decentralizedEventInsurance.deployTransaction.hash);
  
  // Get the deployer account
  const [deployer] = await ethers.getSigners();
  console.log("Deployed by account:", deployer.address);
  console.log("Account balance:", ethers.utils.formatEther(await deployer.getBalance()));
  
  // Verify deployment
  console.log("Verifying deployment...");
  const contractBalance = await decentralizedEventInsurance.getContractBalance();
  const owner = await decentralizedEventInsurance.owner();
  const policyCounter = await decentralizedEventInsurance.policyCounter();
  
  console.log("Contract balance:", ethers.utils.formatEther(contractBalance), "ETH");
  console.log("Contract owner:", owner);
  console.log("Policy counter:", policyCounter.toString());
  
  console.log("Deployment completed successfully!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Error deploying contract:", error);
    process.exit(1);
  });
