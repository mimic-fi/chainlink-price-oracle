// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract FeedMock {
    uint8 internal _decimals;
    int256 internal _price;

    constructor(int256 newPrice, uint8 newDecimals) {
        _price = newPrice;
        _decimals = newDecimals;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80) {
        return (0, _price, 0, 0, 0);
    }
}
