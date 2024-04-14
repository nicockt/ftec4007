require("dotenv").config();

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
  projectName = "project",
  desc = "default desc",
  targetFund = 10,
  startFromNow = 10, // 10s from now
  duration = 60 * 60 * 24 * 30 // 30 days
) => {
  if (projectName == "project") {
    projectName = projectName + "-" + Date.now().toString();
  }
  const transaction = await crowdfundingContract.launch(
    projectName,
    desc,
    targetFund,
    startFromNow,
    duration
  );

  const receipt = await transaction.wait();

  // Find the Launch event in the receipt
  const launchEvent = receipt.events?.find((e) => e.event === "Launch");

  if (launchEvent) {
    return launchEvent.args;
  }

  return null;
};

const transferNFT = async (projectId) => {
  // const { funders, amounts } = await crowdfundingContract.getFunders(projectId);
  const results = await crowdfundingContract.getFunders(projectId);
  console.log(results);
  const funders = results[0];
  const amounts = results[1];
  console.log(funders);
  console.log(amounts);

  // Mint NFTs to funders
  //   for (let i = 0; i < funders.length; i++) {
  //     const funder = funders[i];
  //     const amount = amounts[i];
  //     await nftContract.safeMint(funder, Math.min(Math.floor(amount), 1));
  //     console.log(`Minted NFT to ${funder}`);
  //   }
};

const fundProject = async (projectId, fundAmount) => {
  var result = null;
  const options = {
    gasLimit: 3000000,
    value: ethers.utils.parseUnits(fundAmount.toString(), "wei"),
  };
  const fundTx = await crowdfundingContract.fund(projectId, {
    ...options,
  });

  const fundReceipt = await fundTx.wait();
  const fundEvent = fundReceipt.events?.find((e) => e.event === "Fund");

  if (fundEvent) {
    console.log("Fund Success");
    console.log(fundEvent.args);
    result = fundEvent.args;
  }

  const successFundEvent = fundReceipt.events?.find(
    (e) => e.event === "SuccessFund"
  );

  if (successFundEvent) {
    const successProjectId = successFundEvent.projectId.toNumber();
    const raisedFund = successFundEvent._raisedFund.toNumber();
    console.log(
      `Project ${successProjectId}: Funding met target amount, raised fund: ${raisedFund}`
    );
    result = successFundEvent.args;
    await transferNFT(successProjectId);
  }
  return result;
};

const main = async () => {
  //   const project = await launchProject();
  //   if (project === null) {
  //     console.log("Fail to launch project");
  //     return;
  //   }

  //   const projectId = parseInt(project._id);
  //   const projectName = project._projectName.toString();
  //   const projectOwner = project._owner.toString();
  //   const targetFund = project._targetFund.toString();
  //   const endUnix = parseInt(project._endAt);
  //   const endDate = new Date(endUnix * 1000);
  //   formattedEndDate = endDate.toGMTString();
  //   console.log(
  //     `Project Created - ID: ${projectId}, name: ${projectName}, owner: ${projectOwner}, targetFund: ${targetFund}, endDate: ${formattedEndDate}`
  //   );

  const fundEvent = fundProject(11, 10);
};

main();
