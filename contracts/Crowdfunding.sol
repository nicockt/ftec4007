// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


contract crowdfunding {
    address public owner;
    mapping(address => uint256) public funder;
    uint256 public deadline;
    uint256 public target;
    uint256 public amount;
    uint256 public deploymentTime;
    uint256 public funded;
    enum Status{
      Preparing,
      Funding,
      Failed,
      Successful,
      Closed
    }
    Status public status;

    constructor(uint256 _target){
      deploymentTime = block.timestamp;
      deadline = deploymentTime + 100000000;
      target = _target;
      status = status;
    }

    receive() external payable { }

    fallback() external payable { } 

    function createFund() external payable {
      funder[msg.sender] = msg.value;
    }

    function getMyFund() public view returns(uint256) {
      return funder[msg.sender];
    }

    function showDeadline()public view returns(uint256){
      return deadline;
    }

    function getbalance()public view returns(uint256){
      return address(this).balance;
    }


}

