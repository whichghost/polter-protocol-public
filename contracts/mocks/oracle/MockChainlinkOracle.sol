// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;

import "../../interfaces/IChainlinkAggregator.sol";

contract MockChainlinkOracle is IChainlinkAggregator {

  function decimals() external view override returns (uint8) {
    return 8;
  }
  function description() external view override returns (string memory) {
    return 'mock';
  }
  function version() external view override returns (uint256) {
    return 1;
  }

  int256 private _price = 0;

  constructor(int256 price) {
    _price = price;
  }

  function setPrice(int256 newPrice) external {
    _price = newPrice;
  }

  function getRoundData(uint80 _roundId)
    external
    view
    override
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    ) {
        return (roundId + 1, _price, block.timestamp - 100, block.timestamp - 200, 1);
    }

  function latestRoundData()
    external
    view
    override
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    ) {
        return (3, _price, 3, block.timestamp - 3, 3);
    }
}
