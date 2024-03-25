// npx hardhat run scripts/deploy.js --network sepolia
// Deploy to sepolia testnet, can be checked on etherscan

async function main() {
  const Crowdfunding = await ethers.getContractFactory("Crowdfunding");
  const NFT = await ethers.getContractFactory("NFT");

  // Start deployment, returning a promise that resolves to a contract object

  const crowdfunding = await Crowdfunding.deploy();
  console.log(
    "Crowdfunding Contract deployed to address:",
    crowdfunding.address
  );

  const nft = await NFT.deploy(crowdfunding.address);
  console.log("Contract deployed to address:", nft.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
