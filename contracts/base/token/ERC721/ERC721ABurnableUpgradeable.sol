// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import { ERC721AUpgradeable } from "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be burned (destroyed).
 */
abstract contract ERC721ABurnableUpgradeable is Initializable, ContextUpgradeable, ERC721AUpgradeable {
    function __ERC721Burnable_init() internal onlyInitializing {}

    function __ERC721Burnable_init_unchained() internal onlyInitializing {}

    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) external virtual {
        address owner = ownerOf(tokenId);
        address sender = _msgSenderERC721A();
        require(
            (sender == owner || isApprovedForAll(owner, sender) || getApproved(tokenId) == sender),
            "ERC721A: caller is not token owner nor approved"
        );
        // require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721A: caller is not token owner nor approved");
        _burn(tokenId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
