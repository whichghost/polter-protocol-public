// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {OFT} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFT.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract PolterOft is OFT {
    uint256 public immutable maxTotalSupply;
    address public minter;

    constructor(
        string memory _name,
        string memory _symbol,
        address _lzEndpoint,
        address _delegate,
        uint256 _maxTotalSupply
    ) OFT(_name, _symbol, _lzEndpoint, _delegate) Ownable(_delegate) {
        maxTotalSupply = _maxTotalSupply;
        emit Transfer(address(0), msg.sender, 0);
    }

    function setMinter(address _minter) external returns (bool) {
        require(minter == address(0));
        minter = _minter;
        return true;
    }

    function mint(address _to, uint256 _value) external returns (bool) {
        require(msg.sender == minter);
        // _balances[_to] = _balances[_to].add(_value);
        // totalSupply = totalSupply.add(_value);
        require(maxTotalSupply >= totalSupply() + _value);
        _mint(_to, _value);
        // emit Transfer(address(0), _to, _value);
        return true;
    }
}
