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
const BasView = artifacts.require("BasView");

const fs = require("fs");

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
            conf = instance;
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
            return deployer.deploy(BasView);
        }).then(function(instance){
            view = instance;

//----link sequence----

            view.setAddresses(
                t.address,
                exo.address,
                tro.address,
                rd.address,
                sd.address,
                conf.address,
                acc.address,
                m.address,
                oann.address,
                market.address,
                mail.address,
                mm.address
            )
            
            
            tro.addDataKeeper(rd.address);
            tro.addDataKeeper(sd.address);
            tro.addDataKeeper(market.address);
            rd.addDataKeeper(oann.address);
            sd.addDataKeeper(oann.address);
            acc.addDataKeeper(oann.address);
            acc.addDataKeeper(mm.address);
            acc.registerContractReceiver("miner",m.address);
            m.addDataKeeper(acc.address);
            mail.addDataKeeper(mm.address);
            exo.addDataKeeper(mail.address);
        }).then(function(){
//-----create ganache address files for debug purpose

            let addresses = {
                BasToken_addr                   : t.address,
                BasExpiredOwnership_addr        : exo.address,
                BasTradableOwnership_addr       : tro.address,
                BasRootDomain_addr              : rd.address,
                BasSubDomain_addr               : sd.address,
                BasDomainConf_addr              : conf.address,
                BasAccountant_addr              : acc.address,
                BasMiner_addr                   : m.address,
                BasOANN_addr                    : oann.address,
                BasMarket_addr                  : market.addrrss,
                BasMail_addr                    : mail.address,
                BasMailManager_addr             : mm.address,
                BasView_addr                    : view.address,
            }
            
            fs.writeFile('package/ganache_address.json',JSON.stringify(addresses),function(err){
                if (err) {console.log(err)}
            });

//-----write accounts-------
            fs.writeFile('package/ganache_accounts.json',JSON.stringify(accounts),function(err){
                if (err) {console.log(err)}
            });

//------generate abi files to traget path
            const BasToken_abi = require("../build/contracts/BasToken.json").abi;
            fs.writeFile('package/abi/BasToken.json',JSON.stringify(BasToken_abi),function(err){
                if (err) {console.log(err)}
            });

            const BasExpiredOwnership_abi = require("../build/contracts/BasExpiredOwnership.json").abi;
            fs.writeFile('package/abi/BasExpiredOwnership.json',JSON.stringify(BasExpiredOwnership_abi),function(err){
                if (err) {console.log(err)}
            });

            const BasTradableOwnership_abi = require("../build/contracts/BasTradableOwnership.json").abi;
            fs.writeFile('package/abi/BasTradableOwnership.json',JSON.stringify(BasTradableOwnership_abi),function(err){
                if (err) {console.log(err)}
            });

            const BasRootDomain_abi = require("../build/contracts/BasRootDomain.json").abi;
            fs.writeFile('package/abi/BasRootDomain.json',JSON.stringify(BasRootDomain_abi),function(err){
                if (err) {console.log(err)}
            });

            const BasSubDomain_abi = require("../build/contracts/BasSubDomain.json").abi;
            fs.writeFile('package/abi/BasSubDomain.json',JSON.stringify(BasSubDomain_abi),function(err){
                if (err) {console.log(err)}
            });
            
            const BasDomainConf_abi = require("../build/contracts/BasDomainConf.json").abi;
            fs.writeFile('package/abi/BasDomainConf.json',JSON.stringify(BasDomainConf_abi),function(err){
                if (err) {console.log(err)}
            });

            const BasAccountant_abi = require("../build/contracts/BasAccountant.json").abi;
            fs.writeFile('package/abi/BasAccountant.json',JSON.stringify(BasAccountant_abi),function(err){
                if (err) {console.log(err)}
            });
            
            const BasMiner_abi = require("../build/contracts/BasMiner.json").abi;
            fs.writeFile('package/abi/BasMiner.json',JSON.stringify(BasMiner_abi),function(err){
                if (err) {console.log(err)}
            });

            const BasOANN_abi = require("../build/contracts/BasOANN.json").abi;
            fs.writeFile('package/abi/BasOANN.json',JSON.stringify(BasOANN_abi),function(err){
                if (err) {console.log(err)}
            });

            const BasMarket_abi = require("../build/contracts/BasMarket.json").abi;
            fs.writeFile('package/abi/BasMarket.json',JSON.stringify(BasMarket_abi),function(err){
                if (err) {console.log(err)}
            });

            const BasMail_abi = require("../build/contracts/BasMail.json").abi;
            fs.writeFile('package/abi/BasMail.json',JSON.stringify(BasMail_abi),function(err){
                if (err) {console.log(err)}
            });
            
            const BasMailManager_abi = require("../build/contracts/BasMailManager.json").abi;
            fs.writeFile('package/abi/BasMailManager.json',JSON.stringify(BasMailManager_abi),function(err){
                if (err) {console.log(err)}
            });

            const BasView_abi = require("../build/contracts/BasView.json").abi;
            fs.writeFile('package/abi/BasView.json',JSON.stringify(BasView_abi),function(err){
                if (err) {console.log(err)}
            });
            
        })
}
