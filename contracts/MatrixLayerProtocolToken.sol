// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MatrixLayerProtocolToken is ERC20, ERC20Burnable, Ownable {
    uint256 private constant INITIAL_SUPPLY = 2_000_000_000 * 10 ** 18; // 2 billion tokens

    constructor() ERC20("Matrix Layer Protocol", "MLP") Ownable(msg.sender) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
}
