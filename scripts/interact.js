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
  CROWDFUNDING_ADDRESS,
  crowdfunding.abi,
  signer
);
const nftContract = new ethers.Contract(NFT_ADDRESS, nft.abi, signer);

const launchProject = async (
  projectName,
  desc,
  targetFund,
  startFromNow,
  duration
) => {
  const projectId = await crowdfundingContract.launch(
    projectName,
    desc,
    targetFund,
    startFromNow,
    duration
  );
  return projectId;
};

const getSuccessFundEvent = async () => {
  crowdfundingContract.on(
    "SuccessFund",
    async (projectId, raisedFund, event) => {
      console.log(`Project ID: ${projectId}, Raised Fund: ${raisedFund}`);
      let successFundEvent = {
        projectId: projectId,
        raisedFund: raisedFund,
        eventData: event,
      };
      console.log(successFundEvent);
      // const { funders, amounts } = await crowdfundingContract.getFunders(projectId);
      const result = await crowdfundingContract.getFunders(projectId);
      console.log(result);
      const funders = result[0];
      const amounts = result[1];
      console.log(funders);
      console.log(amounts);

      // Mint NFTs to funders
      for (let i = 0; i < funders.length; i++) {
        const funder = funders[i];
        const amount = amounts[i];

        // Replace with your NFT minting logic
        const tokenId = i; // Replace with your token ID logic

        await nftContract.safeMint(funder, Math.floor(amount));
        console.log(`Minted NFT to ${funder}`);
      }
    }
  );
};

async function main() {
  const projectName = "project1";
  const desc = "First crowdfunding project!";
  const targetFund = "100"; // Wei
  const startFromNow = 10; // 10s from now
  const duration = 60 * 60 * 24 * 30; // 30 days

  const projectId = launchProject(
    projectName,
    desc,
    targetFund,
    startFromNow,
    duration
  );
  console.log(`Project ID: ${projectId}`);
  getSuccessFundEvent();
}
main();
