// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {
    ReentrancyGuardUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { BitMapsUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ERC165Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import { IERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import { IVerifier } from "./interfaces/IVerifier.sol";
import { IZkpLink } from "./interfaces/IZkpLink.sol";
import { CurrencyTransferLib } from "./libraries/CurrencyTransferLib.sol";

contract ZkpLink is
    Initializable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    IZkpLink
{
    using BitMapsUpgradeable for BitMapsUpgradeable.BitMap;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    IVerifier public verifier;
    mapping(address => address) public vaults;
    BitMapsUpgradeable.BitMap private _nullifierHashes;
    BitMapsUpgradeable.BitMap private _roots;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(IVerifier verifier_) public initializer {
        address sender = _msgSender();
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, sender);
        _grantRole(PAUSER_ROLE, sender);
        _grantRole(UPGRADER_ROLE, sender);
        _grantRole(OPERATOR_ROLE, sender);

        _setVerifier(verifier_);
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function addRoot(uint256 root_) external onlyRole(OPERATOR_ROLE) {
        _addRoot(root_);
    }

    function setVerifier(IVerifier verifier_) external onlyRole(OPERATOR_ROLE) {
        _setVerifier(verifier_);
    }

    function setVaults(address[] calldata tokens_, address[] calldata vaults_) external onlyRole(OPERATOR_ROLE) {
        uint256 length = tokens_.length;
        if (length != vaults_.length) revert ZKPL__LengthMismatch();

        for (uint256 i; i < length; ) {
            vaults[tokens_[i]] = vaults_[i];
            unchecked {
                ++i;
            }
        }
    }

    function isSpent(uint256 nullifierHash_) external view returns (bool) {
        return _nullifierHashes.get(nullifierHash_);
    }

    function withdraw(
        Proof calldata proof_,
        WithdrawInput calldata withdrawInput_
    ) external payable override nonReentrant whenNotPaused {
        if (!_roots.get(withdrawInput_.root)) revert ZKPL__InvalidRoot();

        if (_nullifierHashes.get(withdrawInput_.nullifierHash)) revert ZKPL__AlreadySpent();

        if (!_verifyProof(proof_, withdrawInput_)) revert ZKPL__InvalidProof();

        _nullifierHashes.setTo(withdrawInput_.nullifierHash, true);
        _processWithdraw(withdrawInput_.recipient, withdrawInput_.asset, withdrawInput_.value);

        emit Withdrawn(
            withdrawInput_.asset,
            withdrawInput_.recipient,
            withdrawInput_.value,
            withdrawInput_.nullifierHash
        );
    }

    function _addRoot(uint256 root_) internal {
        _roots.setTo(root_, true);
        emit RootAdded(root_);
    }

    function _setVerifier(IVerifier verifier_) internal {
        if (address(verifier_) == address(0)) revert ZKPL__ZeroAddress();
        emit VerifierUpdated(verifier, verifier_);
        verifier = verifier_;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    function _verifyProof(Proof calldata proof_, WithdrawInput calldata withdrawInput_) private view returns (bool) {
        return
            verifier.verifyProof(
                proof_.a,
                proof_.b,
                proof_.c,
                [
                    withdrawInput_.root,
                    withdrawInput_.nullifierHash,
                    uint256(uint160(withdrawInput_.recipient)),
                    uint256(uint160(withdrawInput_.asset)),
                    withdrawInput_.value
                ]
            );
    }

    function _processWithdraw(address recipient_, address asset_, uint256 value_) internal {
        if (ERC165Upgradeable(asset_).supportsInterface(0x80ac58cd)) {
            IERC721Upgradeable(asset_).safeTransferFrom(vaults[asset_], recipient_, value_);
        } else {
            CurrencyTransferLib.transferCurrency(asset_, vaults[asset_], recipient_, value_);
        }
    }
}
