// npx hardhat run scripts/deploy.js --network sepolia
// Deploy to sepolia testnet, can be checked on etherscan

async function main() {
  const Crowdfunding = await ethers.getContractFactory("Crowdfunding");

  // Start deployment, returning a promise that resolves to a contract object

  const crowdfunding = await Crowdfunding.deploy();
  console.log(
    "Crowdfunding Contract deployed to address:",
    crowdfunding.address
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
