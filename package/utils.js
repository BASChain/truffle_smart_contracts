var recover = require("./recover.js");

module.exports = {
    ASCII : (str)=>{
        if(str.length==0){
            return "0x00"
        }else{
            return str.split("").map(e=>e.charCodeAt()).reduce((a,b)=>a+b.toString(16),"0x");
        }
    },

    ToString : (ascii)=>{
        charCode = [];
        for (i=2;i<ascii.length-1;i+=2){
            charCode.push("0x"+ascii[i]+ascii[i+1]);
        }
        return charCode.map((e)=>String.fromCharCode(e)).reduce((a,b)=>a+b);
    },

    Hash : (str)=>{
        return recover.web3.utils.keccak256(str);
    },

    IPv4ToHex :(ip)=>{
        if (ip==""){
            return "0x00000000";
        }
        var slices = ip.split(".");
        if (slices.length!=4){
            throw new Error("not a valid ipv4 address");
        }
        var convert = (slices.map(element => {
            if(isNaN(element)||element<0 || element>255){
                throw new Error("not a valid ipv4 address");
            }else{
                var temp = parseInt(element).toString(16);
                temp = temp.length==1?"0"+temp:temp;
                return temp;
            }
        })).join("");
        return "0x"+convert;
    },

    IPv6ToHex : (ip)=>{
        if(ip==""){
            return "0x00000000000000000000000000000000";
        }
        var striped = ip.replace(/:/g,"");
        if (striped!=striped.match(/^[0-9a-fA-F]{32}$/g)[0]){
            throw new Error("not a valid ipv6 address / shorted version not allowed");
        }else{
            return "0x"+striped;
        }
    },
}