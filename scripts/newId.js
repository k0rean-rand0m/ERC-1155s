// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {

  const signer = (await hre.ethers.getSigners())[0];

  const Mock1155s =  await hre.ethers.getContractFactory("Mock1155s");
  const m1155s = await Mock1155s.attach("0x25d4a73b44ba47f515238b48e05dd0e29e76ad29");

  // ID 3
  await (await m1155s.newId(false, "", "")).wait();
  await (await m1155s.mint(signer.address, 3, 500, [])).wait();

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
