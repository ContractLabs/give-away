//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC721Full {
    /* ========== ERRORS ========== */

    error ZeroAddress();
    error LengthMismatch();
    error AlreadyUsed();
    error NotOwner();

    struct Metadata {
        string tokenName;
    }

    event SetMetadata(address user, uint256 tokenId, Metadata metadata);

    event Registered(bytes32 uid, address user, uint256 tokenId, Metadata metadata);

    function pause() external;

    function unpause() external;

    function setBaseURI(string memory uri_) external;

    function exists(uint256 tokenId_) external view returns (bool);

    function batchMint(address account_, bytes32[] calldata uids_, Metadata[] calldata metadatas_) external;

    function setMetadata(uint256 tokenId_, Metadata memory metadatas_) external;
}
