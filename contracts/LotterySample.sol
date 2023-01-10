// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LotterySample is ReentrancyGuard, Ownable {
    uint256 public constant ticketPrice = 0.01 ether;
    uint256 public constant ticketCommission = 0.001 ether; // commition per ticket
    uint256 public constant duration = 30 minutes; // The duration set for the lottery
    uint256 public constant maxTicketPerUser = 10; // Maximum ticket purchase by 1 address
    uint256 public expiration; // Timeout in case That the lottery was not carried out.
    address public lotteryOperator; // the crator of the lottery
    uint256 public operatorTotalCommission = 0; // the total commission balance
    address public lastWinner; // the last winner of the lottery
    uint256 public lastWinnerAmount; // the last winner amount of the lottery

    mapping(address => uint256) public winnings; // maps the winners to they winnings amount
    mapping(address => uint256) public purchaseLimits; // maps the address to their limit to buy
    address[] public tickets; //array of purchased Tickets

    // modifier to check if caller is the lottery operator
    modifier onlyOperator() {
        require(
            (msg.sender == lotteryOperator),
            "Caller is not the lottery operator"
        );
        _;
    }

    // modifier to check if caller is a winner
    modifier onlyWinner() {
        require(isWinner(), "Caller is not a winner");
        _;
    }

    // The owner of the contract and the operator is different address
    // The operator is a scheduler address that will call the drawTicket after expiration
    constructor(address operator) {
        lotteryOperator = operator;
        expiration = block.timestamp + duration;
    }

    // return all the tickets
    function getTickets() public view returns (address[] memory) {
        return tickets;
    }

    // return the amount winners received
    function getWinningsForAddress(address addr) public view returns (uint256) {
        return winnings[addr];
    }

    function buyTickets() external payable nonReentrant {
        require(block.timestamp < expiration, "The lottery is expired");
        require(
            msg.value % ticketPrice == 0,
            string.concat(
                "the value must be multiple of ",
                Strings.toString(ticketPrice),
                " Ether"
            )
        );
        
        uint256 numOfTicketsToBuy = msg.value / ticketPrice;

        require(numOfTicketsToBuy <= (maxTicketPerUser - purchaseLimits[msg.sender]), "Can't buy more than the limit");

        for (uint256 i = 0; i < numOfTicketsToBuy; i++) {
            purchaseLimits[msg.sender] = purchaseLimits[msg.sender] + 1;
            tickets.push(msg.sender);
        }
    }

    function drawWinnerTicket() public onlyOperator {
        require(tickets.length > 0, "No tickets were purchased");

        bytes32 blockHash = blockhash(block.number - tickets.length);
        uint256 randomNumber = uint256(
            keccak256(abi.encodePacked(block.timestamp, blockHash))
        );
        uint256 winningTicket = randomNumber % tickets.length;

        address winner = tickets[winningTicket];
        lastWinner = winner;
        winnings[winner] += (tickets.length * (ticketPrice - ticketCommission));
        lastWinnerAmount = winnings[winner];
        operatorTotalCommission += (tickets.length * ticketCommission);
        delete tickets;
        expiration = block.timestamp + duration;
    }

    function restartDraw() public onlyOperator {
        require(tickets.length == 0, "Cannot Restart Draw as Draw is in play");

        delete tickets;
        expiration = block.timestamp + duration;
    }

    function checkWinningsAmount() public view returns (uint256) {
        address payable winner = payable(msg.sender);

        uint256 reward2Transfer = winnings[winner];

        return reward2Transfer;
    }

    function withdrawWinnings() external nonReentrant onlyWinner {
        address payable winner = payable(msg.sender);

        uint256 reward2Transfer = winnings[winner];
        winnings[winner] = 0;

        winner.transfer(reward2Transfer);
    }

    function refundAll() public {
        require(block.timestamp >= expiration, "the lottery not expired yet");

        for (uint256 i = 0; i < tickets.length; i++) {
            address payable to = payable(tickets[i]);
            tickets[i] = address(0);
            to.transfer(ticketPrice);
        }
        delete tickets;
    }

    function withdrawCommission() public onlyOperator {
        address payable operator = payable(msg.sender);

        uint256 commission2Transfer = operatorTotalCommission;
        operatorTotalCommission = 0;

        operator.transfer(commission2Transfer);
    }

    function isWinner() public view returns (bool) {
        return winnings[msg.sender] > 0;
    }

    function currentWinningReward() public view returns (uint256) {
        return tickets.length * ticketPrice;
    }

    function gerPurchaseLimits() public view returns (uint256) {
        return maxTicketPerUser - purchaseLimits[msg.sender];
    }
}
