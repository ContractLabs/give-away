// SPDX-License-Identifier: MIT
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

pragma solidity ^0.8.10;

contract PaymentToken {
    event PaymentTokensAdded(address[] indexed tokens);
    event PaymentTokensCancel(address[] indexed tokens);

    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet internal _paymentTokenAddressSet;

    modifier onlyAcceptedToken(address token_) {
        require(_acceptedToken(token_), "Payment: not accept");
        _;
    }

    function acceptedToken(address token) external view returns (bool) {
        return _acceptedToken(token);
    }

    function viewPaymentTokensCount() public view returns (uint256) {
        return _paymentTokenAddressSet.length();
    }

    function viewPaymenTokens(
        uint256 cursor,
        uint256 size
    ) external view returns (address[] memory paymentTokenAddresses, uint256) {
        uint256 length = size;
        if (length > _paymentTokenAddressSet.length() - cursor) length = _paymentTokenAddressSet.length() - cursor;
        paymentTokenAddresses = new address[](length);
        for (uint256 i = 0; i < length; ) {
            paymentTokenAddresses[i] = _paymentTokenAddressSet.at(cursor + i);
            unchecked {
                ++i;
            }
        }
        return (paymentTokenAddresses, cursor + length);
    }

    function _acceptPaymentTokens(address[] memory addresses_) internal {
        uint256 length = addresses_.length;
        for (uint256 i = 0; i < length; ) {
            address tokenAddress = addresses_[i];
            require(!_paymentTokenAddressSet.contains(tokenAddress), "Payment: already added");
            _paymentTokenAddressSet.add(tokenAddress);
            unchecked {
                ++i;
            }
        }
        emit PaymentTokensAdded(addresses_);
    }

    function _cancelPaymentTokens(address[] calldata addresses_) internal {
        uint256 length = addresses_.length;
        for (uint256 i = 0; i < length; ) {
            address tokenAddress = addresses_[i];
            require(_paymentTokenAddressSet.contains(tokenAddress), "Payment: not exist");
            _paymentTokenAddressSet.remove(tokenAddress);
            unchecked {
                ++i;
            }
        }
        emit PaymentTokensCancel(addresses_);
    }

    function _acceptedToken(address token) internal view returns (bool) {
        return _paymentTokenAddressSet.contains(token);
    }

    function _viewTokenByIndex(uint256 index) internal view returns (address) {
        return _paymentTokenAddressSet.at(index + 1);
    }
}
