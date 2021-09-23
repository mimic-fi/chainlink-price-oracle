// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/utils/math/SafeCast.sol';

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';

import '@mimic-fi/v1-vault/contracts/libraries/FixedPoint.sol';
import '@mimic-fi/v1-vault/contracts/interfaces/IPriceOracle.sol';

contract ChainLinkPriceOracle is IPriceOracle, Ownable, ReentrancyGuard {
    using FixedPoint for uint256;

    // Feed to use when price is one
    address internal constant PRICE_ONE_FEED = 0x1111111111111111111111111111111111111111;

    struct PriceFeed {
        uint8 tokenDecimals;
        AggregatorV3Interface feed;
    }

    mapping (address => PriceFeed) internal ethPriceFeeds;

    event PriceFeedSet(address token, AggregatorV3Interface feed);

    constructor(address[] memory tokens, AggregatorV3Interface[] memory feeds) {
        require(tokens.length == feeds.length, 'INVALID_FEEDS_LENGTH');

        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            AggregatorV3Interface feed = feeds[i];

            _setPriceFeed(token, feed);
        }
    }

    function hasPriceFeed(address token) external view returns (bool) {
        return address(getPriceFeed(token).feed) != address(0);
    }

    function getPriceFeed(address token) public view returns (PriceFeed memory) {
        return ethPriceFeeds[token];
    }

    function getTokenPrice(address token, address base) external view override returns (uint256) {
        (uint256 basePrice, uint8 baseDecimals) = _getEthPriceIn(base);
        (uint256 tokenPrice, uint8 tokenDecimals) = _getEthPriceIn(token);

        // Price is token/base = (ETH/base) / (ETH/token)
        uint256 unscaledPrice = basePrice.div(tokenPrice);

        return
            tokenDecimals > baseDecimals
                ? (unscaledPrice * 10**(tokenDecimals - baseDecimals))
                : (unscaledPrice / 10**(baseDecimals - tokenDecimals));
    }

    function _getEthPriceIn(address token) internal view returns (uint256 price, uint8 tokenDecimals) {
        AggregatorV3Interface feed;
        (feed, tokenDecimals) = _getPriceFeed(token);
        price = _getAggregatorPrice(feed);
    }

    function _getAggregatorPrice(AggregatorV3Interface feed) internal view returns (uint256) {
        if (address(feed) == PRICE_ONE_FEED) return FixedPoint.ONE;
        (, int256 priceInt, , , ) = feed.latestRoundData();
        return SafeCast.toUint256(priceInt);
    }

    function _getPriceFeed(address token) internal view returns (AggregatorV3Interface feed, uint8 tokenDecimals) {
        PriceFeed memory priceFeed = getPriceFeed(token);
        feed = priceFeed.feed;
        tokenDecimals = priceFeed.tokenDecimals;
        require(address(feed) != address(0), 'TOKEN_WITH_NO_FEED');
    }

    function setPriceFeed(address token, AggregatorV3Interface feed) public nonReentrant onlyOwner {
        require(ethPriceFeeds[token].feed != feed, 'FEED_ALREADY_SET');

        _setPriceFeed(token, feed);
    }

    //Private

    // This version of the price oracle only handles 18 decimals prices
    // If a price feed is address 0x11..11, it will have a price of one
    // If a price feed is address 0x00..00, it will be disabled
    function _setPriceFeed(address token, AggregatorV3Interface feed) private {
        bool worksWith18Decimals = address(feed) == PRICE_ONE_FEED ||
            address(feed) == address(0) ||
            feed.decimals() == 18;

        require(worksWith18Decimals, 'INVALID_FEED_DECIMALS');

        uint8 tokenDecimals = IERC20Metadata(token).decimals();
        ethPriceFeeds[token] = PriceFeed({ feed: feed, tokenDecimals: tokenDecimals });

        emit PriceFeedSet(token, feed);
    }
}
