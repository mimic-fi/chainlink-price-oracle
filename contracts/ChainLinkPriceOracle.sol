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
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/utils/math/SafeCast.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import '@chainlink/contracts/src/v0.8/interfaces/FeedRegistryInterface.sol';

import '@mimic-fi/v1-vault/contracts/interfaces/IPriceOracle.sol';

/**
 * @title ChainLinkPriceOracle
 * @dev This price oracle contract allows anyone to query prices between two arbitrary tokens if these have
 *      been previously configured in the oracle itself.
 */
contract ChainLinkPriceOracle is IPriceOracle, Ownable {
    /**
     * @dev Emitted every time a new custom feed is set for a (base, quote) pair
     */
    event CustomFeedSet(address indexed base, address indexed quote, AggregatorV3Interface feed);

    // ChainLink feeds registry reference
    FeedRegistryInterface public immutable registry;

    // List of custom feeds set per (base, quote) pair
    mapping (address => mapping (address => AggregatorV3Interface)) public customFeeds;

    /**
     * @dev Initializes the price oracle contract
     * @param _registry ChainLink feeds registry instance
     */
    constructor(FeedRegistryInterface _registry) {
        registry = _registry;
    }

    /**
     * @dev Sets a custom feed for a (base, quote) pair
     * @param base Token to rate
     * @param quote Token used for the price rate
     * @param feed Custom feed to set
     */
    function setCustomFeed(address base, address quote, AggregatorV3Interface feed) external onlyOwner {
        customFeeds[base][quote] = feed;
        emit CustomFeedSet(base, quote, feed);
    }

    /**
     * @dev Tells if there is a custom feed set for a (base, quote) pair
     * @param base Token to rate
     * @param quote Token used for the price rate
     */
    function hasCustomFeed(address base, address quote) external view returns (bool) {
        return address(customFeeds[base][quote]) != address(0);
    }

    /**
     * @dev Tells the price of a token (base) in a given quote. The response is expressed using the corresponding
     *      number of decimals so that when performing a fixed point product of it by a `quote` amount it results in
     *      a value expressed in `base` decimals. For example, if `base` is USDC and `quote` is ETH, then the
     *      returned value is expected to be expressed using 6 decimals.
     *      Note that custom feeds are used if set, otherwise it fallbacks to ChainLink feeds registry.
     * @param base Token to rate
     * @param quote Token used for the price rate
     */
    function getTokenPrice(address base, address quote) external view override returns (uint256) {
        // If `quote * result / 1e18` must be expressed in base decimals, then
        uint8 baseDecimals = IERC20Metadata(base).decimals();
        uint8 quoteDecimals = IERC20Metadata(quote).decimals();
        require(baseDecimals + 18 >= quoteDecimals, 'QUOTE_DECIMALS_TOO_BIG');
        uint256 resultDecimals = baseDecimals + 18 - quoteDecimals;

        int256 priceInt;
        uint8 feedDecimals;
        AggregatorV3Interface feed = customFeeds[base][quote];
        if (address(feed) != address(0)) {
            (, priceInt, , , ) = feed.latestRoundData();
            feedDecimals = feed.decimals();
        } else {
            (, priceInt, , , ) = registry.latestRoundData(base, quote);
            feedDecimals = registry.decimals(base, quote);
        }

        uint256 price = SafeCast.toUint256(priceInt);
        return
            resultDecimals >= feedDecimals
                ? (SafeMath.mul(price, 10**(resultDecimals - feedDecimals)))
                : (SafeMath.div(price, 10**(feedDecimals - resultDecimals)));
    }
}
