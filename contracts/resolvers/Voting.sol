pragma solidity ^0.5.0;

import "../SnowflakeResolver.sol";
import "../interfaces/IdentityRegistryInterface.sol";
import "../interfaces/HydroInterface.sol";
import "../interfaces/SnowflakeInterface.sol";


contract Voting is SnowflakeResolver {
mapping(uint256=>Candidate) public candidates;
mapping(uint256=>bool) public aParticipant;
mapping(uint256=>bool) public aCandidate;
mapping(uint256=>bool) private hasVoted;

struct Candidate{
    uint256 voteCount;
}



uint256 voteFee= 100000000000000000000;//100tokens



uint256 burnAmount=1000000000000000000000;//1000tokens
uint256 maxNoOfCandidates=2;
address _snowflakeAddress;
uint256 deadlineInDays;

uint256[] candidateEINs;
uint256[] voterEINs;
uint256 voters=0;
uint256 registered=0;

//requires that the ein is a registered candidate
modifier isCandidate(uint256 ein){
    require(aCandidate[ein]==true,'This EIN has not registered as a candidate');
    _;
}

//requires that the ein has set this contract a resolver
modifier isParticipant(uint256 _ein){
    require(aParticipant[_ein]==true, 'this EIN has not registered as a participant');
    _;
}

//requires that the entered ein is not a candidate yet
modifier isNotCandidate(uint256 _ein){
    require(aParticipant[_ein]==true && aCandidate[_ein]==false,"you are a candidate");
    _;
}

//requires that the target does not have a hydroId yet
modifier noIdYet(address target){
    require(checkforReg(target)==false);
    _;
}

modifier HasEIN(address target){
    require(checkforReg(target)==true);
    _;
}

//requires that the deadline hasn't passed
modifier voteStillValid(){
    require (now<=deadlineInDays,"this election has expired");
    _;
}


event voted(uint256 _candidate);
event becameCandidate(uint256 _candidateEIN);
event registeredAsVoter(uint256 voterEin);
event newDeadlineSet(uint256 _newDeadline);

 constructor (address snowflakeAddress,string memory _name,string memory _description,uint256 _days)
        SnowflakeResolver(_name, _description, snowflakeAddress, true, false) public
    {
        snowflakeAddress=_snowflakeAddress;
        deadlineInDays=now+_days*1 days;
        
    }
//sets the maximum no of candidates for this resolver
//can only be set by contract owner
function setMaxCandidacy(uint256 _max) public  voteStillValid() onlyOwner(){
    maxNoOfCandidates=_max;
}
//check if address interacting with contract already has an ein
function checkforReg(address _target) public  returns(bool){
    SnowflakeInterface snowfl = SnowflakeInterface(snowflakeAddress);
    IdentityRegistryInterface idRegistry= IdentityRegistryInterface(snowfl.identityRegistryAddress());
    _target=msg.sender;
    bool hasId=idRegistry.hasIdentity(msg.sender);
    return hasId;
}

//basic check to return ein of the specific address
   function checkEIN(address _address) public returns(uint256){
        SnowflakeInterface snowfl = SnowflakeInterface(snowflakeAddress);
    IdentityRegistryInterface idRegistry= IdentityRegistryInterface(snowfl.identityRegistryAddress());
       uint256 Ein=idRegistry.getEIN(_address);
       return Ein;
   }
        
 /**   

//implement create Identity function
//might not be needed for now
function createId(address recoveryAddress) public returns(uint256 ein){
    SnowflakeInterface snowfl = SnowflakeInterface(snowflakeAddress);
    IdentityRegistryInterface idRegistry= IdentityRegistryInterface(snowfl.identityRegistryAddress());
    address[] memory _providers = new address [](2);
    address[] memory _resolvers= new address [](1);
    _providers[0]= address(this);
    _providers[1]= _snowflakeAddress;
    _resolvers[0]= address(this);
    
    return idRegistry.createIdentity(recoveryAddress,_providers,_resolvers);
    
    
} 

**/
//called to register any new actor in the system
//makes the ein to be a participant in the system
//a fee of 100 tokens is required
function onAddition(uint256 ein,uint256 /**allocation**/,bytes memory) public senderIsSnowflake() returns (bool){
   // SnowflakeInterface snowfl = SnowflakeInterface(snowflakeAddress);
   //  HydroInterface hydro = HydroInterface(snowfl.hydroTokenAddress());
    aParticipant[ein]=true;
    registered++;
     emit registeredAsVoter(ein);
    return true;
   
}

 function onRemoval(uint256, bytes memory) public senderIsSnowflake() returns (bool) {}
 
 //anyone who wants to become a candidate
 //1000 hydro tokens are deducted from the wallet of msg.sender and burnt
 function becomeCandidate(uint256 ein) public isParticipant(ein)  voteStillValid() isNotCandidate(ein){
    // SnowflakeInterface snowfl=SnowflakeInterface(snowflakeAddress);
    // HydroInterface hydro = HydroInterface(snowfl.hydroTokenAddress());
    uint256 candidateCount= candidateEINs.length;
    require(candidateCount<=maxNoOfCandidates,"candidate limit reached!");
    aCandidate[ein]=true;
    candidateEINs.push(ein);
    emit becameCandidate(ein);
 }
 
 //main vote function
function vote(uint256 _ein) public  HasEIN(msg.sender) isCandidate(_ein)  voteStillValid() returns(bool){
 SnowflakeInterface snowfl=SnowflakeInterface(snowflakeAddress);
 IdentityRegistryInterface idRegistry= IdentityRegistryInterface(snowfl.identityRegistryAddress());
 HydroInterface hydro = HydroInterface(snowfl.hydroTokenAddress());
 uint256 ein=checkEIN(msg.sender);

 
 require(aParticipant[ein]==true,'you are not a voter,register first');
 require (aCandidate[ein]==false,"you are a candidate");
 require(idRegistry.isResolverFor(ein,address(this)),"This EIN has not set this resolver.");
 require (hasVoted[ein]==false,"you have already voted");
  hydro.burnFrom(msg.sender,voteFee);
 candidates[_ein].voteCount++;
 hasVoted[ein]=true;
 voters++;
  emit voted(_ein);
 return (true);


}
//return the current max number of candidates
function getMaxCandidates() public view returns(uint256[] memory,uint256){
    return(candidateEINs,maxNoOfCandidates);
}



  /**  function withdrawFees(address to) public onlyOwner {
        SnowflakeInterface snowfl = SnowflakeInterface(snowflakeAddress);
        HydroInterface hydro = HydroInterface(snowfl.hydroTokenAddress());
        withdrawHydroBalanceTo(to, hydro.balanceOf(address(this)));
    }
    **/
    function setNewDeadline(uint256 _newDays) public onlyOwner voteStillValid returns(uint256){
        deadlineInDays=now+_newDays*1 days;
        emit newDeadlineSet(deadlineInDays);
        return deadlineInDays;
    }
    
    function getDeadline() public view returns(uint256){
        return deadlineInDays;
    }
    
    function getDetails() public view returns(uint256, uint256){
    return (voters,registered);
}
}