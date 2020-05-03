//this file is for copy paste on node common line for test

var Web3 = require('web3');
var recover = require("./recover.js");
var utils = require("./utils.js");
var accounts = require("./ganache_accounts.json");
var address = require("./ganache_address.json");
var web3 = new Web3('http://127.0.0.1:7545');


recover.setWeb3(web3);
recover.changeToGanache(address);

var admin = accounts[0];

//get balance and approve OANN
recover.BasToken.methods.balanceOf(admin)
                        .call().then((balance)=>{
                            console.log("balance is : ", balance);
                            recover.BasToken.methods.approve(recover.BasOANN._address,balance)
                            .send({from : admin})
                            .then(()=>{
                                recover.BasToken.methods.allowance(admin, recover.BasOANN._address)
                                                        .call()
                                                        .then((d)=>{
                                                            console.log("allowance to OANN is :",d);
                                                        });
                            });
                        })




// //check if the root domain can be registered
recover.BasView.methods.checkRootRegistry(
    utils.ASCII("sunzy"),
    "4000000000000000000",
    1
).call().then((result)=>{
    console.log(result);
})

//
// if no error
recover.BasOANN.methods.registerRoot(utils.ASCII("sunzy"),false,false,"4000000000000000000",1).send({from : admin}).then(console.log);