const BarInventory = artifacts.require("BarInventory");

module.exports = function (deployer) {
  deployer.deploy(BarInventory);
};
