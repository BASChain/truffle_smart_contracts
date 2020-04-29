pragma solidity >=0.5.0;

import "./BasOwnership.sol";

/*
[INHERIT]
this contract just provides two functions
*/
contract BasDomain is ManagedByContract, ManagedByOwner{
    
    uint8 constant MAX_DOMAIN_SEG_LEN   = 64;
    
    //[0~9, a~z, -, _]
    function validChar(bytes1 c)
    internal
    pure
    returns (bool) {
        return
        (c >= 0x30 && c <= 0x39) ||
        (c >= 0x61 && c <= 0x7a) ||
        c == 0x2d ||
        c == 0x5f;
    }
    
    function getValidOwner(bytes32 hash) 
                    external
                    view 
                    returns (address){
        
        (address owner, uint expire) = ownership.ownerOfWithExpire(hash);
        if (expire < now){
            return address(0);
        }
        return owner;
        
    }
    
    function domainIsValid(address curOwner, 
                    bytes32 hash)
                    external 
                    view 
                    returns (bool){
        (address owner, uint expire) = ownership.ownerOfWithExpire(hash);
        return owner == curOwner && expire > now;
    }
}

/*
[DEPLOYED]
this contract keeps root domain data
*/
contract BasRootDomain is BasDomain {
    using SafeMath for uint256;
    
    uint8 public RARE_LENGTH = 6; 
    
    constructor(address _os) public{
        ownership = BasExpiredOwnership(_os);
    }
    
    struct RootItem {
        bytes   rootName;
        bool    openToPublic;
        bool    isCustomed;
        uint256 customedPrice;
    }

    event RootUpdate(bytes32 nameHash, 
                    bytes rootName, 
                    bool openToPublic,
                    bool isCustomed, 
                    uint customedPrice);
                    
    event NewRootDomain(bytes rootName, 
                    bool openToPublic, 
                    bool isCustomed, 
                    uint customedPrice);
                    
    event RootDataReplced(bytes32 nameHash, 
                    bool openToPublic, 
                    bool isCustomed, 
                    uint customedPrice);
    
    event OpenCustomedPrice(bytes32 nameHash, 
                    uint customedPrice);
    
    event ClosedCustomedPrice(bytes32 nameHash);
    event RootRecharged(bytes32, 
                        uint256 duration);
    event RootPublicChagned(bytes32 nameHash,
                            bool isOpen);
    
    mapping(bytes32 => RootItem) public Root;
    
    function changeRareLength(uint8 length)
                    external
                    OnlyDAO{
                       RARE_LENGTH = length; 
    }
    
    function classifyRoot(bytes memory name)
                    public
                    view
                    returns (bool, bool) {

        if (name.length == 0 || name.length >= MAX_DOMAIN_SEG_LEN) {
            return (false, false);
        }

        bool isRare = true;
        for (uint8 i = 0; i < name.length; i++) {

            if (!validChar(name[i])) {
                return (false, false);
            }

            if (isRare) {
                isRare = !(i >= RARE_LENGTH ||
                name[i] == 0x2d ||
                name[i] == 0x5f);
            }
        }

        return (true, isRare);
    }
    
    function classifyRoot(bytes32 nameHash)
                    external
                    view
                    returns (bool, bool){
            if (hasDomain(nameHash)){
                return classifyRoot(Root[nameHash].rootName);
            }else{
                return (false,false);
            }
    }
    
    
    /*
    because we check by nameHash so we can skip validation
    */
    function isRare(bytes32 nameHash)
                    external
                    view
                    returns (bool){
            
            if(!hasDomain(nameHash)){
                return false;
            }
            bytes memory name = Root[nameHash].rootName;
            for (uint8 i = 0; i < name.length; i++) {
                if (i >= RARE_LENGTH ||
                name[i] == 0x2d ||
                name[i] == 0x5f){
                    return false;
                }
            }
            return true;
    }
    
    function verifyRoot(bytes memory name)
                    public
                    pure
                    returns (bool) {

        if (name.length == 0 || name.length >= MAX_DOMAIN_SEG_LEN) {
            return false;
        }

        for (uint8 i = 0; i < name.length; i++) {

            if (!validChar(name[i])) {
                return false;
            }
        }

        return true;
    }
    
    function verifyRoot(bytes32 nameHash)
                    external
                    view
                    returns (bool){
            if(hasDomain(nameHash)){
                return verifyRoot(Root[nameHash].rootName);
            }else{
                return false;
            }
    }
    
    function hasDomain(bytes32 hash) 
                    public
                    view 
                    returns (bool){
        return Root[hash].rootName.length > 0;
    }
    function getNameByHash(bytes32 hash)
                    external 
                    view 
                    returns (bytes memory){
        return Root[hash].rootName;
    }
    
    function updateByDaoProposal(bytes calldata rootName,
                            bool openToPublic,
                            bool isCustomed,
                            uint256 customedPrice)
                            external
                            OnlyDAO {

        bytes32 nameHash = BasHash.Hash(rootName);

        Root[nameHash] = RootItem(
            rootName,
            openToPublic,
            isCustomed,
            customedPrice
        );

        emit RootUpdate(nameHash, rootName, openToPublic, isCustomed, customedPrice);
    }
    
    /*
    create a new item or takeover ownership of expired item
    */
    function replaceOrCreate(bytes calldata rootName,
                        uint expire,
                        bool openToPublic,
                        bool isCustomed,
                        uint256 customedPrice,
                        address applicant)
                        external
                        OnlyDataKeeper {
        
        bytes32 nameHash = BasHash.Hash(rootName); 
        (address oldOwner, uint oldExpire) = ownership.ownerOfWithExpire(nameHash);
        
        Root[nameHash].openToPublic = openToPublic;
        Root[nameHash].isCustomed = isCustomed;
        Root[nameHash].customedPrice = customedPrice;
        
        if (oldOwner != address(0)){
            require(oldExpire < now, "can't take this domain");
            ownership.takeover(nameHash, applicant, expire);
            
            emit RootDataReplced(nameHash, openToPublic, isCustomed, customedPrice);
            
        }else{
            ownership.newOwnership(nameHash, applicant, expire);
            Root[nameHash].rootName = rootName;
            
            emit NewRootDomain(rootName, openToPublic, isCustomed, customedPrice);
        }
        
    }
    
    /*
    anyone can recharge a domain
    if domain is expired, charged time will be added to now
    if domain is not expired, charged time will be added to expiration time
    after addition, the expiration from now should be less than 5 years
    */
    function recharge(bytes32 nameHash, 
                uint rechargeTime, 
                uint maxEnd)
                external 
                OnlyDataKeeper{

        require(ownership.ownerOf(nameHash) != address(0), "no such domain");
        require(ownership.extendTime(nameHash, rechargeTime) < maxEnd, "can't recharge that long");
        
        emit RootRecharged(nameHash, rechargeTime);
    }

    /*
    this function is called by OANN because open customed price costs BAS
    but the ownership is checked here, operator is surposed to be tx.origin
    */
    function openCustomedPrice(bytes32 nameHash,
                        uint customedPrice,
                        address operator)
                        external
                        OnlyOwner(operator, nameHash)
                        OnlyDataKeeper{
        
        Root[nameHash].isCustomed = true;
        Root[nameHash].openToPublic = true;
        Root[nameHash].customedPrice = customedPrice;
        
        emit OpenCustomedPrice(nameHash, customedPrice);
    }

    /*
    called by user
    */
    function closeCustomedPrice(bytes32 nameHash)
                            external
                            OnlyOwner(msg.sender, nameHash) {
            
        Root[nameHash].isCustomed = false;
        Root[nameHash].openToPublic = false;
        
        emit ClosedCustomedPrice(nameHash);
    }

    function setPublic(bytes32 nameHash,
                    bool isOpen) 
                    external 
                    OnlyOwner(msg.sender,nameHash) {
        
        require(Root[nameHash].openToPublic != isOpen, "nothing changed");
        Root[nameHash].openToPublic = isOpen;
        
        emit RootPublicChagned(nameHash, isOpen);
    }
    
}

/*
[DEPLOYED]
this contract keeps sub domain data
*/
contract BasSubDomain is BasDomain{
    using SafeMath for uint256;
    
    uint16 constant MAX_SUB_DOMAIN_LEN  = 192;
    
    bytes1 constant DOT_CHAR_VAL        = 0x2e;
    
    constructor(address _os) public{
        ownership = BasExpiredOwnership(_os);
    }
    
    struct SubItem {
        bytes   totalName;
        bytes32 rootHash;
    }
    
    event SubUpdate(bytes32 nameHash,
                    bytes totalName,
                    bytes32 rootHash);
    
    event NewSubDomain(bytes32 nameHash,
                    bytes totalName,
                    bytes32 rootHash);

    event SubDataReplaced(bytes32 nameHash);
    event SubRecharged(bytes32 nameHash,
                      uint256 duration);
    
    
    mapping(bytes32 => SubItem) public Sub;
    
    function verifySub(bytes memory name)
                    public
                    pure
                    returns (bool) {

        if (name.length >= MAX_SUB_DOMAIN_LEN){
            return false;
        }

        if (name[0] == DOT_CHAR_VAL || name[name.length-1] == DOT_CHAR_VAL){
            return false;
        }

        uint256 segementLength = 0;

        for (uint256 i = 0; i < name.length; i++) {

            bytes1 char = name[i];
            if (!validChar(char) && char != DOT_CHAR_VAL){
                return false;
            }

            if (char == DOT_CHAR_VAL){
                if (segementLength == 0){
                    return false;
                }

                segementLength = 0;
                continue;
            }

            segementLength += 1;
            if (segementLength >= MAX_DOMAIN_SEG_LEN){
                return false;
            }
        }

        return true;
    }
  
    function hasDomain(bytes32 hash) 
                external 
                view 
                returns (bool){
        return Sub[hash].totalName.length > 0;
    }
    
    function getNameByHash(bytes32 hash) 
                external 
                view 
                returns (bytes memory){
        return Sub[hash].totalName;
    } 
    
    function replaceOrCreate(bytes calldata subdomain,
                    bytes32 rootHash,
                    uint newExpire,
                    address applicant)
                    external
                    OnlyDataKeeper{
        
        bytes32 subHash = BasHash.Hash(subdomain);
        
        (address owner, uint expire) = ownership.ownerOfWithExpire(subHash);
        require(owner == address(0) || expire < now, "the subdomain is still under other's control");
        
        if (owner != address(0)) {
            ownership.takeover(subHash, applicant, newExpire);
            emit SubDataReplaced(subHash);
        } else {
            ownership.newOwnership(subHash, applicant, newExpire);
            Sub[subHash] = SubItem(subdomain, rootHash);
            emit NewSubDomain(subHash, subdomain, rootHash);
        }
    }
    
    function updateByDaoProposal(bytes calldata totalName,
                        bytes32 rootHash)
                        external
                        OnlyDAO{

        bytes32 nameHash = BasHash.Hash(totalName);
        Sub[nameHash] = SubItem(totalName, rootHash);
        emit SubUpdate(nameHash,totalName,rootHash);
    }
    
    function recharge(bytes32 nameHash, 
                uint rechargeTime, 
                uint maxEnd)
                external 
                OnlyDataKeeper{
                    
        BasExpiredOwnership _os = BasExpiredOwnership(ownership);
        
        (address owner, uint256 expire) = _os.ownerOfWithExpire(nameHash);
        require(owner != address(0), "no such domain");
        require(expire.add(rechargeTime) < maxEnd, "can't recharge that long");
        
        _os.extendTime(nameHash, rechargeTime);
    }
}

/*
[DEPLOYED]
this contract is used for DNS server, email server etc
*/
contract BasDomainConf is ManagedByOwner{
    
    event DomainConfChanged(bytes32, uint8, bytes);
    event DomainConfRemoved(bytes32, uint8);
    event DomainConfClear(bytes32);
    event DomainConfDictionChanged(uint8, string);
    
    uint8 public MaxTypeID;
    mapping(uint8 => string) public TypDiction;
    mapping(bytes32 => mapping(uint8 => bytes)) public domainConfData;
    
    constructor(address _os) public {
        TypDiction[0] = "A";
        TypDiction[1] = "AAAA";
        TypDiction[2] = "MX";
        TypDiction[3] = "BlockChain";
        TypDiction[4] = "IOTA";
        TypDiction[5] = "Optional";
        TypDiction[6] = "CName";
        TypDiction[7] = "MXBCA";
        MaxTypeID = 7;
        
        ownership = BasExpiredOwnership(_os);
    }
    
    modifier ValidDicIndex(uint8 idx){
        require(idx <= MaxTypeID, "no such item");
        _;
    }
    
    function updateTypeDiction(uint8 typ, 
                    string calldata typName)
                    external
                    OnlyDAO{
        TypDiction[typ] = typName;
        if (typ > MaxTypeID){
            MaxTypeID = typ;
        }
        
        emit DomainConfDictionChanged(typ, typName);
    }

    function updateByDaoProposal(bytes32 nameHash,
                                uint8 typ,
                                bytes calldata data)
                                external
                                OnlyDAO{
                                    
        domainConfData[nameHash][typ] = data;
        emit DomainConfChanged(nameHash, typ, data);
    }

    //support multiple ipv4 data, joined by "," 
    function updateByOwner(bytes32 nameHash,
                        uint8 typ,
                        bytes calldata data)
                        external
                        ValidDicIndex(typ)
                        OnlyOwner(msg.sender, nameHash){

        domainConfData[nameHash][typ] = data;
        emit DomainConfChanged(nameHash, typ, data);
    }

    function query(bytes32 nameHash, 
                uint8 typ)
                external
                view
                returns (bytes memory bca) {
                    
        return domainConfData[nameHash][typ];
    }

    function removeRecord(bytes32 nameHash,
                        uint8 typ)
                        external
                        OnlyOwner(msg.sender, nameHash){

        delete domainConfData[nameHash][typ];
        emit DomainConfRemoved(nameHash, typ);
    }

    function clearRecord(bytes32 nameHash)
                        external
                        OnlyOwner(msg.sender, nameHash){
                            
        for (uint8 idx = 0; idx <= MaxTypeID; idx++){
            delete domainConfData[nameHash][idx];
        }
        
        emit DomainConfClear(nameHash);
    }
}