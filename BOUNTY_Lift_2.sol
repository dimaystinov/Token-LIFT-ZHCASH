// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;
//import "hardhat/console.sol";

/*
    ZRC20Token Standard Token implementation
*/


contract SafeMath {

    function safeAdd(uint256 _x, uint256 _y) pure internal returns (uint256) {
        uint256 z = _x + _y;
        assert(z >= _x);
        return z;
    }

    function safeSub(uint256 _x, uint256 _y) pure internal returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }

    function safeMul(uint256 _x, uint256 _y) pure internal returns (uint256) {
        uint256 z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }

}

contract ZRC20Token is SafeMath {

    string public constant standard = 'ZRC20';
    uint256 public constant decimals = 8; 
    uint256 public constant ZHC = 10 ** decimals;
    string public constant name = 'ZH';//'ZHChain official Bounty Programm / Zero Hour Cash P2P Blockchain Network';
    string  public  symbol = unicode'Bo 💎';
    uint256 public constant totalSupply = 10 * 10 ** 9 * ZHC;
    uint256 private constant unlockedAmount = 3 * totalSupply / 10;
    uint256 private constant rewardPerDay = 55;
    uint256 private constant PERCENT = 10 ** 4;
    uint256 private constant deltaTime = 24 * 3600; //days
    address public  owner;   
    address public firstUser;

    /* number of token holders */
    uint256 public usersNumber = 0;
    uint256 public startTimestamp = block.timestamp;
  
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    /* how long tokens were in user's wallet */
    mapping (address => uint256) public timestamps;
    /* indexes of token holders */
    mapping (uint256 => address) public users;
    /* rewards for each token holder */
    mapping (address => uint256) private rewards;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor()  {
  
      owner = address(0);
      firstUser = msg.sender;
      uint256 lockedAmount = safeSub(totalSupply, unlockedAmount);

      // add locked tokens created to the creator of the token
      balanceOf[owner] = lockedAmount;
      emit Transfer(address(0), msg.sender, lockedAmount); 

      balanceOf[firstUser] = unlockedAmount;
      emit Transfer(address(0), firstUser, unlockedAmount);

      // add moment of tokens' receiving
      timestamps[firstUser] = block.timestamp;
      users[usersNumber] = firstUser;
      ++usersNumber;

    }

    // validates an address - currently only checks that it isn't null
    modifier validAddress(address _address) {
        require(_address != address(0));
        _;
    }


    function transfer(address _to, uint256 _value)
    public
    returns (bool success)
    {
        require(msg.sender != address(0), "DevToken: transfer from zero address");
        require(balanceOf[msg.sender] >= _value, "DevToken: cant transfer more than your account holds");
        

        if (timestamps[msg.sender] == 0) {
        users[usersNumber] = msg.sender;
        timestamps[msg.sender] = block.timestamp;
        ++usersNumber;
        } 

        if (timestamps[_to] == 0) {
        users[usersNumber] = _to;
        timestamps[_to] = block.timestamp;
        ++usersNumber;
        }

        if (safeSub(block.timestamp, timestamps[msg.sender]) >= deltaTime ) {  
          _transfer(owner, msg.sender, _reward(msg.sender));
          timestamps[msg.sender] = block.timestamp;
        }

        if (safeSub(block.timestamp, timestamps[_to]) >= deltaTime ){ 
          _transfer(owner, _to, _reward(_to));
          timestamps[_to] = block.timestamp;
        }

        _transfer(msg.sender, _to, _value);
        
        return true;
    }
  
    //@notice _transfer is used for internal transfers
    function _transfer(address sender, address recipient, uint256 amount) internal returns(bool) {
      balanceOf[sender] = safeSub(balanceOf[sender], amount);
      balanceOf[recipient] = safeAdd(balanceOf[recipient], amount);
      emit Transfer(sender, recipient, amount);
      return true; 
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

    function _reward(address adr) internal view returns (uint256) {
      if (adr == owner || adr == firstUser) return 0;
      return ((block.timestamp - timestamps[adr]) / deltaTime) * balanceOf[adr] * rewardPerDay / PERCENT; 
    }

    function getMyAddress()  external view returns(address) {
        return msg.sender;
    }

    function daysAfterLastReward() external view returns(uint256) {
          return safeSub(block.timestamp, timestamps[msg.sender]) / deltaTime;
    }

    function getMyBallance()  external view returns(uint256) {
        return balanceOf[msg.sender];
    }

    function daysFromStart() external view returns (uint256) {
      return (block.timestamp - startTimestamp) / deltaTime;
    }
     

}