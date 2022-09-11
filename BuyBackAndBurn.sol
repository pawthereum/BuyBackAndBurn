// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC20 {
    function balanceOf(
        address account
    ) external view returns (uint256);

    function transfer(
        address recipient, 
        uint256 amount
    ) external returns (bool);
}


interface IUniswapV2Router02 {
    function getAmountsOut(
        uint amountIn, 
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;
}

contract PawthBuyBackAndBurn {

    IUniswapV2Router02 constant uniswapV2Router = IUniswapV2Router02(
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    );
    
    IERC20 constant pawthereum = IERC20(0xAEcc217a749c2405b5ebC9857a16d58Bdc1c367F);

    address constant pawthDevMultiSig = 0xF10B1D6e1cD1DE1f11daf1f609b152b8B125426D;
    address constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant burnWallet = 0x000000000000000000000000000000000000dEaD;

    event BuyBackAndBurn(uint256 ethSpent, uint256 tokensBurned);

    function buyBackAndBurn () public {
        // only the multi sig can trigger this
        require (msg.sender == pawthDevMultiSig, "Not authorized");

        // create WETH -> PAWTH path
        address [] memory path = new address[](2);
        path[0] = weth;
        path[1] = address(pawthereum);

        // the amount to buy with
        uint256 buyAmount = address(this).balance;

        // the amount of pawth in this contract before the buyback
        uint256 balanceBefore = pawthereum.balanceOf(address(this));

        // buy pawth tokens with eth balance
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens
        {value: buyAmount}(
            0, // get as many tokens as possible
            path,
            address(this),
            block.timestamp
        );

        // the amount of pawth in this contract after the buyback
        uint256 balanceAfter = pawthereum.balanceOf(address(this));

        // burn the total balance of pawth in this contract
        // this will burn whatever pawth is in this contract before the buyback happnes
        // in addition to whatever is purhcased during the buyback
        pawthereum.transfer(burnWallet, balanceAfter);

        // emit event
        emit BuyBackAndBurn(buyAmount, balanceBefore - balanceAfter);
    }

    // accept ETH
    receive() external payable {}
}
