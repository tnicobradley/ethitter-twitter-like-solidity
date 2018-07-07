pragma solidity 0.4.19;

/*
    twitter-like messaging service for the ethereum blockchain. 
    It was created as an excercise, 
 	Tokens are minted when posts are made until they run out
 	a fee is taken for each post which is then distributed to the token owners 
 	it was fairly expensive when testing it a while ago, so I abandoned it
*/

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */

contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

contract ethitter is Ownable{
    string public symbol = "SBOX";
    string public name = "Soap Box";
    uint8 public constant decimals = 2;
    uint256 _totalSupply = 0;
    uint256 _maxTotalSupply = 5000000000;
    uint256 _totalDist;
    uint256 _distributionTime = now; ///to test
    uint256 _lastDistribution = 0;
    uint dividendPercent = 3; //1/3 of all fees orginally --can be changed by owner.
    uint cost;
    bool public enabled;
    event UpdateCost(uint newCost);
    event UpdateEnabled(string newStatus);
    event SendPost(address poster, uint256 postID);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(uint256 => address) addresses;
    ///15 million granted to contract owner 
     struct Account{
        bool exists;
        uint256 balance;
        uint256 eligable;
        uint256 divAmount;
        bool received;

    }

    mapping(address => Account) accounts;

    function ethitter() {
        cost = 15 szabo;
        enabled = true;
        _totalSupply += 1500000000;
        balances[msg.sender] += 1500000000;
        makeAccount(1500000000);
        Transfer(this,msg.sender,1500000000);

    }
   function percent(uint numerator, uint denominator) private
     constant returns(uint quotient) {
         // caution, check safe-to-multiply here
        uint256 _numerator  = numerator * 10**18;
        // with rounding of last digit
        uint _quotient = ((_numerator / denominator)/ 10);
        return ( _quotient);
  }
  function findDiv(uint256 bal,uint256 _total,uint256 available) private constant returns(uint256){
        uint256 divRatio = percent(bal,_total);
        uint256 divpayment = SafeMath.mul(divRatio, available);
        divpayment = SafeMath.div(divpayment,10**17);
        return(divpayment);

  } 
    struct Post{
        uint64 timestamp;
        string postbody;
        string IPFSHash;    ///possible image uploading
    }

    Post[] posts;
    ///mapping from post ID to address of poster
    mapping (uint256 => address) public postIndextoPoster;
    ///mapping from user address to number of posts made by address
    mapping (address => uint256) userPostCount;
    function _emitPost(address _to, uint256 _postId) internal {
        if(accounts[msg.sender].exists == false){
            makeAccount(balances[msg.sender]);
        }
        if(_totalSupply < _maxTotalSupply){
            _totalSupply += 100;    
            balances[_to] += 100;
            accounts[_to].balance += 100;
            Transfer(this,_to,100);
            
        }
        userPostCount[_to]++;
        postIndextoPoster[_postId] = _to;
        SendPost(_to, _postId);
    }

    

    function makeAccount(uint256 usrBalance) private{
        Account memory _account = Account({
            exists: true,
            balance: usrBalance,
            eligable: _distributionTime,
            divAmount: 0,
            received: true
        });
        accounts[msg.sender] = _account;
    }
    function accountExists() returns(bool existence){
        return(accounts[msg.sender].exists);
    }
    function accountEligable() returns(uint256 eligability){
        return(accounts[msg.sender].eligable);
    }
    function received() returns(bool divRecieved){
        return(accounts[msg.sender].received);
    }
    function currentDist() returns(uint256 _Dist){
        return(_distributionTime);
    }
    function accountBalance() returns(uint256 _bal){
        return(accounts[msg.sender].balance);
    }
    function lastDist() returns(uint256 _lastDist){
        return(_lastDistribution);
    }
    function timeNow() returns(uint256 currentTime){
        return(now);
    }
    function setDividend(uint256 divPercent) onlyOwner{
        dividendPercent = divPercent;
    }
    
    function distribution() returns(uint256){
           if(_distributionTime <= now){
                _lastDistribution = _distributionTime;
                _distributionTime += 26 weeks;
                _totalDist = this.balance;
                
                
           }
           if((accounts[msg.sender].received == true) && (accounts[msg.sender].eligable == _lastDistribution)){
                if(now >= _lastDistribution){
                    accounts[msg.sender].received = false;
                    accounts[msg.sender].eligable = _distributionTime;
                    ///return(_totalDist);
                }
           }
           
           if((accounts[msg.sender].eligable == _distributionTime) && (accounts[msg.sender].received == false)){
                accounts[msg.sender].eligable = _distributionTime + 26 weeks;
                accounts[msg.sender].received = true;
                if(accounts[msg.sender].balance >= 500){
                   accounts[msg.sender].divAmount = findDiv(accounts[msg.sender].balance,_totalSupply,_totalDist);
                   ///accounts[msg.sender].divAmount = 5;
                   address payee = msg.sender;
                   payee.send(accounts[msg.sender].divAmount);
                   uint256 divTot = accounts[msg.sender].divAmount;
                   accounts[msg.sender].divAmount = 0;
                   return(divTot);
                }

           }
           else{
                revert();
           }

        }

    function transfer(address _to, uint256 _amount) returns (bool success) {
        if(accounts[msg.sender].exists == false){
            makeAccount(balances[_to]);
        }
        if (balances[msg.sender] >= _amount 
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[msg.sender] -= _amount;
            accounts[msg.sender].balance -= _amount;
            balances[_to] += _amount;
            accounts[_to].balance += _amount;
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) returns (bool success) {
        if(accounts[msg.sender].exists == false){
            makeAccount(balances[_to]);
        }
        if (balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            accounts[_from].balance -= _amount;
            balances[_to] += _amount;
            accounts[_to].balance += _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function changeCost(uint price) onlyOwner {
        cost = price;
        UpdateCost(cost);
    }
    
    function pauseContract() onlyOwner {
        enabled = false;
        UpdateEnabled("ethitter has been disabled");
    }
    
    function enableContract() onlyOwner {
        enabled = true;
        UpdateEnabled("ethitter has been enabled");
    }
    
    
    function costWei() constant returns (uint) {
      return cost;
    }

    function currentRevenue() constant returns (uint){
        return(this.balance);
        
    }


    function makePost(string textBody) public payable {
        ///if paused revert
        if(!enabled) revert();
        ///checks that fee was payed, if not reverts
        if(msg.value < cost) revert();
        ///if (bytes(textBody).length > 560) revert();
        Post memory _post = Post({
            timestamp: uint64(now),
            postbody: textBody,
            IPFSHash: "None"
        });

        uint256 newPostId = posts.push(_post) - 1;
        require(newPostId == uint256(uint32(newPostId)));
        _emitPost(msg.sender,newPostId);
    }

    ///returns total posts made by all posters
    function totalPosts() public view returns (uint) {
        return posts.length - 1;
    }
    ///returns number of posts for _poster
    function postsOf(address _poster) public view returns (uint256 count) {
        return userPostCount[_poster];
    }
    ///returns an array of post ID's of posts made by poster
    function postsOfPoster(address _poster) external view returns(uint256[] userPosts) {
        uint256 postCount = postsOf(_poster);

        if (postCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](postCount);
            uint256 totposts = totalPosts();
            uint256 resultIndex = 0;

            uint256 postsId;

            for (postsId = 1; postsId <= totposts; postsId++) {
                if (postIndextoPoster[postsId] == _poster) {
                    result[resultIndex] = postsId;
                    resultIndex += 1;
                }
            }

            return result;
        }
    }
    
    function showPost(uint _idOfPost) returns(string){
        return(posts[_idOfPost].postbody);
    }
    function showPostTime(uint _idOfPost) returns(uint256){
        return(posts[_idOfPost].timestamp);
    }
    function showPhotoHash(uint _idOfPost) returns(string){
        return(posts[_idOfPost].IPFSHash);
    }
    
}