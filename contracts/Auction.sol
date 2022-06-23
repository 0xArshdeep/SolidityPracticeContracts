// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Auction {
    address payable public owner;
    uint256 public startBlock;
    uint256 public endBlock;
    string public ipfsHash;
    enum State {
        Started,
        Running,
        Ended,
        Canceled
    }
    State public auctionState;

    uint256 public highestBindingBid;
    address payable public highestBidder;

    mapping(address => uint256) public bids;
    uint256 bidIncrement;

    constructor() {
        owner = payable(msg.sender);
        auctionState = State.Running;
        startBlock = block.number;
        endBlock = startBlock + 40320;
        ipfsHash = "";
        bidIncrement = 100;
    }

    modifier notOwner() {
        require(msg.sender != owner);
        _;
    }

    modifier afterStart() {
        require(block.number >= startBlock);
        _;
    }

    modifier beforeEnd() {
        require(block.number <= endBlock);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a <= b) {
            return a;
        } else {
            return b;
        }
    }

    function placeBid() public payable notOwner afterStart beforeEnd {
        require(auctionState == State.Running);
        require(msg.value > 100);

        uint256 currentBid = bids[msg.sender] + msg.value;
        require(currentBid > highestBindingBid);

        bids[msg.sender] = currentBid;

        if (currentBid <= bids[highestBidder]) {
            highestBindingBid = min(
                currentBid + bidIncrement,
                bids[highestBidder]
            );
        } else {
            highestBindingBid = min(
                currentBid,
                bids[highestBidder] + bidIncrement
            );
            highestBidder = payable(msg.sender);
        }
    }

    function cancelAuction() public onlyOwner {
        auctionState = State.Canceled;
    }

    function finalizeAuction() public {
        require(auctionState == State.Canceled || block.number > endBlock);
        require(msg.sender == owner || bids[msg.sender] > 0);

        address payable recipient;
        uint256 value;

        if (auctionState == State.Canceled) {
            recipient = payable(msg.sender);
            value = bids[msg.sender];
        } else {
            // Auction ended (not canceled)
            if (msg.sender == owner) {
                // this is the owner
                recipient = owner;
                value = highestBindingBid;
            } else {
                // this is a bidder
                if (msg.sender == highestBidder) {
                    recipient = highestBidder;
                    value = bids[highestBidder] - highestBindingBid;
                } else {
                    // this is neither the owner or the highestBidder
                    recipient = payable(msg.sender);
                    value = bids[msg.sender];
                }
            }
        }

        // resetting the bids of the recipient to zero
        bids[recipient] = 0;

        // sends value to the recipient
        recipient.transfer(value);
    }
}
