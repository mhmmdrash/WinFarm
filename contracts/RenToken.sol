// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RenToken is ERC20, ERC20Burnable, Ownable {
    address public admin;
    constructor() ERC20("Ren Token", "REN") {
        admin = msg.sender;
        mint(admin, 10000 * 10 ** 18);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function burn(address account, uint amount) public {
        _burn(account, amount);
    }
}