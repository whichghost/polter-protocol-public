// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;

import "../../interfaces/IBandStdReference.sol";

contract MockBandOracle is IBandStdReference {

    uint256 private _price = 0;

    constructor(uint256 price) {
        _price = price;
    }

    function setPrice(uint256 newPrice) external {
        _price = newPrice;
    }

    function getReferenceData(string memory _base, string memory _quote)
        external
        view
        override
        returns (uint256 rate, uint256 lastUpdatedBase, uint256 lastUpdatedRate) {
            return (_price, 1, 1);
        }
}
