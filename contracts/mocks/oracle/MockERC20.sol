// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;

import "../../dependencies/openzeppelin/contracts/ERC20.sol";

contract MockERC20 is ERC20 {

    constructor(string memory name, string memory symbol, uint8 decimals) ERC20(name, symbol) public {
        _setupDecimals(decimals);
        _mint(msg.sender, 1000*10**decimals);
    }

    // deposit wraps received FTM tokens as wFTM in 1:1 ratio by minting
    // the received amount of FTMs in wFTM on the sender's address.
    function deposit() public payable returns (uint256) {
        // there has to be some value to be converted
        if (msg.value == 0) {
            return 0x01;
        }

        // we already received FTMs, mint the appropriate amount of wFTM
        _mint(msg.sender, msg.value);

        // all went well here
        return 0x0;
    }

    // withdraw unwraps FTM tokens by burning specified amount
    // of wFTM from the caller address and sending the same amount
    // of FTMs back in exchange.
    function withdraw(uint256 amount) public returns (uint256) {
        // there has to be some value to be converted
        if (amount == 0) {
            return 0x01;
        }

        // burn wFTM from the sender first to prevent re-entrance issue
        _burn(msg.sender, amount);

        // if wFTM were burned, transfer native tokens back to the sender
        msg.sender.transfer(amount);

        // all went well here
        return 0x0;
    }
}
