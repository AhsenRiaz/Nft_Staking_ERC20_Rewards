import { ethers } from "hardhat";

async function main() {
  const _ = await ethers.getContractFactory("");
  const __ = await _.deploy();

  await __.deployed();

  console.log("address", __.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
