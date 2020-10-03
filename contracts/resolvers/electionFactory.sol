pragma solidity ^0.5.0;

import './Voting.sol';

contract electionFactory is Voting{
address snowflake;
mapping(uint256 => bool) public electionIds;

event newElectionCreated(
    address indexed _deployedAddress
);

constructor(address _snowflakeAddress) public {
    snowflake=_snowflakeAddress;
}

function createNewElection(uint256 _electionID,address _snowflakeAddress) public returns(address newContract){
        require(electionIds[_electionID]==false,"election id already exists");
        _snowflakeAddress=snowflake;
       Voting v = new Voting(_snowflakeAddress);
       emit newElectionCreated(v.get());
        return v.get();
    //returns the new election contract address

}

}