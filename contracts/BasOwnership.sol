pragma solidity >=0.5.0;

import "./BasLib.sol";

/*
[INHERIT]
contract inherit this will be partially under control of DAO 
*/
contract  ManagedByDAO {
    
    address public DAOAddress;

    constructor() public {
        DAOAddress = msg.sender;
    }

    modifier OnlyDAO {
        require(msg.sender == DAOAddress, "admin only");
        _;
    }

    function ChangeDAO(address newDao)
                            external
                            OnlyDAO {
        DAOAddress = newDao;
    }
}

/*
[INHERIT]
contract inherit this will be a DataStore 
 which remain unchanged during logic contract update
 */
contract ManagedByContract is ManagedByDAO{

    mapping(address => bool) public dataKeeper;

    modifier OnlyDataKeeper(){
        require(dataKeeper[msg.sender], "Only data keeper valid");
        _;
    }

    function addDataKeeper(address _addr)
                    external
                    OnlyDAO{
        dataKeeper[_addr] = true;
    }

    function removeDataKeeper(address _ok)
                    external
                    OnlyDAO{
        delete dataKeeper[_ok];
    }
}

/*
[INHERIT]
contract inherit this will be partially under control of data owner
  (sometimes also partially under control if DAO)
*/
contract ManagedByOwner is ManagedByDAO{
    
    BasExpiredOwnership public ownership;
   
    modifier OnlyOwner(address owner, 
                    bytes32 hash){
        (address curOwner, uint256 expire) = ownership.ownerOfWithExpire(hash);
        require(curOwner == owner && expire > now, "only owner is invalid");
        _;
    }
    
    function setOwnership(address _os)
                    external 
                    OnlyDAO{
        ownership = BasExpiredOwnership(_os);
    }
}

/*
[DEPLOYED]
contract like this is a none tradable ownership database
(e.g email ownership)
*/
contract BasExpiredOwnership is ManagedByContract{
    
    using SafeMath for uint256;
    using BasSet for BasSet.IndexedAsset;

    /*
    there is no need to index any of those events
    */
    event Add(bytes32 nameHash, address owner);
    event Update(bytes32 nameHash, address owner);
    event Extend(bytes32 nameHash, uint256 time);
    event Takeover(bytes32 nameHash, address from, address to);

    struct ownerShip{
        address ownerAddr;
        uint256 expireDate;
    }
    
    string public OwnerShipLabel;
    mapping(bytes32 => ownerShip) internal _ownerShips;
    mapping(address => BasSet.IndexedAsset) internal _assetsOf;
    
    constructor(string memory label) public{
        OwnerShipLabel = label;
    }
    
    modifier OnlyOwner(bytes32 nameHash) {
        ownerShip memory os = _ownerShips[nameHash];
        require(os.ownerAddr == msg.sender && os.expireDate > now, "owner only");
        _;
    }

    modifier CanRegister(bytes32 nameHash) {
        ownerShip memory os = _ownerShips[nameHash];
        require(os.ownerAddr == address(0) || os.expireDate < now, "not valid");
        _;
    }

    modifier HasOwner(bytes32 nameHash) {
        require(_ownerShips[nameHash].ownerAddr != address(0), "no owner");
        _;
    }
    
    function ownerOf(bytes32 nameHash)
                    external
                    view
                    returns (address){

        return _ownerShips[nameHash].ownerAddr;
    }
    
    
    function ownerOfWithExpire(bytes32 nameHash)
                    public
                    view
                    returns (address,uint256){

        ownerShip memory os = _ownerShips[nameHash];
        return (os.ownerAddr, os.expireDate);
    }
    
    function updateByDaoProposal(bytes32 nameHash,
                                address owner,
                                uint256 expire)
                                external
                                OnlyDAO {

        ownerShip storage os =  _ownerShips[nameHash];
        require(os.ownerAddr != owner);

        _relpaceOwnership(owner, os.ownerAddr, nameHash);
        os.ownerAddr    = owner;
        os.expireDate   = expire;

        emit Update(nameHash, owner);
    }

    function newOwnership(bytes32 nameHash,
                        address owner,
                        uint256 expire)
                        external
                        OnlyDataKeeper
                        CanRegister(nameHash) {

        _ownerShips[nameHash] = ownerShip(owner, expire);
        _assetsOf[owner].append(nameHash);

        emit Add(nameHash, owner);
    }
    
    function extendTime(bytes32 nameHash,
                        uint256 extend)
                        external
                        OnlyDataKeeper
                        HasOwner(nameHash) 
                        returns (uint256){

        ownerShip storage os = _ownerShips[nameHash];
        if (os.expireDate < now){
            os.expireDate = now.add(extend);
        }else{
            os.expireDate = os.expireDate.add(extend);
        }
        emit Extend(nameHash, extend);
        return os.expireDate;
    }

    function _relpaceOwnership(address oldOwner,
                            address newOwner,
                            bytes32 nameHash)
                            internal{
        _assetsOf[oldOwner].trimIfExist(nameHash);
        _assetsOf[newOwner].append(nameHash);
    }
    
    function takeover(bytes32 nameHash,
                    address owner,
                    uint256 expire)
                    external
                    OnlyDataKeeper
                    CanRegister(nameHash) {

        address oldOwner = _ownerShips[nameHash].ownerAddr;

        _relpaceOwnership(oldOwner, owner, nameHash);
        _ownerShips[nameHash] = ownerShip(owner, expire);

        emit Takeover(nameHash, oldOwner, owner);
    }
    
    function assetsCountsOf()
                external
                view
                returns(uint256){
                return _assetsOf[msg.sender].counts();                
    }
    
    function assetsOf(uint256 start,
                    uint256 end)
                external
                view
                returns(bytes32[] memory){
                return _assetsOf[msg.sender].slice(start,end);   
    }
}

/*
[DEPLOYED]
contract like this is a tradable ownership database
(e.g domain ownership)
*/
contract BasTradableOwnership is BasExpiredOwnership{
    
    /*
    there is also no need to keep index on events
    because Transfer or TransferFrom can happen on different
    scenerios and we should keep records on business level
    */
    event Transfer(bytes32 nameHash, address from, address to);
    event TransferFrom(bytes32 nameHash, address from, address to, address by);
    event Approval(address from, address to, bytes32 nameHash);
    event Revoke(address from, bytes32 nameHash);

    mapping(address => mapping(bytes32 => address)) internal _allowed;
    
    constructor(string memory label) public BasExpiredOwnership(label){}
    
    function transfer(bytes32 nameHash,
                    address to)
                    external
                    OnlyOwner(nameHash) {

        require(msg.sender != to, "transfer to self");

        _ownerShips[nameHash].ownerAddr = to;
        _relpaceOwnership(msg.sender, to, nameHash);

        emit Transfer(nameHash, msg.sender, to);
    }

    function approve(bytes32 nameHash,
                    address spender)
                    external
                    OnlyOwner(nameHash){

        _allowed[msg.sender][nameHash] = spender;
        emit Approval(msg.sender, spender, nameHash);
    }

    function allowance(address owner,
                        bytes32 nameHash)
                        external
                        view
                        returns (address) {

        return _allowed[owner][nameHash];
    }

    function revoke(bytes32 nameHash)
                    external
                    OnlyOwner(nameHash) {

        delete _allowed[msg.sender][nameHash];
        emit Revoke(msg.sender, nameHash);
    }

    function transferFrom(bytes32 nameHash,
                        address from,
                        address to)
                        external {

        require(_ownerShips[nameHash].ownerAddr == from);
        require(_allowed[from][nameHash] == msg.sender, "not allowed");
        require(from != to, "transfer to self");

        delete _allowed[from][nameHash];
        _ownerShips[nameHash].ownerAddr = to;
        _relpaceOwnership(from, to, nameHash);

        emit TransferFrom(nameHash, from, to, msg.sender);
    }
}