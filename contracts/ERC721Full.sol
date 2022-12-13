// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { BitMapsUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {
    ERC721EnumerableUpgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import {
    ERC721BurnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import { ERC721URIStorageUpgradeable } from "./base/token/ERC721/ERC721URIStorageUpgradeable.sol";
import { ERC721WithPermitUpgradable } from "./base/token/ERC721/ERC721WithPermitUpgradable.sol";

import { IERC721Full } from "./interfaces/IERC721Full.sol";

import { Helper } from "./libraries/Helper.sol";

contract SamuraiggNFT is
    IERC721Full,
    Initializable,
    AccessControlUpgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    ERC721WithPermitUpgradable,
    ERC721BurnableUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    using BitMapsUpgradeable for BitMapsUpgradeable.BitMap;
    using Helper for bytes32;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    uint256 private _idCounter;
    mapping(uint256 => Metadata) private _metadatas;
    BitMapsUpgradeable.BitMap private _isUsed;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        address sender = _msgSender();
        __AccessControl_init();
        __Pausable_init();
        __ERC721WithPermitUpgradable_init("SamuraiggNFT", "SGG");
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, sender);
        _grantRole(PAUSER_ROLE, sender);
        _grantRole(UPGRADER_ROLE, sender);
        _grantRole(MINTER_ROLE, sender);
        _idCounter = 1;
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function setBaseURI(string memory uri_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setBaseURI(uri_);
    }

    function batchMint(
        address account_,
        bytes32[] calldata uids_,
        Metadata[] calldata metadatas_
    ) external onlyRole(MINTER_ROLE) {
        if (uids_.length != metadatas_.length) revert LengthMismatch();
        _batchMint(account_, uids_, metadatas_);
    }

    function safeMint(bytes32 uid_, address account_, Metadata memory metadata_) external onlyRole(MINTER_ROLE) {
        uint256 tokenId = _idCounter;
        _checkUnique(uid_);
        _metadatas[tokenId] = Metadata({ tokenName: metadata_.tokenName });
        _safeMint(account_, tokenId);
        emit Registered(uid_, account_, tokenId, metadata_);
        _idCounter = ++tokenId;
    }

    function setMetadata(uint256 tokenId_, Metadata memory metadata_) external {
        address user = _msgSender();
        if (ownerOf(tokenId_) != user) revert NotOwner();
        _metadatas[tokenId_] = Metadata({ tokenName: metadata_.tokenName });
        emit SetMetadata(user, tokenId_, metadata_);
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function metadata(uint256 tokenId) external view returns (Metadata memory) {
        return _metadatas[tokenId];
    }

    function isUsed(bytes32 uid) external view returns (bool) {
        return _isUsed.get(uid.toUint256());
    }

    function _batchMint(address account_, bytes32[] calldata uids_, Metadata[] calldata metadatas_) internal {
        uint256 length = uids_.length;
        uint256 tokenId = _idCounter;
        for (uint256 i; i < length; ) {
            unchecked {
                _checkUnique(uids_[i]);
                _metadatas[tokenId] = Metadata({ tokenName: metadatas_[i].tokenName });
                _safeMint(account_, tokenId);
                emit Registered(uids_[i], account_, tokenId, metadatas_[i]);
                ++tokenId;
                ++i;
            }
        }
        _idCounter = tokenId;
    }

    function _checkUnique(bytes32 uid_) internal {
        uint256 uid = uid_.toUint256();
        if (_isUsed.get(uid)) revert AlreadyUsed();
        _isUsed.setTo(uid, true);
    }

    function _transfer(
        address from_,
        address to_,
        uint256 tokenId_
    ) internal override(ERC721Upgradeable, ERC721WithPermitUpgradable) {
        super._transfer(from_, to_, tokenId_);
    }

    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 tokenId_
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) whenNotPaused {
        super._beforeTokenTransfer(from_, to_, tokenId_);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    function _burn(uint256 tokenId) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(AccessControlUpgradeable, ERC721EnumerableUpgradeable, ERC721Upgradeable, ERC721WithPermitUpgradable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view override(ERC721URIStorageUpgradeable, ERC721Upgradeable) returns (string memory) {
        return _baseUri;
    }
}
