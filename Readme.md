# Commitment Scheme Games and Auctions

## Rock Paper Scissors

### Protocol

#### Commitment Phase
1. Game starts as soon as contract is created.
2. Alice and Bob have 10 minutes to submit their commit hashes, along with the deposit. Commit Hashes are sha256 hashes of their choice and a randomly selected nonce.
3. Game verfies that the hash was actually sent by either Alice or Bob.
4. Once both of them submit their hashes, then game moves on to the Revelation Phase.
5. If anyone fails to submit their commit hashes by the deadline, then the game directly moves to the GameOver phase (where the player can reclaim their deposit).

#### Revelation Phase
6. Alice and Bob have (game start + 20mins) to reveal their original choices. This phase only begins once the commitment phase has concluded.
7. Alice and Bob submit their choice and nonce.
8. Game calculates whether the sha256 hash of a player's choice and nonce match their previous commitment (Step 2). If not, then the player is assumed to have cheated and loses. Game moves to GameOver Phase.

#### Decision Phase
9. Once both Alice and Bob have submitted valid hashes in the Revelation Phase or once revelation deadlines passes, this phase begins.
10. Anyone can call this function. There is incentive for at least one player to call this function, since they need to claim their deposit or have already won.
11. The smart contract calculates the winner based on the rules of Rock-Paper-Scissor.
12. If both players miss the revelation deadline, then its a tie. If only one player misses the deadline, then their opponent wins.
13. Game proceeds to GameOver Phase.

#### GameOver Phase
13. Players can claim their winnings/deposits (if any).

### Ways for players or any third-party to cheat and how it is detected.
|Method for Cheating   |Avoided/Detected   |How is it Avoided/Detected
|---|---|---|
Deciphering the other player's choice before announcing yours | Avoided| Both players submit a hash of their choices so the actual choice is not decipherable. 2. The hash also includes a randomly chosen nonce, so the choice cannot be reversed engineered based on the hash of the choice alone (without the nonce, the choice can be easily deduced from its hash via brute force since there are only 3 possible choices).|
Changing your choice once the other player's choice is revealed| Detected| The hash of the choice and nonce announced by each player in revelation phase must match the original hash announced in commitment. If they don't match, its presumed that the player is cheating.|
Impersonating the other player to submit a choice on their behalf in commitment phase. (applies for 3rd party adversaries as well)| Avoided| Game ensures that only transactions created (and thus, signed) by the player can call the commit function.|
Impersonating the other player to submit a random choice and nonce in revelation phase to make the protocol believe that they are cheating. (applies for 3rd party adversaries as well)| Avoided| Game ensures that only transactions created (and thus, signed) by the player can call the reveal function.|
Intentionally missing commitment deadline so other player loses deposit| Detected| Deposit is returned.


## Blind Auction

### 1. Protocol
#### Commitment Phase
1. Owner creates contract and specifies a deposit amount (commitDeposit) to participate in the auction. This deposit is the owner's estimation of the highest bid he can expect.
2. Auction starts as soon as contract is created.
2. Bidders have 24hrs to submit their commit hashes along with the commitDeposit. Commit Hashes are sha256 hashes of their bid and a randomly selected nonce.
3. Auction verfies that the hash was actually sent by the account that created and signed transaction.
4. Event is created disclosing each bidder's commit hash.
5. Commitment Phase concludes after 24hrs.

#### Revelation Phase
6. Existing bidders have a further 24hrs to reveal their bids. This phase only begins once the commitment phase has concluded.
7. Each bidder submits their choice and nonce. They must also deposit their bid amount (this is okay since other bidders can no longer change their bids.)
8. Contract calculates whether the sha256 hash of a bidder's bid and nonce match their previous commitment (Step 3). If not, then the function returns an error.
9. Each bidder that reveals their bid gets a refund on the commitDeposit. Bidders who do not reveal lose their deposit.
9. Event is created disclosing each bidder's bid, nonce and previous commit hash for independant verification.
10. Highest Bidder is calculated each time the function is called. An event is emitted after each function call disclosing the current highest bidder.
11. Owner's balance is equal to the current highest bid.
11. Auction cocludes after a further 24hrs.

#### AuctionOver Phase
14. The highest bidder once auction concludes is the winner of the auction.
13. All bidders, except the highest bidder, can reclaim their bid deposits. Only bidders that revealed their nonce can reclaim their commitDeposits.
16. The owner can reclaim the highest bid as well as any commitDeposits from bidders that did not reveal their bid.

### 2. Ensuring that the highest bidder always pays
We ensure that the highest bidder always pays since they have to deposit their bid amount during the revelation phase. Bidders are punished from entering multiple bids in the commitment phase and selectively revealing based on the highest bid. This is because they will lose their deposit for each bid that is not revealed. Moreover, the auction owner is incentivized to place a high commitmentDeposit, higher than his percieved value of the item (since they receive any deposit from unrevealed bids). However, they are also incentivised to not keep it obscenely high otherwise legitimate buyers would not participate in the auction. Thus, the commitDeposit is high enough w.r.t. the bids that it is not rationally feasible to place several bids and reveal selectively. 

For example, if the owner expects the <b>highest</b> bid to be 10eth, he/she will set the commitmentDeposit accordingly. Let Alice be a malicious bidder who sends two seperate bids from two different accounts, x and y, with y>x=10eth. She submits a deposit of 20eth in total. During the revelation phase, she finds that the highest bid so far is 9eth. She would like to only reveal x=10eth and win at a lower bid, however that would mean losing her 10eth deposit on bid y as well, costing her x+10eth=20eth on the total transaction. The only way this is rationally feasible is if $y-x>commitmentDeposit$. As long as commitmentDeposit is > than the highest expected bid by the owner, the probability of Alice cheating is quite low.

### 3. Maximum expected gas.
It is constant because time complexity of all functions is O(1).



