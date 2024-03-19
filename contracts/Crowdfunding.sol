// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


contract Crowdfunding {
    address public owner;
    mapping(address => uint256) public funder;
    uint256 public deadline;
    uint256 public targetFund;
    uint256 public amount;
    uint256 public deploymentTime;
    uint256 public funded;
    bool public fundsWithdrawn;
    string public name;

    enum Status{
      Preparing,
      Funding,
      Failed,
      Successful,
      Closed
    }
    Status public status;

    event Funded(address indexed _funder, uint256 _amount);
    event OwnerWithdraw(uint256 _amount);
    event FunderWithdraw(address _funder, uint256 _amount);

    constructor(uint256 _target){
      deploymentTime = block.timestamp;
      deadline = deploymentTime + 100000000;
      targetFund = _target;
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

  function isFundEnabled() public view returns(bool) {
        if (block.timestamp > deadline || fundsWithdrawn) {
            return false;
        } else {
            return true;
        }
    }

    function isFundSuccess() public view returns(bool) {
        if(address(this).balance >= targetFund) {
            return true;
        } else {
            return false;
        }
    }
}

