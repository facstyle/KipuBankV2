const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();

  console.log("Deploying contracts with account:", deployer.address);

  const bankCapUSD = 1000000 * 10**6; // $1M en USDC decimals
  const ethUsdPriceFeed = "0x694AA1769357215Ef4bE215cd2aa0Ddb242dE17d"; // Sepolia ETH/USD

  const KipuBankV2 = await hre.ethers.getContractFactory("KipuBankV2");
  const kipuBank = await KipuBankV2.deploy(bankCapUSD, ethUsdPriceFeed);

  await kipuBank.deployed();
  console.log("KipuBankV2 deployed to:", kipuBank.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
