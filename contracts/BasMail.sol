pragma solidity >=0.5.0;

import "./BasDomain.sol";
import "./BasOwnership.sol";
import "./BasToken.sol";
import "./BasMiner.sol";
import "./BasLib.sol";

/*
[DEPLOYED]
this contract keeps mail data
*/
contract BasMail is ManagedByOwner, ManagedByContract{
    
    /*
    we keep mailHash rather than mail string
    to prevent mail address crawler aquiring all mails
    */
    struct MailRecord {
        bytes32     domainHash;
        bytes32     mailHash;
        bool        valid;
        bytes       aliasName;
        bytes       bcAddress;
    }
    
    event NewMail(bytes32 domainHash,
                bytes32 nameHash,
                address owner);
    event MailUpdate(bytes32 domainHash,
                    bytes aliasName,
                    bytes bcAddress);
    event AbandMail(bytes32 domainHash);
    event MailRecharged(bytes32 domainHash,
                    uint extendTime);
                    
    constructor(address _os) public{
        ownership = BasExpiredOwnership(_os);
    }
    
    mapping(bytes32 => MailRecord) public _mailrecords;
    
    modifier OnlyAlive(bytes32 hash){
        require(_mailrecords[hash].valid, "the mail address has been abandoned");
        _;
    }

    function domainHashOf(bytes32 mailHash) 
                    view 
                    external 
                    returns(bytes32){
        return _mailrecords[mailHash].domainHash;
    }
    
    function updateMail(bytes32 mailHash,
                        bytes calldata aliasName,
                        bytes calldata bcAddress)
                        OnlyOwner(msg.sender, mailHash)
                        OnlyAlive(mailHash)
                        external{

        _mailrecords[mailHash].aliasName = aliasName;
        _mailrecords[mailHash].bcAddress = bcAddress;

        emit MailUpdate(mailHash, aliasName, bcAddress);
    }
    
    function newEmail(bytes32 domainHash,
                    bytes32 mailHash,
                    address owner,
                    uint expire)
                    external 
                    OnlyDataKeeper{
        
        require(_mailrecords[mailHash].domainHash == bytes32(0), "email has been registered");
        
        ownership.newOwnership(mailHash, owner, expire);
        
        _mailrecords[mailHash] = MailRecord(domainHash, mailHash, true, '', '');
        
        emit NewMail(domainHash, mailHash, owner);
    }
    
    function recharge(bytes32 mailHash,
                    uint extendTime)
                    external
                    OnlyAlive(mailHash) 
                    OnlyDataKeeper{
                        
        require(ownership.ownerOf(mailHash) != address(0), "no such email ownership");
        
        ownership.extendTime(mailHash, extendTime);
        
        emit MailRecharged(mailHash, extendTime);
    }
    
    /*
    we don't simply delete mail data, because there is a chance the mail is re-registered
    which may cause secure problem
    */
    function abandon(bytes32 hash)
                OnlyOwner(msg.sender, hash)
                external{
        
        _mailrecords[hash].valid = false;
        
        _mailrecords[hash].aliasName = "";
        _mailrecords[hash].bcAddress = "";
        
        emit AbandMail(hash);
    }
}

/*
[DEPLOYED]
this contract manages mail registry and mail admin options
*/
contract BasMailManager is ManagedByDAO{
    using SafeMath for uint256;
    
    
    event PriceSetting(uint256 MAX_MAIL_YEAR,
                    uint256 OPEN_ACTION_GAS,
                    uint256 REG_MAIL_GAS);
    
    event AllocationSetting(uint256 BASIC_M,
                            uint256 TOP_DOMAIN_M,
                            uint256 TOP_DOMAIN_O);
    
    event MailServerOpen(uint256 receiptID,
                address payer, 
                bytes32 domainHash, 
                uint256 cost);
                        
    event MailServerRemoved(address owner,
                            bytes32 mailHash);
    event MailServerCloseToPublic(address owner,
                            bytes32 mailHash);
    event MailServerOpenToPublic(address owner,
                            bytes32 mailHash);
    event MailServerAdminChanged(address owner,
                            bytes32 mailHash);
    
    event Register(uint receiptID,
                address payer, 
                bytes32 domainHash, 
                uint cost);
                
    event Recharge(uint receiptID,
                address payer, 
                bytes32 mailHash,
                uint cost);
                
    string constant MINER = "miner";
    
    uint256 public MAX_MAIL_YEAR        = 5;
    uint256 public OPEN_ACTION_GAS      = 100 * (10 ** 18);
    uint256 public REG_MAIL_GAS         = 2 * (10 ** 18);
    uint256 public BASIC_M              = 40;
    uint256 public TOP_DOMAIN_M         = 40;
    uint256 public TOP_DOMAIN_O         = 20;
    
    function priceSetting(uint256 max_mail_year,
                        uint256 open_action_gas,
                        uint256 reg_mail_gas)
                        public
                        OnlyDAO{
                MAX_MAIL_YEAR           = max_mail_year;
                OPEN_ACTION_GAS         = open_action_gas;
                REG_MAIL_GAS            = reg_mail_gas;
                
                emit PriceSetting(max_mail_year, open_action_gas, reg_mail_gas);
    }
    
    function allocationSetting(uint256 basic_m,
                            uint256 top_domain_m,
                            uint256 top_domain_o)
                            public
                            OnlyDAO{
                                
                require(basic_m <= 100 &&
                        top_domain_m.add(top_domain_o) <= 100,
                        "param error");
                BASIC_M                 = basic_m;
                TOP_DOMAIN_M            = top_domain_m;
                TOP_DOMAIN_O            = top_domain_o;
                
                emit AllocationSetting (basic_m, top_domain_m, top_domain_o);
    }
    
    struct MainServiceConf{
        bool    active;
        bool    openToPublic;
    }
    
    ERC20 public            token;
    uint public             receiptID;
    BasAccountant public    accountant;
    BasMail public          mailData;
    BasSubDomain public     subDomainData;
    BasRootDomain public    rootDomainData;
    
    mapping(bytes32 => MainServiceConf) public    mailConfigs;
    mapping(address => address)         public    adminOfOwner;

    constructor(address _t,
                address _acc,
                address _rd,
                address _sd,
                address _mail)
                public{
        token           = ERC20(_t);
        accountant      = BasAccountant(_acc);
        mailData        = BasMail(_mail);
        rootDomainData  = BasRootDomain(_rd);
        subDomainData   = BasSubDomain(_sd);
    }
    
    function setupDataRef(address _t, 
                address _acc, 
                address _rd,  
                address _sd, 
                address _mail) 
                external
                OnlyDAO{
        token           = ERC20(_t);
        accountant      = BasAccountant(_acc);
        mailData        = BasMail(_mail);
        rootDomainData  = BasRootDomain(_rd);
        subDomainData   = BasSubDomain(_sd);
    }
    
    modifier ValidEmailDuration(uint8 durationInYear){
        require(durationInYear > 0 && 
                durationInYear <= MAX_MAIL_YEAR, 
                "Invalid email duration");
        _;
    }
    
    /*
    actually the ownership behind hasDomain call will be the same
    */
    modifier DomainValid(bytes32 domainHash){
        require(rootDomainData.hasDomain(domainHash)
                ||subDomainData.hasDomain(domainHash), 
                "no such domain name");
        _;
    }
    
    modifier OnlyDomainOwner(bytes32 domainHash){
        require(rootDomainData.domainIsValid(msg.sender, domainHash)
                || subDomainData.domainIsValid(msg.sender, domainHash),
                "only domain valid");
        _;
    }
    
    modifier MailServiceOpened(bytes32 domainHash){
        require(mailConfigs[domainHash].active, "no such domain service config");
        _;
    }
    

    /*
    all domains can open Mail service
    but only rare root domain can open to public
    */
    function openMailService(bytes32 domainHash,
                            bool openToPublic)
                        OnlyDomainOwner(domainHash)
                        DomainValid(domainHash)
                        external{
        
        require(mailConfigs[domainHash].active == false, "opened already"); 
        token.transferFrom(msg.sender, address(accountant), OPEN_ACTION_GAS);
        
        if (openToPublic){
            require(rootDomainData.isRare(domainHash), 
                "Only top root domain can be used for public email user");
        }
        
        mailConfigs[domainHash] = MainServiceConf(true, openToPublic);
        
        accountant.allocateProfit(accountant.contractReceivers(MINER), OPEN_ACTION_GAS.mul(BASIC_M).div(100));
        
        emit MailServerOpen(receiptID++, msg.sender, domainHash, OPEN_ACTION_GAS);
    }


    function removeMailServer(bytes32 domainHash)
                        MailServiceOpened(domainHash)
                        OnlyDomainOwner(domainHash) external{

        delete mailConfigs[domainHash];
        
        emit MailServerRemoved(msg.sender, domainHash);
    }

    /*
    skip is rare check
    */
    function closeToPublic(bytes32 domainHash)
                        MailServiceOpened(domainHash)
                        OnlyDomainOwner(domainHash) external{

        mailConfigs[domainHash].openToPublic = false;
        
        emit MailServerCloseToPublic(msg.sender, domainHash);
    }

    /*
    can insert freely
    but only domain owner will be used
    */    
    function setAdmin(address admin)
                external{
        adminOfOwner[msg.sender] = admin;
    }

    /*
    only rare root domain can open to public
    */
    function openToPublic(bytes32 domainHash)
                        MailServiceOpened(domainHash)
                        OnlyDomainOwner(domainHash) external{
        
        MainServiceConf storage conf = mailConfigs[domainHash];
        
        require(rootDomainData.isRare(domainHash), 
                "Only top root domain can be used for public email user");
        
        conf.openToPublic = true;

        emit MailServerOpenToPublic(msg.sender, domainHash);
    }
    
    /*
    there are generally two type of mail domain
    1. rare root domain, user can register mail when domain is open to public
    2. other domain, only domain user or domain admin can register mail
    */
    function registerMail(bytes32 domainHash,
                         bytes32 mailhash,
                        uint8 durationInYear)
                        ValidEmailDuration(durationInYear)
                        external{
        
        MainServiceConf memory conf = mailConfigs[domainHash];
        require(conf.active, "domain hasn't open to email register");
        
        
        //actually rootDomainData and subDomainData shares the same owner contract
        address domainOwner;
        if (rootDomainData.isRare(domainHash)){
            domainOwner = rootDomainData.getValidOwner(domainHash);
            require(conf.openToPublic, "not open to public");
        }else{
            domainOwner = subDomainData.getValidOwner(domainHash);
            require(msg.sender == domainOwner || msg.sender == adminOfOwner[msg.sender],
                    "only owner or admin can register");
        }
        
        uint cost = REG_MAIL_GAS.mul(durationInYear);
        
        token.transferFrom(msg.sender, address(accountant), cost);
        
        mailData.newEmail(domainHash, mailhash, msg.sender, now.add(durationInYear * 365 days));
        
        _allocateProfit(cost,conf.openToPublic, domainOwner);
        
        emit Register(receiptID++, msg.sender, domainHash, cost);
    }
    
    function recharge(bytes32 mailHash, 
                    uint8 durationInYear) 
                    ValidEmailDuration(durationInYear)
                    external{
        
        bytes32 domainHash = mailData.domainHashOf(mailHash);
        
        MainServiceConf memory conf = mailConfigs[domainHash];
        require(conf.active, "domain hasn't open to email register");
        
        //actually the ownership of root domain or sub domain is the same
        address domainOwner = rootDomainData.getValidOwner(domainHash);
        if (domainOwner == address(0)){
            domainOwner = subDomainData.getValidOwner(domainHash);
        }
        
        uint cost = REG_MAIL_GAS.mul(durationInYear);
        
        token.transferFrom(msg.sender, address(accountant), cost);
        
        mailData.recharge(mailHash, durationInYear * 365 days);
        
        _allocateProfit(cost, conf.openToPublic, domainOwner);
         
        emit Recharge(receiptID++, msg.sender, mailHash, cost);
    }
    
    function _allocateProfit(uint cost,
                    bool isOpenToPub,
                    address topDomainOwner) private{
                        
        
         if (isOpenToPub){
            accountant.allocateProfit(accountant.contractReceivers(MINER), cost.mul(TOP_DOMAIN_M).div(100));
            accountant.allocateProfit(topDomainOwner, cost.mul(TOP_DOMAIN_O).div(100));
        }else{
            accountant.allocateProfit(accountant.contractReceivers(MINER), cost.mul(BASIC_M).div(100));
        }
    }
}