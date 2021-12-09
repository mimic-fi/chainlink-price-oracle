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

import '@openzeppelin/contracts/utils/math/SafeCast.sol';
import '@mimic-fi/v1-vault/contracts/libraries/FixedPoint.sol';
import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';

interface IWstEth {
    function stEthPerToken() external view returns (uint256);
}

contract WstEthFeed {
    using FixedPoint for uint256;

    IWstEth public constant wstEth = IWstEth(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);
    AggregatorV3Interface public constant stEthChainlinkFeed =
        AggregatorV3Interface(0x86392dC19c0b719886221c78AB11eb8Cf5c52812);

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        uint256 rate = wstEth.stEthPerToken();
        (, int256 stEthPrice, , , ) = stEthChainlinkFeed.latestRoundData();
        int256 price = SafeCast.toInt256(rate.mul(SafeCast.toUint256(stEthPrice)));

        return (0, price, 0, 0, 0);
    }
}
