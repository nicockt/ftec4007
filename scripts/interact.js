const API_URL = process.env.API_URL;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const CROWDFUNDING_ADDRESS = "0x51db8d67f51730D11718a64476D4F562aD82f91f";

// Get ABI for Hardhat
const crowdfunding = require("../artifacts/contracts/Crowdfunding.sol/Crowdfunding.json");
const nft = require("../artifacts/contracts/NFT.sol/NFT.json");

// Ethers.js
const eth = require("ethers");
// Provider: gives you read and write access to the blockchain
const alchemyProvider = new eth.providers.JsonRpcProvider(API_URL);
// Signer: Ethereum account that has the ability to sign transactions
const signer = new eth.Wallet(PRIVATE_KEY, alchemyProvider);
// Contract: Ethers.js object representing a specific contract deployed on-chain
const crowdfundingContract = new eth.Contract(
  CROWDFUNDING_ADDRESS,
  crowdfunding.abi,
  signer
);

const launchProject = async (
  projectName = "project",
  desc = "default desc",
  targetFund = 10,
  startFromNow = 10, // 10s from now
  duration = 60 * 60 * 24 * 30 // 30 days
) => {
  console.log(`Start launching ${projectName}`);
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
    const project = launchEvent.args;
    const projectId = parseInt(project._id);
    const projectName = project._projectName.toString();
    const projectOwner = project._owner.toString();
    const targetFund = project._targetFund.toString();
    const endUnix = parseInt(project._endAt);
    const endDate = new Date(endUnix * 1000);
    formattedEndDate = endDate.toGMTString();
    console.log(
      `Project Created - ID: ${projectId}, name: ${projectName}, owner: ${projectOwner}, targetFund: ${targetFund}, endDate: ${formattedEndDate}`
    );
    return project;
  }

  return null;
};

const transferNFT = async (projectId) => {
  console.log(`Start transferring NFT to funders of Project ${projectId}`);
  // const { funders, amounts } = await crowdfundingContract.getFunders(projectId);
  const results = await crowdfundingContract.getFunders(projectId);
  const funders = results[0];
  const amounts = results[1];

  // Mint NFTs to funders
  for (let i = 0; i < funders.length; i++) {
    const funder = funders[i];
    const amount = amounts[i].toNumber();
    const nftAmount = Math.max(Math.floor(amount), 1);

    const NFT = await ethers.getContractFactory("NFT");
    const NFTDeploy = await NFT.deploy(
      process.env.OWNER_ADDRESS,
      "FTEC Crowdfunding",
      "FTC"
    );
    console.log(
      "NFT Contract created and deployed to address:",
      NFTDeploy.address
    );
    const nftContract = new eth.Contract(NFTDeploy.address, nft.abi, signer);
    await nftContract.safeMint(funder, nftAmount, {
      gasLimit: 3000000,
    });
    console.log(`Minted ${nftAmount} NFT to ${funder}`);
  }
};

const fundProject = async (projectId, fundAmount) => {
  console.log(`Start funding ${fundAmount} to Project ${projectId}`);
  var result = null;
  const options = {
    gasLimit: 3000000,
    value: eth.utils.parseUnits(fundAmount.toString(), "wei"),
  };
  const fundTx = await crowdfundingContract.fund(projectId, {
    ...options,
  });

  const fundReceipt = await fundTx.wait();
  const fundEvent = fundReceipt.events?.find((e) => e.event === "Fund");

  if (fundEvent) {
    console.log("Fund Success");
    result = fundEvent.args;
  }

  const successFundEvent = fundReceipt.events?.find(
    (e) => e.event === "SuccessFund"
  );

  if (successFundEvent) {
    const successProjectId = successFundEvent.args._id.toNumber();
    const raisedFund = successFundEvent.args._raisedFund.toNumber();
    console.log(
      `Project ${successProjectId}: Funding met target amount, raised amount: ${raisedFund} wei`
    );
    result = successFundEvent.args;
    await transferNFT(successProjectId);
  }
  return result;
};

const main = async () => {
  const project = await launchProject(
    (projectName = "project1"),
    (desc = "default desc"),
    (targetFund = 10),
    (startFromNow = 1), // 1s from now
    (duration = 60 * 60 * 24 * 30) // 30 days
  );
  if (project === null) {
    console.log("Fail to launch project");
    return;
  }
  const projectId = parseInt(project._id);
  const fundEvent = await fundProject(projectId, 10);
};

main();
