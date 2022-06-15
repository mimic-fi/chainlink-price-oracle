// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract RegistryMock {
    uint8 internal _decimals;
    int256 internal _price;

    function mockPrice(int256 newPrice, uint8 newDecimals) external {
        _price = newPrice;
        _decimals = newDecimals;
    }

    function decimals(address, address) external view returns (uint8) {
        return _decimals;
    }

    function latestRoundData(address, address) external view returns (uint80, int256, uint256, uint256, uint80) {
        return (0, _price, 0, 0, 0);
    }
}
