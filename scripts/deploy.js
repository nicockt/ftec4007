// npx hardhat run scripts/deploy.js --network sepolia
// Deploy to sepolia testnet, can be checked on etherscan

async function main() {
  const Crowdfunding = await ethers.getContractFactory("Crowdfunding");
  const NFT = await ethers.getContractFactory("NFT");

  // Start deployment, returning a promise that resolves to a contract object

  const crowdfunding = await Crowdfunding.deploy();

  //Crowdfunding Contract deployed to address: 0xad11d2475E355F85842fa7f1A1C28bbF1dc9e9dA
  console.log(
    "Crowdfunding Contract deployed to address:",
    crowdfunding.address
  );

  const nft = await NFT.deploy(crowdfunding.address);

  //Contract deployed to address: 0x4db86Ce55567E14Cf4Eabbeed9b61857aCA03757
  console.log("Contract deployed to address:", nft.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
