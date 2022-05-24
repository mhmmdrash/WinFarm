// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./WinToken.sol";
import "./RenToken.sol";

contract PmknFarm {
    // userAddress => stakingBalance
    mapping(address => uint256) public stakingBalance;
    // userAddress => isStaking boolean
    mapping(address => bool) public isStaking;
    // userAddress => timeStamp
    mapping(address => uint256) public startTime;
    // userAddress => pmknBalance
    mapping(address => uint256) public winBalance;

    string public name = "WinFarm";

    RenToken public renToken;
    WinToken public winToken;

    event Stake(address indexed from, uint256 amount);
    event Unstake(address indexed from, uint256 amount);
    event YieldWithdraw(address indexed to, uint256 amount);

    constructor(RenToken _renToken, WinToken _winToken) public {
        renToken = _renToken;
        winToken = _winToken;
    }


    /// Core function shells

    function stake(uint amt) public {
        require(renToken.balanceOf(msg.sender) >= amt && amt > 0, "Cannot stake zero tokens");
        if(isStaking[msg.sender] == true){
            uint256 toTransfer = calculateYieldTotal(msg.sender);
            winBalance[msg.sender] += toTransfer;
        }
        renToken.transferFrom(msg.sender, address(this), amt);
        stakingBalance[msg.sender] += amt;
        startTime[msg.sender] = block.timestamp;
        isStaking[msg.sender] = true;
        emit Stake(msg.sender, amt);
    }


    function unstake(uint256 amount) public {
        require(
            isStaking[msg.sender] = true &&
            stakingBalance[msg.sender] >= amount, 
            "Nothing to unstake"
        );
        uint256 yieldTransfer = calculateYieldTotal(msg.sender);
        startTime[msg.sender] = block.timestamp; // bug fix
        // uint256 balanceTransfer = amount;
        // amount = 0;
        stakingBalance[msg.sender] -= amount;
        renToken.transfer(msg.sender, amount);
        winBalance[msg.sender] += yieldTransfer;
        if(stakingBalance[msg.sender] == 0){
            isStaking[msg.sender] = false;
        }
        emit Unstake(msg.sender, amount);
    }


    function viewYieldBalance() public view returns(uint) {
        uint bal = calculateYieldTotal(msg.sender);
        bal += winBalance[msg.sender];
        return bal;
    }


    function withdrawYield() public {
        uint toTransfer = calculateYieldTotal(msg.sender);
        require(
            toTransfer > 0 || 
            winBalance[msg.sender] > 0, 
            "Nothing to withdraw"
        );
        if (winBalance[msg.sender] != 0) {
            uint oldBal = winBalance[msg.sender];
            winBalance[msg.sender] = 0;
            toTransfer += oldBal;
        }
        startTime[msg.sender] = block.timestamp;
        winToken.mint(msg.sender, toTransfer);
        emit YieldWithdraw(msg.sender, toTransfer);
    }


    function calculateYieldTime(address user) public view returns (uint) {
        uint timeDif = block.timestamp - startTime[user];
        return timeDif;
    }


    function calculateYieldTotal(address user) public view returns (uint) {
        uint time = calculateYieldTime(user) * 10 ** 18;
        uint rate = 86400;
        uint timeRate = time / rate;
        uint rawYield = (stakingBalance[user] * timeRate) / 10 ** 18;
        return rawYield;
    }
}