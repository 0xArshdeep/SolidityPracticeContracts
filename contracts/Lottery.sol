// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Lottery {
    address payable[] public players;
    address payable public manager;

    constructor() {
        manager = payable(msg.sender);
    }

    receive() external payable {
        require(msg.value == 0.1 ether);
        require(msg.sender != manager);
        players.push(payable(msg.sender));
    }

    function getBalance() public view returns (uint256) {
        require(msg.sender == manager);
        return address(this).balance;
    }

    function random() public view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        players.length
                    )
                )
            );
    }

    function pickWinnder() public {
        require(msg.sender == manager);
        require(players.length >= 3);

        uint256 r = random();
        address payable winner;

        uint256 index = r & players.length;
        winner = players[index];

        winner.transfer((getBalance() / 100) * 90); // winner receives 90% of the lottery funds
        manager.transfer(getBalance()); // manager receives a fee of 10% of the lottery funds
        players = new address payable[](0); // resetting the lottery
    }
}
