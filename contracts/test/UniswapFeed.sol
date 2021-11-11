// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

//NOTE: this is for TESTING only and can be MANIPULATED
contract UniswapPriceFeed {
    address public immutable _token;
    address public immutable _weth;
    address public immutable _uniswapFactory;

    constructor(address uniswapFactory, address token, address weth) {
        _token = token;
        _weth = weth;
        _uniswapFactory = uniswapFactory;
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function _getPool(address tokenA, address tokenB) internal view returns (IUniswapV2Pair) {
        IUniswapV2Factory factory = IUniswapV2Factory(_uniswapFactory);
        address pool = factory.getPair(tokenA, tokenB);
        require(pool != address(0), 'UNISWAP_POOL_NOT_CREATED');
        return IUniswapV2Pair(pool);
    }

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        (uint256 reserve0, uint256 reserve1, ) = _getPool(_token, _weth).getReserves();
        require(reserve0 > 0 && reserve1 > 0, 'UNISWAP_POOL_NOT_INITIALIZED');
        bool isTokenIn0 = _token < _weth;
        uint256 reserveIn = isTokenIn0 ? reserve0 : reserve1;
        uint256 reserveOut = isTokenIn0 ? reserve1 : reserve0;

        uint8 dec = IERC20Metadata(_token).decimals();
        uint8 decDiff = 18 - dec;

        return (0, int256((reserveOut * 1e18) / reserveIn / 10**decDiff), 0, 0, 0);
    }
}
