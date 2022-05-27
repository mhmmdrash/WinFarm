// SPDX=License-Identifier: MIT
pragma solidity ^0.8;

import "./WinToken.sol";
import "./RenToken.sol";

contract WinFarm2 {

    struct staker {
        uint balance;
        bool isStaking;
        uint startTime;
        uint storedRewards;
    }
    mapping(address => staker) public stakers;
    RenToken public immutable renToken;
    WinToken public immutable winToken;

    constructor(RenToken _renToken, WinToken _winToken) {
        renToken = _renToken;
        winToken = _winToken;
    }

    function stake(uint amount) public {
        require(renToken.balanceOf(msg.sender) >= amount, "Insufficient balance");
        if(stakers[msg.sender].isStaking) {
            uint rew = calculateReward(msg.sender);
            stakers[msg.sender].storedRewards += rew;
        }
        renToken.transferFrom(msg.sender, address(this), amount);
        stakers[msg.sender].balance += amount;
        stakers[msg.sender].isStaking = true;
        stakers[msg.sender].startTime = block.timestamp;
    }

    function unstake(uint amount) public {
        require(stakers[msg.sender].balance >= amount && stakers[msg.sender].isStaking, "Nothing to unstake");
        uint rew = calculateReward(msg.sender);
        stakers[msg.sender].storedRewards += rew;
        stakers[msg.sender].balance -= amount;
        stakers[msg.sender].startTime = block.timestamp;
        renToken.transferFrom(address(this), msg.sender, amount);
        if(stakers[msg.sender].balance == 0) stakers[msg.sender].isStaking = false;
    }

    function claimRewards() public {
        uint rew = calculateReward(msg.sender);
        require(rew > 0 || stakers[msg.sender].storedRewards > 0, "NO Rewards to claim!");
        uint bal = stakers[msg.sender].storedRewards;
        stakers[msg.sender].storedRewards = 0;
        rew += bal;
        winToken.mint(msg.sender, rew);
    }

    function calculateYieldTime(address user) public view returns (uint) {
        uint timeDif = block.timestamp - stakers[user].startTime;
        return timeDif;
    }

    // rewards will be distributed 5% quarterly
    function calculateReward(address user) internal view returns(uint reward) {
        uint time = calculateYieldTime(user) * 10 ** 18;
        uint rate = 86400 * 30 * 3;
        uint timerate = time / rate;
        uint yield = stakers[user].balance * 5 / 100;
        reward = (yield * timerate) / 10 ** 18;
    }
}
