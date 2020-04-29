pragma solidity >= 0.5.0;

import "./BasToken.sol";
import "./BasOwnership.sol";


interface ContractReceiver{
    function subAllocate(uint sum) external;
    function getBalance(address addr) external view returns (uint256);
}

/*
[DEPLOYED]
this contract works as ledger keeper
*/
contract BasAccountant is ManagedByDAO, ManagedByContract{
    
    using SafeMath for uint256;
    
    struct ProfitAssigner{
        uint8[]    weight;
        address[] addr;
    }
    
    ERC20 public token;
    
    mapping(string=>address) public contractReceivers;
    
    mapping(address=>uint) public ledger;
    
    /*
    contractReceiver should implements subAllocate function
    to keep their inner balance
    and "miner" should be at least be setted
    */
    function registerContractReceiver(string memory lebal, address receiver) 
            public
            OnlyDAO{
        contractReceivers[lebal] = receiver;
    }
    
    /*
    this function returns the balance of a address in contract receiver's ledger
    */
    function checkSubBalance(string calldata lebal,
                            address account)
                            external
                            view
                            returns(uint256){
        address addr = contractReceivers[lebal];
        return ContractReceiver(addr).getBalance(account);                            
    }
    
    /*
    this function will be called by contract that costs token,
    like OANN, emailManager
    just keep ledger of an address
    */
    function allocateProfit(address receiver,  
                        uint value)
                        OnlyDataKeeper
                        external{
        ledger[receiver] = ledger[receiver].add(value);
    }
    
    /*
    this function keep ledger of contract address
    and triggers its subAllocate interface
    */
    function allocateProfit(string calldata lebal,
                            uint value)
                            OnlyDataKeeper
                            external{
        address addr = contractReceivers[lebal];
        ledger[addr] = ledger[addr].add(value);
        ContractReceiver(addr).subAllocate(value);
    }
    
    /*
    this is for contract receiver to withdraw token
    the amount is managed by contract receiver itself
    */
    function withdrawTo(uint amount, 
                address target) 
                external {
        uint256 balance = ledger[msg.sender];
        require(balance > amount, "balance insufficient");

        ledger[msg.sender] = balance.sub(amount);
        token.transfer(target, balance);
    }
    
    /*
    for root domain owner withdraw token
    */
    function withdraw(uint amount)
                external {
        uint256 balance = ledger[msg.sender];
        require(balance > amount, "balance insufficient");

        ledger[msg.sender] = balance.sub(amount);
        token.transfer(msg.sender, balance);
    }
    
    function daoWithdraw(address to,
                        uint256 no)
                        OnlyDAO
                        external{
        token.transfer(to, no);
    }
    
}
/*
[DEPLOYED]
this contract acts as contract receiver
*/

contract BasMiner is ManagedByContract, ContractReceiver{
    using SafeMath for uint256;
 
    BasToken public token;
    BasAccountant public accountant;
    address[] public MainNode;
    mapping(address=>uint) public balanceOf;
    uint8 public constant MainNodeSize = 64;
    
    constructor(address _t, address _a) public {
        token = BasToken(_t);
        accountant = BasAccountant(_a);
    }

    /*
    we should make Withdraw indexed
    because miner can view how many it already withdrawed
    */
    event MinerAdd(address miner);
    event Withdraw(address indexed drawer, uint256 amout);
    event MinerRemove(address miner);
    event MinerReplace(address oldMiner, address newMiner);

    modifier HasSettleClean(address miner){
        require(balanceOf[miner] == 0, "miner's balance isn't settled down");
        _;
    }

    function GetAllMainNodeAddress()
                public
                view
                returns(address[] memory) {

        return MainNode;
    }
    
    function addMiner(address m)
                    OnlyDAO
                    external{

        require(MainNode.length < MainNodeSize, "nodes is full");

        MainNode.push(m);
        emit MinerAdd(m);
    }

    function replaceMiner(address oldM,
                    address newM)
                    OnlyDAO
                    HasSettleClean(oldM)
                    external{
        
        require(MainNode.length > 0, "nodes empty");

        for (uint8 i = 0; i < MainNode.length; i++){
            if (MainNode[i] == oldM){
                MainNode[i] = newM;
                break;
            }
        }

        emit MinerReplace(oldM, newM);
    }

    function removeMiner(address miner)
                    OnlyDAO
                    HasSettleClean(miner)
                    external{

        require(MainNode.length > 0, "nodes empty");
        
        for (uint8 i = 0; i < MainNode.length; i++){

            if (MainNode[i] == miner){

                MainNode[i] = MainNode[MainNode.length - 1];

                delete MainNode[MainNode.length - 1];

                emit MinerRemove(miner);
                break;
            }
        }
    }
    
    function settleMiner(address miner)
                OnlyDAO
                external{
        
        require(balanceOf[miner] > 0, " empty account");
        
        accountant.withdrawTo(balanceOf[miner] , miner);
    }

    function withdraw() external {
        
        uint256 balance = balanceOf[msg.sender];
        require(balance > 0,"balance is 0");
        
        balanceOf[msg.sender] = 0;
        accountant.withdrawTo(balance, msg.sender);

        emit Withdraw(msg.sender, balance);
    }
    
    function subAllocate(uint256 sum) 
                    OnlyDataKeeper
                    external{

        uint256 one_porift = sum.div(MainNode.length);
        for (uint8 i = 0; i < MainNode.length; i++){
            address miner_address = MainNode[i];
            balanceOf[miner_address] = balanceOf[miner_address].add(one_porift);
        }
    }
    
    function getBalance(address addr) 
                    external 
                    view 
                    returns (uint256){
        return balanceOf[addr];                       
    }
    
}