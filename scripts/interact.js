const API_URL = process.env.API_URL;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const CROWDFUNDING_ADDRESS = process.env.CROWDFUNDING_ADDRESS;
const NFT_ADDRESS = process.env.NFT_ADDRESS;

// Get ABI for Hardhat
const crowdfunding = require("../artifacts/contracts/Crowdfunding.sol/Crowdfunding.json");
const nft = require("../artifacts/contracts/NFT.sol/NFT.json");

// Ethers.js
const ethers = require("ethers");
// Provider: gives you read and write access to the blockchain
const alchemyProvider = new ethers.providers.JsonRpcProvider(API_URL);
// Signer: Ethereum account that has the ability to sign transactions
const signer = new ethers.Wallet(PRIVATE_KEY, alchemyProvider);
// Contract: Ethers.js object representing a specific contract deployed on-chain
const crowdfundingContract = new ethers.Contract(
  CONTRACT_ADDRESS,
  crowdfunding.abi,
  signer
);
const nftContract = new ethers.Contract(CONTRACT_ADDRESS, nft.abi, signer);

async function main() {
  const projectName = "project1";
  const targetFund = "100"; // Wei
  const startAt = Date.now() + 5000; // 5s from now
  const endAt = startAt + 1000 * (60 * 60 * 24 * 30); // 30 days

  const project = await crowdfundingContract.launch(
    projectName,
    targetFund,
    startAt,
    endAt
  );
  await project.wait();
}
main();
