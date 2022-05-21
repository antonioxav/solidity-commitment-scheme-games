// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Test{
    function createHash(uint nonce, uint bid) public pure returns (bytes32){
        return sha256(abi.encodePacked(bid, nonce));
    }
}