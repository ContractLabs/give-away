// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC721Bridge {
    struct BridgeNFTInfo {
        uint256 nativeChainId;
        address tokenAddress;
    }

    struct NativeNFTInfo {
        uint256 chainId; // original chainId
        address tokenAddress; // NFT collection's address on the original (native) chain
        bytes metadata; // NFT's metadata
    }

    error AdminBadRole();

    error WrongArgument();
    error ZeroAddress();
    error ZeroChainId();
    error ChainToIsNotSupported();
    error NotReceivedERC721();
    error Unreachable();
    error AlreadyAdded();

    /* ========== EVENTS ========== */

    event AddedChainSupport(uint256 chainId);
    event RemovedChainSupport(uint256 chainId);
    event BridgeAdded(uint256 nativeChainId, address nativeAddress, uint256 secondaryChaind, address secondAddress);
    event BridgeRemoved(bytes32 bridgeId);

    /// @param tokenAddress NFT collection's address on the current chain
    event NFTSent(address tokenAddress, uint256 tokenId, address receiver, uint256 chainIdTo);

    /// @param tokenAddress NFT collection's address on the native chain
    event NFTClaimed(bytes32 submissionId, address tokenAddress, uint256 tokenId, address receiver);

    /// @param tokenAddress NFT collection's address on the current chain
    event NFTMinted(bytes32 submissionId, address tokenAddress, uint256 tokenId, address receiver, string tokenUri);

    /* ========== FUNCTIONS ========== */

    function deposit(
        address collectionAddress_,
        uint256 tokenId_,
        uint256 deadline_,
        bytes calldata permitSignature_,
        uint256 chainIdTo_,
        address recipientAddress_
    ) external;

    function claimOrMint(
        bytes32 submissionId_,
        uint256 tokenId_,
        address receiver_,
        string calldata tokenUri_,
        NativeNFTInfo calldata tokenInfo_
    ) external;

    function addBridge(
        uint256 nativeChainId_,
        address nativeAddress_,
        uint256 secondaryChaind_,
        address secondAddress_
    ) external;

    function removeBridge(bytes32 bridgeId_) external;

    function addChainSupport(uint256 chainIdTo_, address nativeCollection_) external;

    function removeChainSupport(uint256 chainIdTo_, address nativeCollection_) external;
}
