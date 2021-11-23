interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ILPToken is IERC20 {
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IUniswapRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

//TODO: hard code the contract here, so we don't have to worry about security issues when deploying
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol';
import 'https://github.com/Uniswap/solidity-lib/blob/master/contracts/libraries/TransferHelper.sol';

contract LPConverter {
   
    using SafeMath for uint256;
    enum SwapCase{ AA, AB, BB }
    address _uniswapRouterAddress;
    IUniswapRouter _uniswapRouter;
   
    constructor(address uniswapRouterAddress) {
        _uniswapRouterAddress = uniswapRouterAddress;
        _uniswapRouter = IUniswapRouter(uniswapRouterAddress);
    }
   
    /**
     * ConvertSingleSidedLP Converts from one LP token to another.
     * Note: SingleSided refers to the fact that one token from the InLPToken will Match one token from the outLPToken
     * minAmountOutTokenA is the minimum amount out in which we should receive when removing liquidity from TokenA
     * minAmountOutTokenB is the minimum amount out in which we should receive when removing liquidity from TokenB
     * minAmountInTokenA is the minimum amount of tokens in which we should be obtaining when providing liqudity for outLPToken.Token0()
     * minAmountInTokenB is the minimum amount of tokens in which we should be obtaining when providing liqudity for outLPToken.Token1()
     * slippage
     */
    //TODO: This probably should have a reentrance guard
    function convertSingleSidedLP(address inLPTokenAddress,
        address outLPTokenAddress,
        address[] calldata path,
        uint amount,
        uint minAmountOutTokenA,
        uint minAmountOutTokenB,
        uint minAmountInTokenA,
        uint minAmountInTokenB,
        uint slippage,
        uint deadline) external {
       
        //LP Tokens are sorted which should limit the possibilities
        ILPToken inLPToken = ILPToken(inLPTokenAddress);
        ILPToken outLPToken = ILPToken(outLPTokenAddress);
       
        IERC20(inLPToken).approve(_uniswapRouterAddress, amount);
        (uint outTokenAAmount, uint outTokenBAmount) = _uniswapRouter.removeLiquidity(
            inLPToken.token0(),
            inLPToken.token1(),
            amount,
            minAmountOutTokenA,
            minAmountOutTokenB,
            address(this),
            deadline);
           
        _swap(path, slippage, deadline);
       
    }
   
    function addLiquidity(ILPToken outLPToken, uint minAmountInToken0, uint minAmountInToken1, uint deadline) internal
    {
        bool isToken1WETH = (outLPToken.token1() == _uniswapRouter.WETH());
       
        _safeApprove(outLPToken.token0());
        _safeApprove(outLPToken.token1());
       
        if(outLPToken.token0() == _uniswapRouter.WETH()) {
            //Contracts can be manipulated so we calculate the minimum tokens expected when providing liquidity externally
            //https://docs.uniswap.org/protocol/V2/guides/smart-contract-integration/providing-liquidity
            _uniswapRouter.addLiquidityETH{value: address(this).balance }(
                outLPToken.token1(),
                IERC20(outLPToken.token1()).balanceOf(address(this)),
                minAmountInToken1,
                minAmountInToken0,
                msg.sender,
                deadline
            );
           
            if(address(this).balance > 0) {
                (bool sent, bytes memory data) = msg.sender.call{value: address(this).balance}("");
                require(sent, "Failed to return Ether");
            }
           
            uint token1LeftOver = IERC20(outLPToken.token1()).balanceOf(address(this));
            if(token1LeftOver > 0) {
                IERC20(outLPToken.token1()).transfer(msg.sender, token1LeftOver);
            }
        }
        else if(outLPToken.token1() == _uniswapRouter.WETH()) {
            //Contracts can be manipulated so we calculate the minimum tokens expected when providing liquidity externally
            //to assure the enduser has a general idea of how much liquidity they will receive in return
            //https://docs.uniswap.org/protocol/V2/guides/smart-contract-integration/providing-liquidity
            _uniswapRouter.addLiquidityETH{value: address(this).balance }(
                outLPToken.token0(),
                IERC20(outLPToken.token0()).balanceOf(address(this)),
                minAmountInToken0,
                minAmountInToken1,
                msg.sender,
                deadline
            );
           
            if(address(this).balance > 0) {
                (bool sent, bytes memory data) = msg.sender.call{value: address(this).balance}("");
                require(sent, "Failed to return Ether");
            }
           
            uint token0LeftOver = IERC20(outLPToken.token0()).balanceOf(address(this));
            if(token0LeftOver > 0)
            {
                IERC20(outLPToken.token0()).transfer(msg.sender, token0LeftOver);
            }
        }
        else {
            _uniswapRouter.addLiquidity(
                outLPToken.token0(),
                outLPToken.token1(),
                IERC20(outLPToken.token0()).balanceOf(address(this)),
                IERC20(outLPToken.token1()).balanceOf(address(this)),
                minAmountInToken0,
                minAmountInToken1,
                msg.sender,
                deadline
            );
           
            uint token0LeftOver = IERC20(outLPToken.token0()).balanceOf(address(this));
            if(token0LeftOver > 0)
            {
                IERC20(outLPToken.token0()).transfer(msg.sender, token0LeftOver);
            }
           
            uint token1LeftOver = IERC20(outLPToken.token1()).balanceOf(address(this));
            if(token1LeftOver > 0) {
                IERC20(outLPToken.token1()).transfer(msg.sender, token1LeftOver);
            }
        }
    }
   
    function _safeApprove(address tokenAddress) internal {
       
        if(tokenAddress == _uniswapRouter.WETH()) {
            return;    
        }
       
        IERC20 ercToken = IERC20(tokenAddress);
       
        uint tokenBalance = ercToken.balanceOf(address(this));
        ercToken.approve(_uniswapRouterAddress, tokenBalance);
    }
   
    function _swap(address[] calldata path, uint slippage, uint deadline) internal returns (uint[] memory amounts) {
        uint amountIn = IERC20(path[0]).balanceOf(address(this));
        uint[] memory amountsOut = _uniswapRouter.getAmountsOut(amountIn, path);
        uint amountOut = amountsOut[amountsOut.length - 1].mul(slippage).div(1000);
       
        if(path[0] == _uniswapRouter.WETH()) {
            return _uniswapRouter.swapExactETHForTokens{value: amountIn }(amountOut, path, address(this), deadline);
        }
        else if (path[1] == _uniswapRouter.WETH()) {
            return _uniswapRouter.swapExactTokensForETH(amountIn, amountOut, path, address(this), deadline);
        }
        else {
            return _uniswapRouter.swapExactTokensForTokens(amountIn, amountOut, path, address(this), deadline);
        }
    }
}
