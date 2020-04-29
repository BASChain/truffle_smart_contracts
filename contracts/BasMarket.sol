pragma solidity >=0.5.0;

import "./BasToken.sol";
import "./BasOwnership.sol";
import "./BasDomain.sol";
import "./BasLib.sol";

/*
[DEPLOYED]
this contract is for domain trade
*/
contract BasMarket is ManagedByDAO{
    
    using SafeMath for uint256;
    using BasSet for BasSet.IndexedAsset;
    
    uint256 public AT_LEAST_REMAIN_TIME = 128 days;

    ERC20 public token;
    BasSubDomain public subDomainData;
    BasRootDomain public rootDomainData;
    BasTradableOwnership public ownership;
    
    constructor(address _t,
                address _rd,
                address _sd)
                public{
        token           = ERC20(_t);
        rootDomainData  = BasRootDomain(_rd);
        subDomainData   = BasSubDomain(_sd);
        require(address(rootDomainData.ownership()) ==
                address(subDomainData.ownership()), "domain contract deploy error");
        ownership       = BasTradableOwnership(address(rootDomainData.ownership));            
    }

    function setupDataRef(address _t, 
                    address _rd, 
                    address _sd)
                    public 
                    OnlyDAO{
        
        token           = ERC20(_t);
        rootDomainData  = BasRootDomain(_rd);
        subDomainData   = BasSubDomain(_sd);
        require(address(rootDomainData.ownership) ==
                address(subDomainData.ownership), "domain contract deploy error");
        ownership       = BasTradableOwnership(address(rootDomainData.ownership));
    }

    /*
    SoldBySell should be indexed
    because there are scenerios like 
    get all my sold domains
    or get all my bought domains
    */
    event SoldBySell(bytes32 nameHash,
                address indexed from,
                address indexed to,
                uint256 price);

    event SellAdded(bytes32 nameHash,
                address operator,
                uint256 price);

    event SellChanged(bytes32 nameHash,
                address operator,
                uint256 price);

    event SellRemoved(bytes32 nameHash,
                address operator);

    mapping(address => mapping(bytes32 => uint256)) public DomainSellOrders;
    mapping(address => BasSet.IndexedAsset) internal _ordersOf;
    
    
    
    modifier ValidPrice(uint price){
        require(price > 0, "price can't be zero");
        _;
    }
    
    modifier ItemExist(bytes32 hash){
        require(DomainSellOrders[msg.sender][hash] > 0, "no such item");
        _;
    }

    /*
    mainly check two things
    1. if msg.sender owns this asset
    2. if this asset's expiration longer than AT_LEAST_REMAIN_TIME
    3. if msg.sender approved market with this asset 
    */
    modifier FullControl(bytes32 nameHash){
        (address owner, uint expire) = ownership.ownerOfWithExpire(nameHash);
        require(owner == msg.sender 
                && ownership.allowance(owner, nameHash) == address(this) 
                && now.add(AT_LEAST_REMAIN_TIME) < expire,
            "control error");
        _;
    }
    
    function changeAtLeastDays(uint newDays)
                            external
                            OnlyDAO{
        AT_LEAST_REMAIN_TIME = newDays;
    }
    

    function AddToSells(bytes32 nameHash,
                    uint256 price)
                    external
                    FullControl(nameHash)
                    ValidPrice(price){

        DomainSellOrders[msg.sender][nameHash] = price;
        
        emit SellAdded(nameHash, msg.sender, price);
    }
    
    /*
    we skip FullControl check
    */
    function ChangeSellPrice(bytes32 nameHash,
                    uint256 price)
                    external
                    ValidPrice(price)
                    ItemExist(nameHash){
                        
        DomainSellOrders[msg.sender][nameHash] = price;
        
        emit SellChanged(nameHash, msg.sender, price);
    }

    function RemoveSellOrder(bytes32 nameHash)
                    public {

        delete DomainSellOrders[msg.sender][nameHash];
        
        emit SellRemoved(nameHash, msg.sender);
    }

    /*
    we skip peer FullControl check because it's guarenteed by transferFrom
    */
    function BuyFromSells(bytes32 nameHash,
                        address owner)
                        external {
        
        require(msg.sender != owner, "can't buy from self");
        
        uint price = DomainSellOrders[owner][nameHash];
        
        (,uint expire) = ownership.ownerOfWithExpire(nameHash);
        require(now.add(AT_LEAST_REMAIN_TIME) < expire, "the domain will expire shortly");
        
        token.transferFrom(msg.sender, owner, price);
        
        ownership.transferFrom(nameHash, owner, msg.sender);

        delete DomainSellOrders[owner][nameHash];

        emit SoldBySell(nameHash, owner, msg.sender, price);
    }
    
    function ordersCountsOf()
                external
                view
                returns(uint256){
                return _ordersOf[msg.sender].counts();                
    }
    
    function ordersOf(uint256 start,
                    uint256 end)
                external
                view
                returns(bytes32[] memory){
                return _ordersOf[msg.sender].slice(start,end);   
    }
}