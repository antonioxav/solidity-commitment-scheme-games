// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Rps
 * @dev One-time rock paper scissors game between Alice and Bob.
 **/
 contract Rps{

    address payable alice = payable(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
    address payable bob = payable(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2);

    enum Choice {
        None, // Default value.
        Rock,
        Paper,
        Scissors
    }

    // State Variables
    enum GameState {
        Commitment,
        Revelation,
        Decision,
        GameEnd
    }

    GameState public gameState = GameState.Commitment;    

    mapping(address => bytes32) public commitments;
    mapping(address => Choice) public choices;
    mapping(address => uint) public balance;

    mapping(address => bool) committed;
    mapping(address => bool) revealed;

    // Events
    event CommitmentDetails(address player, bytes32 commitment);
    event RevelationDetails(address player, Choice choice, bytes32 nonce, bytes32 commitmentHash);
    event GameOver(string message);

    modifier onlyPlayers(){
        require(msg.sender==alice || msg.sender==bob);
        _;
    }

    uint public initBlock;
    uint public commitDeadline;
    uint public revealDeadline;

    constructor(){
        initBlock = block.number;
        uint ten_mins = (10*60)/uint256(13);
        commitDeadline = initBlock + ten_mins;
        revealDeadline = commitDeadline + ten_mins;
    }

    function commit(bytes32 commitHash) external onlyPlayers payable{
        
        require(gameState == GameState.Commitment && block.number <= commitDeadline, "Commitment Phase is over.");

        // //12-14s per block. 10 minutues for Commitment Phase.
        // if ((block.number - init_block)*13 > 10*60){ 
        //     // At least one player missed deadline.
        //     gameState = GameState.GameEnd;  
        //     return;          
        //     // revert("Commitment Phase is over. One player missed deadline. Call claimMoney to refund deposit.");
        // }

        require(msg.value==1 ether, "Need to deposit exactly 1 ether");
        require(committed[msg.sender] == false, "You already committed!");

        commitments[msg.sender] = commitHash;
        balance[msg.sender] = 1 ether;
        committed[msg.sender] = true;
        emit CommitmentDetails(msg.sender, commitHash);

        if (committed[bob] && committed[alice]) gameState = GameState.Revelation;

        emit CommitmentDetails(msg.sender, commitHash);
    }

    function reveal(Choice choice, bytes32 nonce) external onlyPlayers{

        require(gameState == GameState.Revelation || (gameState == GameState.Commitment && block.number > commitDeadline), "Not in Revelation Phase");
        require(block.number <= revealDeadline, "Not in Revelation Phase");

        if (gameState == GameState.Commitment && block.number > commitDeadline){
            gameState = GameState.GameEnd; 
            emit GameOver("At least one player missed commit deadline");
            return; 
        }

        // //12-14s per block. 10 minutes for Revelation Phase.
        // if ((block.number - init_block)*13 > 20*60){ 
        //     gameState = GameState.Decision;
        //     return;
        //     // revert("Revelation Phase is over.");
        // }

        require(revealed[msg.sender] == false, "You already revealed your choice.");

        if (sha256(abi.encodePacked(choice, nonce)) == commitments[msg.sender]){
            choices[msg.sender] = choice;
            revealed[msg.sender] = true;

            if (revealed[bob] && revealed[alice]) gameState = GameState.Decision;
            emit RevelationDetails(msg.sender, choice, nonce, commitments[msg.sender]);
        }
        else {
            // Caught cheating. Instant Loss.
            if (msg.sender == alice) balance[bob] += balance[alice];
            else balance[alice] += balance[bob];
            balance[msg.sender] = 0;
            gameState = GameState.GameEnd;
            emit GameOver("Player caught cheating. Instant Loss.");
        }
    }

    function decideWinner() external {
        require(gameState == GameState.Decision || ((gameState == GameState.Commitment || gameState == GameState.Revelation) && block.number > revealDeadline), "Not in Decision Phase");

        if (gameState == GameState.Commitment && block.number > commitDeadline){
            // At least one player missed commit deadline.
            gameState = GameState.GameEnd; 
            emit GameOver("At least one player missed commit deadline"); 
            return; 
        }

        Choice bobChoice = choices[bob];
        Choice aliceChoice = choices[alice];
        
        address payable winner;
        address payable loser;
        bool tie = false;

        if (aliceChoice == Choice.None){ // None is when revelation is not done within deadline
            if (bobChoice == Choice.None) tie = true;
            else {
                winner = bob;
                loser = alice;
            }
        }

        else if (aliceChoice == Choice.Rock){
            if (bobChoice == Choice.Paper){
                winner = bob;
                loser = alice;
            }
            else if (bobChoice == Choice.Rock) tie = true;
            else {
                winner = alice;
                loser = bob;
            }
        }

        else if (aliceChoice == Choice.Paper){
            if (bobChoice == Choice.Scissors){
                winner = bob;
                loser = alice;
            }
            else if (bobChoice == Choice.Paper) tie = true;
            else {
                winner = alice;
                loser = bob;
            }
        }
    
        else if (aliceChoice == Choice.Scissors){
            if (bobChoice == Choice.Rock){
                winner = bob;
                loser = alice;
            }
            else if (bobChoice == Choice.Scissors) tie = true;
            else {
                winner = alice;
                loser = bob;
            }
        }

        // transfer funds
        if (!tie){
            balance[winner] += balance[loser];
            balance[loser] = 0;
        }

        gameState = GameState.GameEnd;
        emit GameOver("Game Settled. Claim Money.");
    }

    function claimMoney() external onlyPlayers{
        uint amount = balance[msg.sender];
        balance[msg.sender] = 0;
        (bool sent, bytes memory data) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }
 }