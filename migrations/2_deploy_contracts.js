const BarOwners = artifacts.require("BarOwners");

module.exports = function (deployer, _network, accounts) {
  deployer.deploy(BarOwners, "Paddy's Irish Pub", 100000, 86400);
};
