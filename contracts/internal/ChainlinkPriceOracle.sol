// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { IAggregatorV3 } from "../interfaces/IAggregatorV3.sol";

contract ChainlinkPriceOracle {
    event SetPriceFeeds(address token, address priceFeed);

    mapping(address => IAggregatorV3) internal _priceFeeds;

    constructor() {
        _setPriceFeeds(address(0), 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e); // ETH
        _setPriceFeeds(0x650EcAEA321482fF342fbDD011E740D8B54891d0, 0xAb5c49580294Aff77670F839ea425f5b78ab3Ae7); // USDT
    }

    function getPrice(address token) external view returns (uint256) {
        return _getPrice(token);
    }

    function _getPrice(address token) internal view returns (uint256) {
        (, int256 price, , , ) = _priceFeeds[token].latestRoundData();
        return uint256(price * 1e10);
    }

    function _getTokenAmount(address token, uint256 usdAmount) internal view returns (uint256) {
        uint256 price = _getPrice(token);
        return (usdAmount * 1 ether) / price;
    }

    function _getUsdAmount(address token, uint256 amount) internal view returns (uint256) {
        uint256 price = _getPrice(token);
        return (amount * price) / 1 ether;
    }

    function _setPriceFeeds(address token_, address priceFeed_) internal {
        _priceFeeds[token_] = IAggregatorV3(priceFeed_);
        emit SetPriceFeeds(token_, priceFeed_);
    }
}
