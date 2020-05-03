pragma solidity >=0.5.0;

import "./BasToken.sol";
import "./BasOwnership.sol";
import "./BasDomain.sol";
import "./BasOANN.sol";
import "./BasMail.sol";
import "./BasMarket.sol";
import "./BasLib.sol";


contract BasView is ManagedByDAO{
    
    using SafeMath for uint256;
    
    ERC20 public                    token;
    BasExpiredOwnership public      exo;
    BasTradableOwnership public     tro;
    BasRootDomain public            root;
    BasSubDomain public             sub;
    BasDomainConf public            conf;
    BasAccountant public            acc;
    BasMiner public                 miner;
    BasOANN public                  oann;
    BasMarket public                market;
    BasMail public                  mail;
    BasMailManager public           mm;
    
    
    function setAddresses(address token_addr,
                        address exo_addr,
                        address tro_addr,
                        address root_addr,
                        address sub_addr,
                        address conf_addr,
                        address acc_addr,
                        address miner_addr,
                        address oann_addr,
                        address market_addr,
                        address mail_addr,
                        address mm_addr)
                        external
                        OnlyDAO{
            token = ERC20(token_addr);
            exo = BasExpiredOwnership(exo_addr);
            tro = BasTradableOwnership(tro_addr);
            root = BasRootDomain(root_addr);
            sub = BasSubDomain(sub_addr);
            conf = BasDomainConf(conf_addr);
            acc = BasAccountant(acc_addr);
            miner = BasMiner(miner_addr);
            oann = BasOANN(oann_addr);
            market = BasMarket(market_addr);
            mail = BasMail(mail_addr);
            mm = BasMailManager(mm_addr);
    }
    
    function getOANNParams() external view returns(
            uint256 MAX_YEAR,
            uint256 AROOT_GAS,
            uint256 BROOT_GAS,
            uint256 SUB_GAS,
            uint256 CUSTOMED_PRICE_GAS){
            MAX_YEAR = oann.MAX_YEAR();
            AROOT_GAS = oann.AROOT_GAS();
            BROOT_GAS = oann.BROOT_GAS();
            SUB_GAS = oann.SUB_GAS();
            CUSTOMED_PRICE_GAS = oann.CUSTOMED_PRICE_GAS();
    }
    
    mapping(uint8 => string) public ErrorCode;
    
    //set initial error code
    constructor() public {
        
        ErrorCode[0]  = "no error";
        
        //this covers domain registry
        ErrorCode[1]  = "invalid string";
        ErrorCode[2]  = "domain is taken";
        ErrorCode[3]  = "invalid expiration";
        ErrorCode[4]  = "customed price below default";
    }
    
    
    function setErrorCode(uint8 index, 
                        string calldata reason) 
                        external
                        OnlyDAO{
        ErrorCode[index] = reason;
    }
    
    // this function checks is root domain can be registed, return detail and error code if necessary
    function checkRootRegistry(bytes calldata name,
                            uint256 cusPrice,
                            uint8 durationInYear)
                            external
                            view
                            returns(uint8, 
                                    bool,
                                    uint256){
            (bool isValid, bool isRare) = root.classifyRoot(name);
            uint256 cost;
            if(!isValid){
                return (1, isRare, cost);
            }
            
            if(durationInYear > 5){
                return (3, isRare, cost);
            }
            if(cusPrice < oann.SUB_GAS()){
                return (4, isRare, cost);
            }
            (address oldOwner, uint oldExpire) = tro.ownerOfWithExpire(BasHash.Hash(name));
            if(oldOwner != address(0) && oldExpire >= now){
                return (2, isRare, cost);
            }
            if (isRare) {
                cost = oann.AROOT_GAS().mul(durationInYear);
            } else {
                cost = oann.BROOT_GAS().mul(durationInYear);
            }
            return (0, isRare, cost);
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
}
