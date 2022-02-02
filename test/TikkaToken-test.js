const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Cube TikkaToken tests", function () {
  let tikkaToken;
  let owner;

  beforeEach(async function () {
    const TikkaToken = await ethers.getContractFactory("TikkaToken");
    tikkaToken = await TikkaToken.deploy();
    await tikkaToken.deployed();

    [owner, acc1] = await ethers.getSigners();
  });

  it("Should deploy TikkaToken Token", async function () {
    console.log("Pass!!")
  });
});
