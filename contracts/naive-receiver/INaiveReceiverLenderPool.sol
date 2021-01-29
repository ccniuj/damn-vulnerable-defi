pragma solidity ^0.6.0;

interface INaiveReceiverLenderPool {
    function fixedFee() external pure returns (uint256);
    function flashLoan(address borrower, uint256 borrowAmount) external;
    receive () external payable;
}
