// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}


contract Crowdfunding {
    // address public owner;
    // mapping(address => uint256) public funders; //mapping funder address to fund amount
    // uint256 public deadline;
    // uint256 public targetFund;
    // uint256 public raisedFund;
    // uint256 public deploymentTime;
    // uint256 public funded;
    // bool public ownerWithdrawn;
    // string public projectName;

    struct Project {
      address owner; // creator of project
      uint256 targetFund;
      uint256 raisedFund;
      uint256 endAt;
      uint256 startAt;
      bool ownerWithdrawn;
      mapping(address => uint256) funders;
      string projectName;
    }

    uint256 public projectCount = 0; // count total number of existing project
    mapping(uint256 => Project) public projects; // map project id to project
   

    event Launch(uint256 id, string projectName, address indexed owner, uint256 targetFund, uint256 startAt, uint256 endAt);
    event Funded(address indexed _funder, uint256 _amount);
    event OwnerWithdraw(uint256 _id);
    event Refund(uint256 _id , address indexed _funder, uint256 _amount);
    event FunderWithdraw(address _funder, uint256 _amount);

    constructor(uint256 _targetFund, uint256 _deadline){
      deploymentTime = block.timestamp;
      deadline = deploymentTime + _deadline;
      targetFund = _targetFund;
    }

    receive() external payable { }

    fallback() external payable { } 

    function launch(string _projectName, uint256 _targetFund, uint256 _startAt, uint256 _endAt) external {
        require(_startAt >= block.timestamp, "start at < now");
        require(_endAt > _startAt, "end at <= start at");
        require(_endAt <= block.timestamp + 730 days, "end at > max duration (2 years)");

        projectCount++;
        projects[projectCount] = Project({
          owner: msg.sender,
          targetFund: _targetFund,
          raisedFund: 0,
          endAt: _endAt,
          startAt: _startAt,
          ownerWithdrawn: false,
          projectName: _projectName,
        });

        emit Launch(projectCount, _projectName, msg.sender, _targetFund, _startAt, _endAt);
    }

    // function createFund() external payable {
    //   funders[msg.sender] = msg.value;
    // }

    function getMyFund(uint256 projectId) public view returns(uint256) {
      return projects[projectId].funders[msg.sender];
    }

    function getRaisedFund(uint256 projectId) public view returns (uint256) {
      return projects[projectId].raisedFund;
    }

    function getDeadline(uint256 projectId)public view returns(uint256){
      return projects[projectId].endAt;
    }

    //TODO: cancel project

    // Owner get money after crowdfunding success
    function withdrawOwner(uint256 _id) public {
          Project storage project = projects[_id];
          require(msg.sender == project.owner, "Not authorized!");
          require(project.raisedFund >= project.targetFund, "Not meet target");
          require(block.timestamp > project.endAt, "not ended");
          require(!project.ownerWithdrawn, "Owner already withdrawn");

          // Transfer fund to owner
          (bool success,) = msg.sender.call{value: project.raisedFund}("");
          require(success, "unable to transfer fund to owner");
          project.ownerWithdrawn = true;
          emit OwnerWithdraw(_id);
      }

    // Funder invest
    function fund() public payable {
          Project storage project = projects[_id];
          require(block.timestamp >= project.startAt, "Not started yet");
          require(block.timestamp <= project.endAt, "Ended");

          //TODO: set the value limit (eg: 100, 1000, 5000)
          (bool success, ) = address(this).call{value: msg.value}("");
          require(success, "Unable to transfer funds to the contract.");
          project.raisedFund += msg.value;
          project.funders[msg.sender] += msg.value;

          emit Funded(msg.sender, msg.value);
      }
    
    // Optional: Funder get back investment
    // function withdrawFunder(uint256 _id) public {
    //     Project storage project = projects[_id];
    //     require(block.timestamp > project.endAt, "not end!");
    //     require(funders[msg.sender]>0, "You are not a contributor");

    //     uint256 amountToSend = funders[msg.sender];
        
    //     // Send ETH
    //     (bool success,) = msg.sender.call{value: amountToSend}("");
    //     require(success, "unable to send!");
    //     payable(msg.sender).transfer(amountToSend);
    //     raisedFund -= amountToSend;
    //     funders[msg.sender]=0;

    //     emit FunderWithdraw(msg.sender, amountToSend);
    // }

    // Fund refund after crowdfunding fails
    function refund(uint256 _id) public {
          Project storage project = projects[_id];
          require(block.timestamp > project.endAt, "not end!");
          require(project.funders[msg.sender]>0, "You are not a contributor");
          require(project.raisedFund < project.targetFund, "raisedFund > targetFund");

          uint256 amountToSend = project.funders[msg.sender];
          (bool success,) = msg.sender.call{value: amountToSend}("");
          require(success, "unable to send!");
          project.raisedFund -= amountToSend;
          project.funders[msg.sender]=0;
          emit Refund(_id, msg.sender, amountToSend);
      }

}

