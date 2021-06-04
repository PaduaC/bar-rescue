const BarStartup = artifacts.require("BarStartup");

module.exports = function (deployer, _network, accounts) {
  deployer.deploy(BarStartup, "Paddy's Irish Pub", 100000, 86400);
};
