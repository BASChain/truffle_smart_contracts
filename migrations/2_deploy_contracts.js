const BasToken = artifacts.require("BasToken");
const BasExpiredOwnership = artifacts.require("BasExpiredOwnership");
const BasTradableOwnership = artifacts.require("BasTradableOwnership");
const BasRootDomain = artifacts.require("BasRootDomain");
const BasSubDomain = artifacts.require("BasSubDomain");
const BasDomainConf = artifacts.require("BasDomainConf");
const BasAccountant = artifacts.require("BasAccountant");
const BasMiner = artifacts.require("BasMiner");
const BasOANN = artifacts.require("BasOANN");
const BasMarket = artifacts.require("BasMarket");
const BasMail = artifacts.require("BasMail");
const BasMailManager = artifacts.require("BasMailManager");


module.exports = function(deployer, network, accounts){

//----deploy sequence----
  deployer.deploy(BasToken)
          .then(function(instance){
            t = instance;
            return deployer.deploy(BasExpiredOwnership, "mail");
        }).then(function(instance){
            exo = instance;
            return deployer.deploy(BasTradableOwnership, "domain");
        }).then(function(instance){
            tro = instance;
            return deployer.deploy(BasRootDomain, tro.address);
        }).then(function(instance){
            rd = instance;
            return deployer.deploy(BasSubDomain, tro.address);
        }).then(function(instance){
            sd = instance;
            return deployer.deploy(BasDomainConf, tro.address);
        }).then(function(instance){
            dc = instance;
            return deployer.deploy(BasAccountant);
        }).then(function(instance){
            acc = instance;
            return deployer.deploy(BasMiner, t.address, acc.address);
        }).then(function(instance){
            m = instance;
            return deployer.deploy(BasOANN, t.address, rd.address, sd.address, acc.address);
        }).then(function(instance){
            oann = instance;
            return deployer.deploy(BasMarket, t.address, rd.address, sd.address);
        }).then(function(instance){
            market = instance;
            return deployer.deploy(BasMail, exo.address);
        }).then(function(instance){
            mail = instance;
            return deployer.deploy(BasMailManager, t.address, acc.address, rd.address,
               sd.address, mail.address);
        }).then(function(instance){
            mm = instance;
//----link sequence----
            tro.addDataKeeper(rd.address);
            tro.addDataKeeper(sd.address);
            tro.addDataKeeper(market.address);
            acc.addDataKeeper(oann.address);
            acc.addDataKeeper(mm.address);
            m.addDataKeeper(acc.address);
            mail.addDataKeeper(mm.address);
            exo.addDataKeeper(mail.address);
        })
}
