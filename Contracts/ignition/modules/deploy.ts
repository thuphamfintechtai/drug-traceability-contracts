// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";


const deployedContract = buildModule("DeployModule", (m) => {
  // Deploy Access Control Contract First
  const accessControlContract = m.contract("accessControlService")

  const myNFTContract = m.contract("MyNFT" , [accessControlContract])
  return { accessControlContract , myNFTContract }
});

export default deployedContract;
