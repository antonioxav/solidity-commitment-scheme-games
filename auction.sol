// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Auction.
 * @dev One-time blind auction.
 **/
 contract Auction{

    // State Variables.
    address public highest_bidder; 
    address owner;  

    mapping(address => bytes32) public commitments;
    mapping(address => uint) public bids;
    mapping(address => uint) public balance;

    mapping(address => bool) committed;
    mapping(address => bool) revealed;

    // Events
    event CommitmentDetails(address bidder, bytes32 commitment);
    event RevelationDetails(address bidder, uint bid, uint nonce, bytes32 commitmentHash);
    event CurrentHighestBidder(address winner, uint winningBid); // todo: adapt.

    uint public initBlock;
    uint public commitDeadline;
    uint public revealDeadline;

    uint public commitDeposit;

    constructor(uint deposit){
        initBlock = block.number;
        uint day = (24*60*60)/uint256(13);
        commitDeadline = initBlock + day;
        revealDeadline = commitDeadline + day;
        commitDeposit = deposit;
        owner = msg.sender;
    }

    function commit(bytes32 commitHash) external payable{
        
        require(block.number <= commitDeadline, "Commitment Phase is over.");
        require(committed[msg.sender] == false, "You already committed!");
        require(commitDeposit == msg.value, "Need to deposit the commitDeposit amount");

        commitments[msg.sender] = commitHash;
        committed[msg.sender] = true;

        emit CommitmentDetails(msg.sender, commitHash);
    }

    function reveal(uint bid, uint nonce) external payable{

        require(block.number > commitDeadline, "Not in Revelation Phase.");
        require(block.number <= revealDeadline, "Auction over. Reclaim your deposits.");

        require(committed[msg.sender] == true, "You did not participate in the commitment phase.");
        require(revealed[msg.sender] == false, "You already revealed your choice.");

        require(sha256(abi.encodePacked(bid, nonce)) == commitments[msg.sender], "Revelation does match CommitmentHash.");
        require(msg.value >= bid, "Deposit is less than bid amount.");

        bids[msg.sender] = bid;
        balance[msg.sender] += (bid + commitDeposit);
        revealed[msg.sender] = true;
        emit RevelationDetails(msg.sender, bid, nonce, commitments[msg.sender]);

        if (bid>bids[highest_bidder]){
            balance[owner] -= bids[highest_bidder];
            balance[highest_bidder] += bids[highest_bidder];
            highest_bidder = msg.sender;
            balance[highest_bidder] -= bids[highest_bidder];
            balance[owner] += bids[highest_bidder];
        } 
        emit CurrentHighestBidder(highest_bidder, bids[highest_bidder]);
    }

    function claimMoney() external{
        require(block.number > revealDeadline, "Auction still ongoing.");

        uint amount = balance[msg.sender];
        balance[msg.sender] = 0;
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }
 }