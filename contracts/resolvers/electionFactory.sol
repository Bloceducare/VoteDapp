pragma solidity ^0.5.0;

import './Voting.sol';

contract electionFactory {
address snowflake;
mapping(uint256 => bool) public electionIds;

event newElectionCreated(
    address indexed _deployedAddress,uint _id
);


function createNewElection(uint256 _electionID,address _snowflakeAddress,string memory _name,string memory _description) public returns(address newContract){
        require(electionIds[_electionID]==false,"election id already exists");
        _snowflakeAddress=snowflake;
       Voting v = new Voting(snowflake,_name,_description);
       emit newElectionCreated(address(v),_electionID);
       electionIds[_electionID]=true;
        return address(v);
    //returns the new election contract address

}

}