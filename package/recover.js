//contract abi
const BasToken_abi = require("./abi/BasToken.json");
const BasExpiredOwnership_abi = require("./abi/BasExpiredOwnership.json");
const BasTradableOwnership_abi = require("./abi/BasTradableOwnership.json");
const BasRootDomain_abi = require("./abi/BasRootDomain.json");
const BasSubDomain_abi = require("./abi/BasSubDomain.json");
const BasDomainConf_abi = require("./abi/BasDomainConf.json");
const BasAccountant_abi = require("./abi/BasAccountant.json");
const BasMiner_abi = require("./abi/BasMiner.json");
const BasOANN_abi = require("./abi/BasOANN.json");
const BasMarket_abi = require("./abi/BasMarket.json");
const BasMail_abi = require("./abi/BasMail.json");
const BasMailManager_abi = require("./abi/BasMailManager.json");
const BasView_abi = require("./abi/BasView.json");

var BasToken_addr;
var BasExpiredOwnership_addr;
var BasTradableOwnership_addr;
var BasRootDomain_addr;
var BasSubDomain_addr;
var BasDomainConf_addr;
var BasAccountant_addr;
var BasMiner_addr;
var BasOANN_addr;
var BasMarket_addr;
var BasMail_addr;
var BasMailManager_addr;

//this function is just for debugging with ganache
function changeToGanache(addressObj){
    BasToken_addr = addressObj.BasToken_addr;
    BasExpiredOwnership_addr = addressObj.BasExpiredOwnership_addr;
    BasTradableOwnership_addr = addressObj.BasTradableOwnership_addr;
    BasRootDomain_addr = addressObj.BasRootDomain_addr;
    BasSubDomain_addr = addressObj.BasSubDomain_addr;
    BasDomainConf_addr = addressObj.BasDomainConf_addr;
    BasAccountant_addr = addressObj.BasAccountant_addr;
    BasMiner_addr = addressObj.BasMiner_addr;
    BasOANN_addr = addressObj.BasOANN_addr;
    BasMarket_addr = addressObj.BasMarket_addr;
    BasMail_addr = addressObj.BasMail_addr;
    BasMailManager_addr = addressObj.BasMailManager_addr;
    BasView_addr = addressObj.BasView_addr;

    recoverContracts();
}

function recoverContracts(){
    module.exports.BasToken = new module.exports.web3.eth.Contract(BasToken_abi, BasToken_addr);
    module.exports.BasExpiredOwnership = new module.exports.web3.eth.Contract(BasExpiredOwnership_abi, BasExpiredOwnership_addr);
    module.exports.BasTradableOwnership = new module.exports.web3.eth.Contract(BasTradableOwnership_abi, BasTradableOwnership_addr);
    module.exports.BasRootDomain = new module.exports.web3.eth.Contract(BasRootDomain_abi, BasRootDomain_addr);
    module.exports.BasSubDomain = new module.exports.web3.eth.Contract(BasSubDomain_abi, BasSubDomain_addr);
    module.exports.BasDomainConf = new module.exports.web3.eth.Contract(BasDomainConf_abi, BasDomainConf_addr);
    module.exports.BasAccountant = new module.exports.web3.eth.Contract(BasAccountant_abi, BasAccountant_addr);
    module.exports.BasMiner = new module.exports.web3.eth.Contract(BasMiner_abi, BasMiner_addr);
    module.exports.BasOANN = new module.exports.web3.eth.Contract(BasOANN_abi, BasOANN_addr);
    module.exports.BasMarket = new module.exports.web3.eth.Contract(BasMarket_abi, BasMarket_addr);
    module.exports.BasMail = new module.exports.web3.eth.Contract(BasMiner_abi, BasMail_addr);
    module.exports.BasMailManager = new module.exports.web3.eth.Contract(BasMailManager_abi, BasMailManager_addr);
    module.exports.BasView = new module.exports.web3.eth.Contract(BasView_abi, BasView_addr);
}

module.exports = {
    setWeb3: (obj) => {
        module.exports.web3 = obj;
    },
    setAccount: (account) => {
        module.exports.account = account;
    },
    changeToGanache : changeToGanache,

}