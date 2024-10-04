// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract TokenVesting is Ownable {
    IERC20 public token;

    struct VestingSchedule {
        uint256 totalAmount; // Total tokens to be vested
        uint256 released; // Tokens already released
        uint256 startTime; // Vesting start time
        uint256 duration; // Vesting duration (seconds)
    }

    mapping(address => VestingSchedule) public vestingSchedules;

    event TokensRelease(address indexed beneficiary, uint256 indexed amount);
    event TokenVest(address indexed beneficiary, uint256 indexed amount);

    constructor(address _token, address _owner) Ownable(_owner) {
        token = IERC20(_token);
    }

    // Set up a vesting schedule for a beneficiary
    function setVestingSchedule(address _beneficiary, uint256 _totalAmount, uint256 _startTime, uint256 _duration)
        external
        onlyOwner
    {
        require(_beneficiary != address(0), "Invalid beneficiary");
        require(_totalAmount > 0, "Amount must be greater than 0");
        require(_duration > 0, "Duration must be greater than 0");
        require(vestingSchedules[_beneficiary].totalAmount == 0, "Vesting already set for this address");
        // Transfer tokens to the contract for vesting
        token.transferFrom(msg.sender, address(this), _totalAmount);

        vestingSchedules[_beneficiary] =
            VestingSchedule({totalAmount: _totalAmount, released: 0, startTime: _startTime, duration: _duration});

        emit TokenVest(_beneficiary, _totalAmount);
    }

    // Claim vested tokens
    function releaseTokens() external {
        VestingSchedule storage schedule = vestingSchedules[msg.sender];
        require(schedule.totalAmount > 0, "No vesting schedule");
        uint256 vested = vestedAmount(msg.sender);
        uint256 unreleased = vested - schedule.released;

        require(unreleased > 0, "No tokens to release");

        schedule.released += unreleased;
        token.transfer(msg.sender, unreleased);

        emit TokensRelease(msg.sender, unreleased);
    }

    // Calculate the total amount of tokens that have vested so far
    function vestedAmount(address _beneficiary) public view returns (uint256) {
        VestingSchedule memory schedule = vestingSchedules[_beneficiary];

        if (block.timestamp < schedule.startTime) {
            return 0; // Vesting hasn't started
        }

        uint256 elapsedTime = block.timestamp - schedule.startTime;
        if (elapsedTime >= schedule.duration) {
            return schedule.totalAmount; // Full vesting after the duration
        }

        return (schedule.totalAmount * elapsedTime) / schedule.duration; // Linear vesting
    }

    // Allows the owner to withdraw leftover tokens after all vesting is complete
    function withdrawRemainingTokens() external onlyOwner {
        uint256 remainingBalance = token.balanceOf(address(this));
        token.transfer(owner(), remainingBalance);
    }
}
