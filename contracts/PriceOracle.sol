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

import '@mimic-fi/v1-helpers/contracts/math/FixedPoint.sol';

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/utils/math/SafeCast.sol';

import './IPriceOracle.sol';

/**
 * @title PriceOracle
 * @dev This price oracle contract allows anyone to query prices between two arbitrary tokens if these have
 *      been previously configured in the oracle itself.
 */
contract ChainLinkPriceOracle is IPriceOracle, Ownable, ReentrancyGuard {
    using FixedPoint for uint256;

    // Feed to use when price is one
    address internal constant PRICE_ONE_FEED = 0x1111111111111111111111111111111111111111;

    /**
     * @dev Feed data associated to each token
     * @param tokenDecimals Tells the decimals used for a token
     * @param feed Tells the address of the ETH-quoted ChainLink feed used for a token
     */
    struct PriceFeed {
        uint8 tokenDecimals;
        AggregatorV3Interface feed;
    }

    /**
     * @dev Emitted every time a new feed is set for a token
     */
    event PriceFeedSet(address indexed token, AggregatorV3Interface feed);

    // List of feeds data indexed by token address
    mapping (address => PriceFeed) internal ethPriceFeeds;

    /**
     * @dev Initializes the price oracle contract
     * @param tokens Initial set of tokens to be configured
     * @param feeds Initial set of ChainLink feeds to be configured for each token
     */
    constructor(address[] memory tokens, AggregatorV3Interface[] memory feeds) {
        require(tokens.length == feeds.length, 'INVALID_FEEDS_LENGTH');
        for (uint256 i = 0; i < tokens.length; i++) {
            _setPriceFeed(tokens[i], feeds[i]);
        }
    }

    /**
     * @dev Sets a ChainLink feed for a token
     * @param token Token whose feed will be updated
     * @param feed ETH-quoted ChainLink feed to be set
     */
    function setPriceFeed(address token, AggregatorV3Interface feed) public nonReentrant onlyOwner {
        require(ethPriceFeeds[token].feed != feed, 'FEED_ALREADY_SET');
        _setPriceFeed(token, feed);
    }

    /**
     * @dev Tells if there is a price feed set for a token
     * @param token Token being queried
     */
    function hasPriceFeed(address token) external view returns (bool) {
        return address(getPriceFeed(token).feed) != address(0);
    }

    /**
     * @dev Tells the price feed data associated to a token
     * @param token Token being queried
     */
    function getPriceFeed(address token) public view returns (PriceFeed memory) {
        return ethPriceFeeds[token];
    }

    /**
     * @dev Tells the price of a token in a given quote
     * @param token Token being queried
     * @param quote Token used for the price rate
     */
    function getTokenPrice(address token, address quote) external view override returns (uint256) {
        (uint256 tokenPrice, uint8 tokenDecimals) = _getEthPriceIn(token);
        (uint256 quotePrice, uint8 quoteDecimals) = _getEthPriceIn(quote);

        // Price is token/quote = (ETH/quote) / (ETH/token)
        uint256 unscaledPrice = quotePrice.divDown(tokenPrice);

        return
            tokenDecimals > quoteDecimals
                ? (unscaledPrice * 10**(tokenDecimals - quoteDecimals))
                : (unscaledPrice / 10**(quoteDecimals - tokenDecimals));
    }

    /**
     * @dev Internal method to tell the price of a token expressed in ETH
     * @param token Token being queried
     */
    function _getEthPriceIn(address token) internal view returns (uint256 price, uint8 tokenDecimals) {
        AggregatorV3Interface feed;
        (feed, tokenDecimals) = _getPriceFeed(token);
        price = _getAggregatorPrice(feed);
    }

    /**
     * @dev Internal method to tell the latest price reported by a ChainLink feed
     * @param feed ChainLink feed being queried
     */
    function _getAggregatorPrice(AggregatorV3Interface feed) internal view returns (uint256) {
        if (address(feed) == PRICE_ONE_FEED) return FixedPoint.ONE;
        (, int256 priceInt, , , ) = feed.latestRoundData();
        return SafeCast.toUint256(priceInt);
    }

    /**
     * @dev Internal method to fetch the ETH-quoted ChainLink feed for a token. It reverts if the feed is not set.
     * @param token Token being queried
     */
    function _getPriceFeed(address token) internal view returns (AggregatorV3Interface feed, uint8 tokenDecimals) {
        PriceFeed memory priceFeed = getPriceFeed(token);
        feed = priceFeed.feed;
        tokenDecimals = priceFeed.tokenDecimals;
        require(address(feed) != address(0), 'TOKEN_WITH_NO_FEED');
    }

    /**
     * @dev Internal method to set an ETH-quoted ChainLink feed for a token
     * This version of the price oracle only handles prices expressed with 18 decimals
     * If the feed is address 0x11..11, it will have a constant price of one
     * If the feed is address 0x00..00, it will be disabled
     * @param token Token whose feed will be updated
     * @param feed ETH-quoted ChainLink feed to be set
     */
    function _setPriceFeed(address token, AggregatorV3Interface feed) private {
        bool uses18Decimals = address(feed) == PRICE_ONE_FEED || address(feed) == address(0) || feed.decimals() == 18;
        require(uses18Decimals, 'INVALID_FEED_DECIMALS');

        uint8 tokenDecimals = IERC20Metadata(token).decimals();
        ethPriceFeeds[token] = PriceFeed({ feed: feed, tokenDecimals: tokenDecimals });
        emit PriceFeedSet(token, feed);
    }
}
