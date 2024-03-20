// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}


contract Crowdfunding {
    address public owner;
    mapping(address => uint256) public funders; //mapping funder address to fund amount
    uint256 public deadline;
    uint256 public targetFund;
    uint256 public raisedFund;
    uint256 public deploymentTime;
    uint256 public funded;
    bool public ownerWithdrawn;
    string public projectName;

    enum Status{
      Preparing,
      Funding,
      Failed,
      Successful,
      Closed
    }
    Status public status;

    IERC20 public immutable token;

    event Funded(address indexed _funder, uint256 _amount);
    event OwnerWithdraw(uint256 _amount);
    event FunderWithdraw(address _funder, uint256 _amount);

    constructor(uint256 _targetFund, uint256 _deadline, address _token){
      deploymentTime = block.timestamp;
      deadline = deploymentTime + _deadline;
      targetFund = _targetFund;
      status = status;
      token = IERC20(_token);
    }

    receive() external payable { }

    fallback() external payable { } 

    function createFund() external payable {
      funders[msg.sender] = msg.value;
    }

    function getMyFund() public view returns(uint256) {
      return funders[msg.sender];
    }

    function showDeadline()public view returns(uint256){
      return deadline;
    }

    function getRasiedFund()public view returns(uint256){
      return raisedFund;
    }

    function withdrawOwner() public {
          require(msg.sender == owner, "Not authorized!");
          require(raisedFund >= targetFund, "Cannot withdraw!");
          require(block.timestamp > deadline, "not ended");
          require(!ownerWithdrawn, "Owner already withdrawn");

          // Send ETH
          (bool success,) = msg.sender.call{value: raisedFund}("");
          require(success, "unable to send!");
          ownerWithdrawn = true;
          emit OwnerWithdraw(raisedFund);
      }

    function fund() public payable {
          require(block.timestamp > deadline, "Funding is now disabled!");
          raisedFund += msg.value;
          funders[msg.sender] += msg.value;
          // Give token to funder
          token.transferFrom(msg.sender, address(this), msg.value);
          emit Funded(msg.sender, msg.value);
      }

    function withdrawFunder() public {
          require(block.timestamp > deadline, "Withdraw is now disabled!");
          require(funders[msg.sender]>0, "You are not a contributor");

          uint256 amountToSend = funders[msg.sender];
          
          // Send ETH
          (bool success,) = msg.sender.call{value: amountToSend}("");
          require(success, "unable to send!");
          payable(msg.sender).transfer(amountToSend);
          raisedFund -= amountToSend;
          funders[msg.sender]=0;
          token.transfer(msg.sender, amountToSend);
          emit FunderWithdraw(msg.sender, amountToSend);
      }

}

