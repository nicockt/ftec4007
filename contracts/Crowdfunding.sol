// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}


contract Crowdfunding {
    struct Project {
      uint256 id;
      address owner; // creator of project
      uint256 targetFund;
      uint256 raisedFund;
      uint256 endAt;
      uint256 startAt;
      bool ownerWithdrawn;
      mapping(address => uint256) funders; // address -> amountDonated
      address[] fundersAddress;
      string projectName;
      string description;
    }

    uint256 public projectCount = 0; // count total number of existing project
    mapping(uint256 => Project) public projects; // map project id to project

    event Cancel(uint256 _id);
    event Launch(uint256 _id, string _projectName, address indexed _owner, uint256 _targetFund, uint256 _startAt, uint256 _endAt);
    event Fund(uint256 indexed _id, address indexed _funder, uint256 _amount);
    event SuccessFund(uint256 indexed _id, uint256 _raisedFund);
    event OwnerWithdraw(uint256 _id);
    event Refund(uint256 _id , address indexed _funder, uint256 _amount);
    event FunderWithdraw(uint256 indexed _id, address _funder, uint256 _amount);

    receive() external payable { }

    fallback() external payable { } 

    function launch(string memory _projectName, string memory _description, uint256 _targetFund, uint256 _startFromNow, uint256 _duration) external returns (uint256){
        uint256 _startAt = block.timestamp + _startFromNow;
        uint256 _endAt = _startAt + _duration;
        require(_duration > 0, "duration <= 0");
        require(_startFromNow >= 0, "startFromNow < 0");
        require(_startAt >= block.timestamp, "start at < now");
        require(_endAt > _startAt, "end at <= start at");
        require(_endAt <= block.timestamp + 730 days, "end at > max duration (2 years)");
        require(_targetFund > 0, "targetFund <= 0");

        projectCount++;
        Project storage newProject = projects[projectCount];
        newProject.owner = msg.sender;
        newProject.id = projectCount;
        newProject.targetFund = _targetFund;
        newProject.raisedFund = 0;
        newProject.endAt = _endAt;
        newProject.startAt = _startAt;
        newProject.projectName = _projectName;
        newProject.description = _description;
        newProject.ownerWithdrawn = false;
        

        emit Launch(newProject.id, _projectName, msg.sender, _targetFund, _startAt, _endAt);
        return newProject.id;
    }

    function getMyFund(uint256 projectId) public view returns(uint256) {
      return projects[projectId].funders[msg.sender];
    }

    function getRaisedFund(uint256 projectId) public view returns (uint256) {
      return projects[projectId].raisedFund;
    }

    function getDeadline(uint256 projectId)public view returns(uint256){
      return projects[projectId].endAt;
    }

    function getFunders(uint256 _projectId)external view returns(address[] memory, uint256[] memory){
      Project storage project = projects[_projectId];
      address[] memory fundersArray = project.fundersAddress;
      uint256[] memory funderAmounts = new uint256[](project.fundersAddress.length);

      for (uint i = 0; i < project.fundersAddress.length; i++) {
          funderAmounts[i] = project.funders[project.fundersAddress[i]];
      }

      return (fundersArray, funderAmounts);
    }

    function isSuccess(uint256 projectId)public view returns(bool){
      return projects[projectId].raisedFund >= projects[projectId].targetFund;
    }



    // Owner cancel project before funding
    function cancel(uint256 _id) external { 
        Project storage project = projects[_id];
        require(project.startAt != 0, "Project not exists");
        require(project.owner == msg.sender, "not creator");
        require(block.timestamp < project.startAt, "started");
        require(project.raisedFund == 0, "already funded");
        require(!project.ownerWithdrawn, "Owner already withdrawn");

        delete projects[_id];
        emit Cancel(_id);
    }

    // Owner get money after crowdfunding success
    function withdrawOwner(uint256 _id) external {
          Project storage project = projects[_id];
          require(project.startAt != 0, "Project not exists");
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
    function fund(uint256 _id) external payable {
          Project storage project = projects[_id];
          require(project.startAt != 0, "Project not exists");  
          require(block.timestamp >= project.startAt, "Not started yet");
          require(block.timestamp <= project.endAt, "Ended");

          //TODO: set the value limit (eg: 100, 1000, 5000)
          (bool success, ) = address(this).call{value: msg.value}("");
          require(success, "Unable to transfer funds to the contract.");
          project.raisedFund += msg.value;
          project.funders[msg.sender] += msg.value;
          project.fundersAddress.push(msg.sender);

          emit Fund(_id, msg.sender, msg.value);
          if (project.raisedFund >= project.targetFund) {
            emit SuccessFund(_id, project.raisedFund);
          }
      }
    
    // Funder get back funding before project ends
    function withdrawFunder(uint256 _id) external  {
        Project storage project = projects[_id];
        require(project.startAt != 0, "Project not exists");
        require(block.timestamp <= project.endAt, "Ended");
        require(project.funders[msg.sender] > 0, "You are not a contributor");

        uint256 amountToSend = project.funders[msg.sender];
        
        // Send money from contract to funder
        (bool success,) = msg.sender.call{value: amountToSend}("");
        require(success, "unable to send!");
        project.raisedFund -= amountToSend;
        project.funders[msg.sender]=0;
        uint256 indexToBeRemoved = 0;
        for (uint i = 0; i < project.fundersAddress.length; i++) {
            if (project.fundersAddress[i] == msg.sender) {
                indexToBeRemoved = i;
                break;
            }
        }
        // Swap the funder to be removed with the last funder
        project.fundersAddress[indexToBeRemoved] = project.fundersAddress[project.fundersAddress.length - 1];
        project.fundersAddress.pop();

        emit FunderWithdraw(_id, msg.sender, amountToSend);
    }

    // Refund to funder after project fails
    function refund(uint256 _id) external {
          Project storage project = projects[_id];
          require(project.startAt != 0, "Project not exists");
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
