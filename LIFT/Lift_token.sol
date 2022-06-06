pragma solidity ^0.4.18;
import './SafeMath.sol';
// SPDX-License-Identifier: MIT
/*
 88           88   88888888888  88888888888888           
 88           88   88                 88           
 88           88   88                 88           
 88           88   888888             88           
 88           88   88                 88           
 88           88   88                 88           
 88           88   88                 88           
 88888888888  88   88                 88
 */

/*
    ZRC20Token Standard Token implementation
*/
contract ZRC20Token is SafeMath {

    string public constant standard = 'ZRC20';
    uint8 public constant decimals = 8; 
    string public constant name = 'TESTF10';
    string public constant symbol = 'TESTF10';
    uint256 public totalSupply = 10**9 * 10**uint256(decimals);

    uint256 private constant unlockedAmount = 10**6 * 10**uint256(decimals);
    uint256 private constant rewardPerDay = 10**3;
    uint256 private deltaTime = 1 minutes;
    address public owner;   
    /* number of token holders */
    uint256 public usersNumber = 0;
    uint256 public startTimestamp = block.timestamp;


    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    /* the time of the last payment of reward */
    mapping (address => uint256) public timestamps;
    /* indexes of token holders */
    mapping (uint256 => address) public users;
    /* if user is node*/
    mapping (address => bool) public isNode;
    /* rewards for each token holder */
    mapping (address => uint256) private rewards;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor(address _firstUser) public {

      owner = msg.sender; 
      uint256 lockedAmount = safeSub(totalSupply, unlockedAmount);

      // Add locked tokens created to the creator of the token
      balanceOf[msg.sender] = lockedAmount;
      // Emit an Transfer event to notify the blockchain that an Transfer has occured
      emit Transfer(address(0), msg.sender, lockedAmount); 

      balanceOf[_firstUser] = unlockedAmount;
      emit Transfer(address(0), _firstUser, unlockedAmount);

      //add moment of tokens' receiving
      timestamps[_firstUser] = block.timestamp;
      users[usersNumber] = _firstUser;
      ++usersNumber;

    }

    // validates an address - currently only checks that it isn't null
    modifier validAddress(address _address) {
        require(_address != address(0x0));
        _;
    }

    //During the transfer, interest on tokens will be charged to both the sender and the recipient
    //If recipient is new user he will be registrated
    function transfer(address _to, uint256 _value)
    public
    validAddress(_to)
    returns (bool success)
    {
        require(msg.sender != address(0), "DevToken: transfer from zero address");
        require(_to != address(0), "DevToken: transfer to zero address");
        require(balanceOf[msg.sender] >= _value, "DevToken: cant transfer more than your account holds");
        require(msg.sender != owner, "Owner can't transfer tokens");

        uint256 timestampNow = block.timestamp;

        _transfer(msg.sender, _to, _value);

        if (timestamps[msg.sender] == 0) {
        timestamps[msg.sender] = timestampNow;
        users[usersNumber] = msg.sender;
        ++usersNumber;
        } 

        if (timestamps[_to] == 0) {
        timestamps[_to] = timestampNow;
        users[usersNumber] = _to;
        ++usersNumber;
        }
        
        if ((balanceOf[owner] > 0) && ((safeSub(timestampNow, timestamps[users[0]])) / deltaTime > 0)) {  
          _transfer(owner, msg.sender, _reward(msg.sender));
          _transfer(owner, _to, _reward(_to));
        }
      
        return true;
    }

        
    //@notice _transfer is used for internal transfers
    function _transfer(address sender, address recipient, uint256 amount) internal {

      balanceOf[sender] = safeSub(balanceOf[sender], amount);
      balanceOf[recipient] = safeAdd(balanceOf[recipient], amount);
      emit Transfer(sender, recipient, amount);

    }

    function transferFrom(address _from, address _to, uint256 _value)
    public
    validAddress(_from)
    validAddress(_to)
    returns (bool success)
    {
          allowance[_from][msg.sender] = safeSub(allowance[_from][msg.sender], _value);
          balanceOf[_from] = safeSub(balanceOf[_from], _value);
          balanceOf[_to] = safeAdd(balanceOf[_to], _value);
          emit Transfer(_from, _to, _value);
          return true;
    }

    function approve(address _spender, uint256 _value)
    public
    validAddress(_spender)
    returns (bool success)
    {
        require(_value == 0 || allowance[msg.sender][_spender] == 0);
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // pay the reward to choosed users. No more than 20 users per block
    function payRewardToAll(uint256 startUser, uint256 finalUser) public {

      /* variables for calculation of sum of rewards to all users */
      uint256 totalReward = 0;
      uint256 lastUserReward = balanceOf[owner];
      uint256 i=0;

      if (finalUser > usersNumber) {
        finalUser=usersNumber;
      }

      for ( i=startUser; i < finalUser ; i++) {     
        rewards[users[i]] = _reward(users[i]);
        totalReward += rewards[users[i]];
      }

      if (totalReward > balanceOf[owner]) {
        for (i=0; i < usersNumber-1 ; i++) {
          rewards[users[i]] = rewards[users[i]] * balanceOf[owner] / totalReward;
          lastUserReward -= rewards[users[i]];
        }
        rewards[users[usersNumber-1]] = lastUserReward;
      }
      
      for (i=startUser; i < finalUser ; i++) {
        _transfer(owner, users[i], rewards[users[i]]);
        timestamps[users[i]] = block.timestamp;
      }
    }

    function _reward(address adr) internal view returns (uint256) {
      uint8 nodeCoef = 1;
      if (isNode[adr]) {
          nodeCoef = 2;
      }

      if (balanceOf[adr] >= 10 * 10**uint256(decimals)) {
        return (safeMul((safeSub(block.timestamp, timestamps[adr]) / deltaTime), balanceOf[adr]) * nodeCoef / rewardPerDay);
      } 
      else {
        return (0);
      }
    }

    function getMyAddress()  external view returns(address) {
        return msg.sender;
    }

    function getMyBallance()  external view returns(uint256) {
        return balanceOf[msg.sender];
    }

    function getPotentialNodes() external view returns (address[] memory) {
      uint256 temp = 0;
      address[] memory potNodes = new address[] (temp);
      uint256 intTemp = 0;

      for (uint256 i=0; i < usersNumber ; i++) {
        if (balanceOf[users[i]] >= 500 * 10 ** uint256(decimals)) {
          temp += 1;
        }
      }
      
      for (i=0; i < usersNumber ; i++) {
        if (balanceOf[users[i]] >= 500 * 10 ** uint256(decimals)) {
          potNodes[intTemp] = users[i];
          intTemp += 1;
        }
      }

      return (potNodes);
    }

    function showIsNode(address adr) external view returns (bool) {
      return isNode[adr];
    }

    function daysFromStart() external view returns (uint256) {
      return (block.timestamp - startTimestamp) / deltaTime;
    }

    // disable pay ZHC to this contract
    function () public payable {
        revert();
    }
}