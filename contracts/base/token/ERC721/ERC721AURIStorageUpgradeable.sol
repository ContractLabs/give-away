// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import { ERC721AUpgradeable } from "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721AURIStorageUpgradeable is Initializable, ERC721AUpgradeable {
    // using StringsUpgradeable for uint256;

    function __ERC721URIStorage_init() internal onlyInitializing {}

    function __ERC721URIStorage_init_unchained() internal onlyInitializing {}

    string internal _baseUri;

    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    function _setBaseURI(string memory baseUri_) internal virtual {
        _baseUri = baseUri_;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}
