pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/bitify.circom";
include "merkleTree.circom";

template Withdraw(levels) {
    // public
    signal input root;
    signal input nullifierHash;
    
    // not taking part in any computations
    signal input recipient; 
    signal input token;
    signal input value;      
    
    // private
    signal input nullifier; 
    signal input pathElements[levels];
    signal input pathIndices[levels];

    component leafIndexNum = Bits2Num(levels);
    for (var i = 0; i < levels; i++) {
        leafIndexNum.in[i] <== pathIndices[i];
    }

    component nullifierHasher = Poseidon(2);
    nullifierHasher.inputs[0] <== nullifier;
    nullifierHasher.inputs[1] <== leafIndexNum.out;
    nullifierHasher.out === nullifierHash; // compare

    component commitmentHasher = Poseidon(2);
    commitmentHasher.inputs[0] <== nullifier;
    commitmentHasher.inputs[1] <== 0;

    component tree = MerkleTreeChecker(levels);
    tree.leaf <== commitmentHasher.out;
    tree.root <== root;
    for (var i = 0; i < levels; i++) {
        tree.pathElements[i] <== pathElements[i];
        tree.pathIndices[i] <== pathIndices[i];
    }

    // Add hidden signals to make sure that tampering with recipient or fee will invalidate the snark proof
    // Most likely it is not required, but it's better to stay on the safe side and it only takes 2 constraints
    // Squares are used to prevent optimizer from removing those constraints
    signal recipientSquare;
    signal tokenSquare;
    signal valueSquare;
    recipientSquare <== recipient * recipient;
    tokenSquare <== token * token;
    valueSquare <== value * value;
}

component main {public [root,nullifierHash,recipient,token,value]} = Withdraw(10);
