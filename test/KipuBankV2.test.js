const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("KipuBankV2", function () {
  let KipuBank, kipuBank, deployer, user;

  beforeEach(async () => {
    [deployer, user] = await ethers.getSigners();
    const bankCapUSD = 1000000 * 10**6;
    const ethUsdPriceFeed = "0x694AA1769357215Ef4bE215cd2aa0Ddb242dE17d"; // Sepolia

    KipuBank = await ethers.getContractFactory("KipuBankV2");
    kipuBank = await KipuBank.deploy(bankCapUSD, ethUsdPriceFeed);
    await kipuBank.deployed();
  });

  it("should allow ETH deposit and update balance", async function () {
    const depositAmount = ethers.utils.parseEther("1");
    await kipuBank.connect(user).deposit(ethers.constants.AddressZero, depositAmount, { value: depositAmount });

    const balance = await kipuBank.vaults(user.address, ethers.constants.AddressZero);
    expect(balance).to.equal(depositAmount);
  });
});
