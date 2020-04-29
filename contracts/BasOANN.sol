pragma solidity >=0.5.0;
//ICANN（The Internet Corporation for Assigned Names and Numbers）
//BOANN（The Blockchain Organizaiton for Assigned Names and Numbers）

import "./BasToken.sol";
import "./BasLib.sol";
import "./BasMiner.sol";
import "./BasDomain.sol";

/*
[DEPLOYED]
this contract manages domain registry and some data change options that costs bas
and keeps all receiptID with profit allocation plan meanwhile
*/
contract BasOANN is ManagedByDAO {
    using SafeMath for uint256;
    
    event PriceSetting(uint256 MAX_YEAR,
                uint256 AROOT_GAS,
                uint256 BROOT_GAS,
                uint256 SUB_GAS,
                uint256 CUSTOMED_PRICE_GAS);
                
    event AllocationSetting(uint256 REG_ROOT_M,
                uint256 REG_SELF_SUB_M,
                uint256 REG_SELF_SUB_O,
                uint256 REG_NORMAL_SUB_M,
                uint256 REG_NORMAL_SUB_O,
                uint256 REG_CUSTOEMED_SUB_M,
                uint256 REG_CUSTOEMED_SUB_O);
    
    event Register(uint receiptID, 
                address payer,
                bytes name,
                uint256 amount,
                bool isRoot,
                bool isRare);
    
    // notice nameHash is indexed            
    event Recharge(uint receiptID, 
                address payer,
                bytes32 indexed nameHash,
                uint256 amount,
                bool isRoot,
                bool isRare);
                
    event OperCustomerPrice(uint receiptID, 
                address payer,
                bytes32 nameHash,
                uint256 amount);
                
    string constant MINER = "miner";
    
    uint256 public MAX_YEAR             ;//= 5
    uint256 public AROOT_GAS            ;//= 2000 * (10**18);
    uint256 public BROOT_GAS            ;//= 200 * (10**18);
    uint256 public SUB_GAS              ;//= 4 * (10**18);
    uint256 public CUSTOMED_PRICE_GAS   ;//= 100 * (10**18);
    uint256 public REG_ROOT_M           ;//= 40;
    uint256 public REG_SELF_SUB_M       ;//= 40;
    uint256 public REG_SELF_SUB_O       ;//= 0;
    uint256 public REG_NORMAL_SUB_M     ;//= 40;
    uint256 public REG_NORMAL_SUB_O     ;//= 20;
    uint256 public REG_CUSTOEMED_SUB_M  ;//= 40;
    uint256 public REG_CUSTOEMED_SUB_O  ;//= 15;
    
    function priceSetting(uint256 max_year,
                        uint256 aroot_gas,
                        uint256 broot_gas,
                        uint256 sub_gas,
                        uint256 customed_price_gas)
                        public
                        OnlyDAO{
            MAX_YEAR                    =   max_year;
            AROOT_GAS                   =   aroot_gas;
            BROOT_GAS                   =   broot_gas;
            SUB_GAS                     =   sub_gas;
            CUSTOMED_PRICE_GAS          =   customed_price_gas;
            
            emit PriceSetting(MAX_YEAR, AROOT_GAS, BROOT_GAS, SUB_GAS, CUSTOMED_PRICE_GAS);
    }
    
    
    function allocationSetting(uint256 reg_root_m,
                        uint256 reg_self_sub_m,
                        uint256 reg_self_sub_o,
                        uint256 reg_normal_sub_m,
                        uint256 reg_normal_sub_o,
                        uint256 reg_customed_sub_m,
                        uint256 reg_customed_sub_o)
                        public
                        OnlyDAO{
                            
            require(reg_root_m <= 100 &&
                    reg_self_sub_m.add(reg_self_sub_o) <= 100 &&
                    reg_normal_sub_m.add(reg_normal_sub_o) <= 100 &&
                    reg_customed_sub_m.add(reg_customed_sub_o) <= 100,
                    "param error");
            
            REG_ROOT_M                  =   reg_root_m;
            REG_SELF_SUB_M              =   reg_self_sub_m;
            REG_SELF_SUB_O              =   reg_self_sub_o;
            REG_NORMAL_SUB_M            =   reg_normal_sub_m;
            REG_NORMAL_SUB_O            =   reg_normal_sub_o;
            REG_CUSTOEMED_SUB_M         =   reg_customed_sub_m;
            REG_CUSTOEMED_SUB_O         =   reg_customed_sub_o;

            
            emit AllocationSetting(REG_ROOT_M, REG_SELF_SUB_M, REG_SELF_SUB_O, 
                        REG_NORMAL_SUB_M, REG_NORMAL_SUB_O,
                        REG_CUSTOEMED_SUB_M, REG_CUSTOEMED_SUB_O);
    }
    
    constructor(address _t,
                address _rd,
                address _sd,
                address _acc) public {
            priceSetting(5, 2000 * (10**18), 200 * (10**18), 4 * (10**18), 100 * (10**18));
            allocationSetting(40, 40, 0, 40, 20, 40, 15);
            
            token           = ERC20(_t);
            accountant      = BasAccountant(_acc);
            rootDomainData  = BasRootDomain(_rd);
            subDomainData   = BasSubDomain(_sd);
    }
    
    uint public             receiptID;
    ERC20 public            token;
    BasAccountant public    accountant;
    BasSubDomain public     subDomainData;
    BasRootDomain public    rootDomainData;
    
    
    modifier validDuration(uint8 y)  {
        require (y <= MAX_YEAR && y > 0);
        _;
    }
    
    function setupDataRef(address _t,
                    address _rd,
                    address _sd,
                    address _acc)
                    public 
                    OnlyDAO{
        
        token           = ERC20(_t);
        accountant      = BasAccountant(_acc);
        rootDomainData  = BasRootDomain(_rd);
        subDomainData   = BasSubDomain(_sd);
    }
    
    
    /*
    this profit allocation is for root domain options
    */
    function _allocateProfit_m(uint256 share_m, 
                        uint cost) 
                        internal{
        if (share_m > 0){
            accountant.allocateProfit(accountant.contractReceivers(MINER), cost.mul(share_m).div(100));
        }
    }
    
    /*
    this profit allocation is for sub domain options
    */
    function _allocateProfit_m_o(uint256 share_m,
                        uint256 share_o,
                        uint cost,
                        address domainOwner) 
                        internal{
        if (share_m > 0){
            accountant.allocateProfit(accountant.contractReceivers(MINER), cost.mul(share_m).div(100));
        }
        if (domainOwner != address(0) && share_o > 0){
            accountant.allocateProfit(domainOwner, cost.mul(share_o).div(100));
        }
    }
    
    
    /*
    when register a root, there are some checks and some changes about storage,
    first, validity of characters are checked here, so is rareness,
    then the cost is sumed and token transfered to miners
    then the domain contract decide if this registry is new or takeover
    lastly the ownership record the new expiration date 
    */
    function registerRoot(bytes calldata name,
                    bool isOpen,
                    bool isCustomed,
                    uint256 cusPrice,
                    uint8 durationInYear)
                    external
                    validDuration(durationInYear){
        
        (bool isValid, bool isRare) = rootDomainData.classifyRoot(name);
        require(isValid, "invalid domain name");

        uint256 cost;
        if (isRare) {
            cost = AROOT_GAS.mul(durationInYear);
        } else {
            cost = BROOT_GAS.mul(durationInYear);
        }

        if (isCustomed) {
            require(isRare, "only rare root domain is allowed to customerlize sub domain price");
            require(cusPrice >= SUB_GAS, "can't be lower than system price");
            cost = cost.add(CUSTOMED_PRICE_GAS);
        }
        
        token.transferFrom(msg.sender, address(accountant), cost);
        
        rootDomainData.replaceOrCreate(name, now.add(durationInYear * 365 days), isOpen, isCustomed, cusPrice, msg.sender);
        
        _allocateProfit_m(REG_ROOT_M, cost);
        
        emit Register(receiptID++, msg.sender, name, cost, true, isRare);
    }

    /*
    any one can recharge an existing domain
    */
    function rechargeRoot(bytes32 nameHash,
                    uint8 durationInYear)
                    external
                    validDuration(durationInYear){

        require(rootDomainData.hasDomain(nameHash), "domain not exist");
        (, bool isRare) = rootDomainData.classifyRoot(nameHash);
        
        uint256 cost;
        if (isRare){
            cost = AROOT_GAS.mul(durationInYear);
        }else{
            cost = BROOT_GAS.mul(durationInYear);
        }
        
        token.transferFrom(msg.sender, address(accountant), cost);
        
        rootDomainData.recharge(nameHash, durationInYear * 365 days, now.add(MAX_YEAR * 365 days));
        
        _allocateProfit_m(REG_ROOT_M, cost);
        
        emit Recharge(receiptID++, msg.sender, nameHash, cost, true, isRare);
    }

    /*
    each time user want to change price, it should pay some token
    to prevent from constantly changes
    */
    function openCustomedPrice(bytes32 nameHash,
                            uint256 price)
                            external{

        require(price > SUB_GAS, "can't set price lower than default");
        
        token.transferFrom(msg.sender, address(accountant), CUSTOMED_PRICE_GAS);
        
        _allocateProfit_m(REG_ROOT_M, CUSTOMED_PRICE_GAS);
        
        rootDomainData.openCustomedPrice(nameHash, price, msg.sender);

        emit OperCustomerPrice(receiptID++, msg.sender, nameHash, CUSTOMED_PRICE_GAS);
    }

    /*
    registering sub domain takes more steps than root,
    if we are registering a subdomain of an existing root, we can skip the root validity check
    otherwise we should perform a full check
    second, based on existence and openness and account address, decide if able to register
    then sum cost and transfer token
    */
    function registerSub(bytes calldata rName,
                    bytes calldata sName,
                    uint8 durationInYear)
                    external
                    validDuration(durationInYear){
        
        require(subDomainData.verifySub(sName), "subname not valid");
        bytes32 rootHash = BasHash.Hash(rName);
        bool isOpen;
        bool isCustomed;
        uint256 customedPrice;
        address rootOwner;
        bool rootExist = rootDomainData.hasDomain(rootHash);
        if (rootExist){
            (,isOpen, isCustomed, customedPrice) = rootDomainData.Root(rootHash);
            rootOwner = rootDomainData.ownership().ownerOf(rootHash);
            require(isOpen || msg.sender == rootOwner, "root disallow registry");
        }else{
            require(rootDomainData.verifyRoot(rName),"root not valid");
        }
        uint256 cost = _decideCostAndDeliverToken(isCustomed, msg.sender == rootOwner, customedPrice, durationInYear, rootOwner);
        bytes memory totalName = abi.encodePacked(sName, ".", rName);

        subDomainData.replaceOrCreate(totalName, rootHash, now.add((durationInYear * 365 days)), msg.sender);
        
        emit Register(receiptID++, msg.sender, totalName, cost, false, false);
    }
    
    
    /*
    in most case, we should not check root validity again, but in case root of rareness changes,
    recheck is needed, 
    */
    function rechargeSub(bytes calldata rName,
                    bytes calldata sName,
                    uint8 durationInYear)
                    external
                    validDuration(durationInYear){
        
        bytes32 nameHash = BasHash.Hash(abi.encodePacked(sName, ".", rName));
        bytes32 rootHash = BasHash.Hash(rName);
        require(subDomainData.hasDomain(nameHash), "domain not exist");
        
        (,, bool isCustomed, uint256 customedPrice) = rootDomainData.Root(rootHash);
        address rootOwner = rootDomainData.ownership().ownerOf(rootHash);
        
        uint256 cost = _decideCostAndDeliverToken(isCustomed, msg.sender == rootOwner, customedPrice, durationInYear, rootOwner);
        
        subDomainData.recharge(nameHash, durationInYear * 365 days, now.add(MAX_YEAR * 365 days));
        
        emit Recharge(receiptID++, msg.sender, nameHash, cost, false, false);
    }
    
    function _decideCostAndDeliverToken(bool isCustomed,
                                    bool isSelf,
                                    uint256 customedPrice,
                                    uint8 durationInYear,
                                    address rootOwner)
                            internal
                            returns (uint256 cost){
                                
        if (isCustomed){
            
            cost = customedPrice.mul(durationInYear);
            _allocateProfit_m_o(REG_CUSTOEMED_SUB_M, REG_CUSTOEMED_SUB_O, cost, rootOwner);
            
        } else{
            cost = SUB_GAS.mul(durationInYear);
            _allocateProfit_m_o(REG_NORMAL_SUB_M, REG_NORMAL_SUB_O, cost, rootOwner);
        }
        
        if (isSelf){
            _allocateProfit_m_o(REG_SELF_SUB_M, REG_SELF_SUB_O, cost, rootOwner);
        }
        
        token.transferFrom(msg.sender, address(accountant), cost);

    }
}
