// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CrowdFunding {
    mapping(address => uint256) public contributors;
    address public admin;
    uint256 public numOfContributors;
    uint256 public minimumContribution;
    uint256 public deadline; // timestamp
    uint256 public goal;
    uint256 public raisedAmount;
    struct Request {
        string description;
        address payable recipient;
        uint256 value;
        bool completed;
        uint256 numVoters;
        mapping(address => bool) voters;
    }

    mapping(uint256 => Request) public requests;

    uint256 public numRequests;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function!");
        _;
    }

    constructor(uint256 _goal, uint256 _deadline) {
        goal = _goal;
        deadline - block.timestamp + _deadline;
        minimumContribution = 100 wei;
        admin = msg.sender;
    }

    function contribute() public payable {
        require(block.timestamp < deadline, "Deadline has passed!");
        require(
            msg.value >= minimumContribution,
            "Minimum Contribution not met!"
        );

        if (contributors[msg.sender] == 0) {
            numOfContributors++;
        }

        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;
    }

    receive() external payable {
        contribute();
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getRefund() public {
        require(block.timestamp > deadline && raisedAmount < goal);
        require(contributors[msg.sender] > 0);

        address payable recipient = payable(msg.sender);
        uint256 value = contributors[msg.sender];
        recipient.transfer(value);

        contributors[msg.sender] = 0;
    }

    function createRequest(
        string memory _description,
        address payable _recipient,
        uint256 _value
    ) public onlyAdmin {
        Request storage newRequest = requests[numRequests];
        numRequests++;

        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.numVoters = 0;
    }

    function voteRequest(uint256 _requestNo) public {
        require(
            contributors[msg.sender] > 0,
            "You must be a contributor to vote!"
        );
        Request storage thisRequest = requests[_requestNo];

        require(
            thisRequest.voters[msg.sender] == false,
            "You have already voted!"
        );
        thisRequest.voters[msg.sender] = true;
        thisRequest.numVoters++;
    }

    function makePayment(uint256 _requestNo) public onlyAdmin {
        require(raisedAmount >= goal);
        Request storage thisRequest = requests[_requestNo];
        require(
            thisRequest.completed == false,
            "The request has been completed."
        );
        require(
            thisRequest.numVoters > numOfContributors / 2,
            "Less than 50% of contriutors have voted for the request."
        );

        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed = true;
    }
}
