pragma solidity ^0.5.0;

import "../SnowflakeResolver.sol";
import "../interfaces/IdentityRegistryInterface.sol";
import "../interfaces/HydroInterface.sol";
import "../interfaces/SnowflakeInterface.sol";

contract Voting is SnowflakeResolver {
    mapping (uint => string) private statuses;
    mapping(uint=>Candidate) public candidates;
    mapping(uint=>bool) public aVoter;
    mapping(uint=>bool) public aCandidate;


struct Candidate{
    uint voteCount;
}

    uint signUpFee = 1000000000000000000;
    string firstStatus = "My first status 😎";
    uint256 tokenToBurn= 2000000000000000000;
    uint256 regFee= 4000000000000000000;
    uint maxNoOfCandidates;

uint[] candidateEINs;
uint[] voterEINs;

modifier isVoter(uint ein){
    require(aVoter[ein]==true,'you are not a voter,register first');
    _;
}
modifier isCandidate(uint _ein){
    require(aCandidate[_ein]==true, 'this EIN has not registered as a candidate');
    _;
}


    constructor (address snowflakeAddress)
        SnowflakeResolver("Voting", "vote your candidates", snowflakeAddress, true, false) public
    {}

    // implement signup function
    function onAddition(uint ein, uint, bytes memory) public senderIsSnowflake() returns (bool) {
        SnowflakeInterface snowflake = SnowflakeInterface(snowflakeAddress);
        snowflake.withdrawSnowflakeBalanceFrom(ein, owner(), regFee);
    
        statuses[ein] = firstStatus;

        emit StatusSignUp(ein);

        return true;
    }

    function onRemoval(uint, bytes memory) public senderIsSnowflake() returns (bool) {}

    function getStatus(uint ein) public view returns (string memory) {
        return statuses[ein];
    }

    function setStatus(string memory status) public {
        SnowflakeInterface snowflake = SnowflakeInterface(snowflakeAddress);
        IdentityRegistryInterface identityRegistry = IdentityRegistryInterface(snowflake.identityRegistryAddress());

        uint ein = identityRegistry.getEIN(msg.sender);
        require(identityRegistry.isResolverFor(ein, address(this)), "The EIN has not set this resolver.");

        statuses[ein] = status;

        emit StatusUpdated(ein, status);
    }

    function withdrawFees(address to) public onlyOwner() {
        SnowflakeInterface snowflake = SnowflakeInterface(snowflakeAddress);
        HydroInterface hydro = HydroInterface(snowflake.hydroTokenAddress());
        withdrawHydroBalanceTo(to, hydro.balanceOf(address(this)));
    }

function setMaxCandidacy(uint _max) public onlyOwner(){
    maxNoOfCandidates=_max;
}
    event StatusSignUp(uint ein);
    event StatusUpdated(uint ein, string status);
}
