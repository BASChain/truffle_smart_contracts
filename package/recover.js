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

//change envrionment
function changeToGanache(){
    var BasToken_addr = "0xb364EA3A76c3d56c507465dfaa7CfFd3060d68Ed"
    var BasExpiredOwnership_addr = "0xB0Aa973E3BC0Ed9Af3ca52F5C3c8D3626e20Bc4B"
    var BasTradableOwnership_addr = "0xea8B0a79df9F2ED7544a39BD9087A7644FA7f3d7"
    var BasRootDomain_addr = "0x68fc3Eb778fA50A792E2EF3F71400659A74624C3"
    var BasSubDomain_addr = "0x204F8757A376463885001060E4ea7AA0A93A36F6"
    var BasDomainConf_addr = "0x9aA6EBb037f0680DA35623684aF8a5808E1F7108"
    var BasAccountant_addr = "0xFD30a5D95d59397926282d97a4D5DC9A178E0D76"
    var BasMiner_addr = "0x955fE4fBA4d8da3b5E95f92487ed5beE33E26AF5"
    var BasOANN_addr = "0x280841eA3644BbA7Fa6Cf98b95b4A6491323BB25"
    var BasMarket_addr = "0x14FdDc32c7fE6F145E291B0D9751EBc8e82495D8"
    var BasMail_addr = "0x8996DB5C99295FC7D3f9aF3c50577333A9130724"
    var BasMailManager_addr = "0xe62D9A0537AD062B6bd0c5f8c2a0A3648567Fd82"

    //recover contracts
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

}


module.exports = {
    setWeb3: (obj) => {
        module.exports.web3 = obj;
    },
    changeToGanache : changeToGanache,

}