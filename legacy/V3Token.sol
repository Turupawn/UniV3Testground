// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface INonfungiblePositionManager {

    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint amount0Desired;
        uint amount1Desired;
        uint amount0Min;
        uint amount1Min;
        address recipient;
        uint deadline;
    }

    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint tokenId,
            uint128 liquidity,
            uint amount0,
            uint amount1
        );

    struct IncreaseLiquidityParams {
        uint tokenId;
        uint amount0Desired;
        uint amount1Desired;
        uint amount0Min;
        uint amount1Min;
        uint deadline;
    }

    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        returns (
            uint128 liquidity,
            uint amount0,
            uint amount1
        );

    struct DecreaseLiquidityParams {
        uint tokenId;
        uint128 liquidity;
        uint amount0Min;
        uint amount1Min;
        uint deadline;
    }

    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint amount0, uint amount1);

    struct CollectParams {
        uint tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    function collect(CollectParams calldata params)
        external
        payable
        returns (uint amount0, uint amount1);
}

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint amount) external;
}

struct ExactInputSingleParams {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    address recipient;
    uint deadline;
    uint amountIn;
    uint amountOutMinimum;
    uint160 sqrtPriceLimitX96;
}

interface ISwapRouter {
    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint amountOut);
}

abstract contract IUniswapV3Pool
{
    struct Slot0 {
        // the current price
        uint160 sqrtPriceX96;
        // the current tick
        int24 tick;
        // the most-recently updated index of the observations array
        uint16 observationIndex;
        // the current maximum number of observations that are being stored
        uint16 observationCardinality;
        // the next maximum number of observations to store, triggered in observations.write
        uint16 observationCardinalityNext;
        // the current protocol fee as a percentage of the swap fee taken on withdrawal
        // represented as an integer denominator (1/x)%
        uint8 feeProtocol;
        // whether the pool is locked
        bool unlocked;
    }
    //Slot0 public slot0;

    uint24 public fee;
    //int24 public tickSpacing;


    function slot0(
    ) external virtual view returns 
        (
            uint160 sqrtPriceX96, 
            int24 tick, 
            uint16 observationIndex, 
            uint16 observationCardinality, 
            uint16 observationCardinalityNext, 
            uint8 feeProtocol, 
            bool unlocked);
    
    function tickSpacing() external virtual view returns (int24);
}

contract V3Token is Context, IERC20, IERC20Metadata, Ownable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    // My variables
    address public pool1;
    address public pool2;
    address public pool3;
    address public pool4;
    IWETH public weth;
    ISwapRouter public router;
    INonfungiblePositionManager public nonfungiblePositionManager;

    bool private inSwap;
    uint256 internal _marketingFeeCollected;
    uint256 internal _liquidityFeeCollected;

    address public marketing_wallet;
    address public liquidity_wallet;

    uint public _feeDecimal = 2;
    // index 0 = buy fee, index 1 = sell fee, index 2 = p2p fee
    uint[] public _marketingFee;
    uint[] public _liquidityFee;

    bool public swapEnabled = true;
    bool public isFeeActive = true;

    mapping(address => bool) public isTaxless;

    int24 internal constant MIN_TICK = -887272;
    int24 internal constant MAX_TICK = -MIN_TICK;

    constructor(string memory pName, string memory pSymbol) {
        _name = pName;
        _symbol = pSymbol;

        marketing_wallet = 0x707e55a12557E89915D121932F83dEeEf09E5d70;
        liquidity_wallet = 0x08966BfFa14A7d0d7751355C84273Bb2eaF20FC3;

        _marketingFee.push(300);
        _marketingFee.push(0);
        _marketingFee.push(0);

        _liquidityFee.push(200);
        _liquidityFee.push(0);
        _liquidityFee.push(0);

        isTaxless[msg.sender] = true;
        isTaxless[address(this)] = true;
        isTaxless[marketing_wallet] = true;
        isTaxless[liquidity_wallet] = true;
        isTaxless[address(0)] = true;

        _mint(msg.sender, 1_000_000 ether);

        nonfungiblePositionManager
            = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

        weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

        address token0;
        address token1;
        if(address(this) < address(weth))
        {
            token0 = address(this);
            token1 = address(weth);
        }else
        {
            token0 = address(weth);
            token1 = address(this);
        }

        pool1 = nonfungiblePositionManager.createAndInitializePoolIfNecessary(
            token0,
            token1,
            100/* fee */,
            79228162514264337593543950336//Math.sqrt("1") * 2 ** 96
        );
        pool2 = nonfungiblePositionManager.createAndInitializePoolIfNecessary(
            token0,
            token1,
            500/* fee */,
            79228162514264337593543950336//Math.sqrt("1") * 2 ** 96
        );
        pool3 = nonfungiblePositionManager.createAndInitializePoolIfNecessary(
            token0,
            token1,
            3000/* fee */,
            79228162514264337593543950336//Math.sqrt("1") * 2 ** 96
        );
        pool4 = nonfungiblePositionManager.createAndInitializePoolIfNecessary(
            token0,
            token1,
            10000/* fee */,
            79228162514264337593543950336//Math.sqrt("1") * 2 ** 96
        );
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        // My implementation
        if (swapEnabled && !inSwap && 
            (from != pool1 && from != pool2 && from != pool3 && from != pool4)) {
            //swap();
        }
        
        uint256 feesCollected;
        if (isFeeActive && !isTaxless[from] && !isTaxless[to] && !inSwap) {
            bool sell;
            if(to == pool1 || to == pool2 || to == pool3 || to == pool4)
            {
                sell = true;
            }
            bool p2p;
            if(to != pool1 && to != pool2 && to != pool3 && to != pool4
                && from != pool1 && from != pool2 && from != pool3 && from != pool4)
            {
                p2p = true;
            }
            feesCollected = calculateFee(p2p ? 2 : sell ? 1 : 0, amount);
        }

        amount -= feesCollected;
        _balances[from] -= feesCollected;
        _balances[address(this)] += feesCollected;

        // End my implementation

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    // My functions

    function calculateFee(uint256 feeIndex, uint256 amount) internal returns(uint256) {
        uint256 marketingFee = (amount * _marketingFee[feeIndex]) / (10**(_feeDecimal + 2));
        uint256 liquidityFee = (amount * _liquidityFee[feeIndex]) / (10**(_feeDecimal + 2));
        
        _marketingFeeCollected += marketingFee;
        _liquidityFeeCollected += liquidityFee;
        return marketingFee + liquidityFee;
    }

    function setTaxless(address account, bool value) external onlyOwner {
        isTaxless[account] = value;
    }

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    function swap() public lockTheSwap {
        // How much are we swaping?
        uint totalCollected = _marketingFeeCollected  + _liquidityFeeCollected;
        uint amountToSwap = _marketingFeeCollected + (_liquidityFeeCollected / 2);
        uint amountTokensToLiquidity = totalCollected - amountToSwap;

        uint minTokensBeforeSwap = 10;
        //if(minTokensBeforeSwap > totalCollected) return;

        // Let's swap for eth now     
        _approve(address(this), address(router), amountToSwap*1000);
        
        ExactInputSingleParams memory swapParams = ExactInputSingleParams(
            address(this), //tokenIn
            address(weth), //tokenOut
            10000,  //fee
            address(this),   //recipient
            block.timestamp, //deadline
            amountToSwap,    //amountIn
            0, //amountOutMinimum
            0  //sqrtPriceLimitX96
        );
        
        router.exactInputSingle(swapParams);

        liquidity();
    }

    function liquidity() public {
        _approve(address(this), address(nonfungiblePositionManager), balanceOf(address(this)));
        weth.approve(address(nonfungiblePositionManager), weth.balanceOf(address(this)));

        address token0;
        address token1;
        uint amount0;
        uint amount1;

      int24 tickSpacing = IUniswapV3Pool(pool4).tickSpacing();//pool4.tickSpacing();

      (
            uint160 sqrtPriceX96, 
            int24 tick, 
            uint16 observationIndex, 
            uint16 observationCardinality, 
            uint16 observationCardinalityNext, 
            uint8 feeProtocol, 
            bool unlocked) = IUniswapV3Pool(pool4).slot0();

      int24 nearestTick = getNearestUsableTick(tick, tickSpacing);


        if(address(this) < address(weth))
        {
            token0 = address(this);
            token1 = address(weth);
            amount0 = balanceOf(address(this));
            amount1 = weth.balanceOf(address(this));
        }else
        {
            token0 = address(weth);
            token1 = address(this);
            amount0 = weth.balanceOf(address(this));
            amount1 = balanceOf(address(this));
        }

        INonfungiblePositionManager.MintParams memory params =
            INonfungiblePositionManager.MintParams({
                token0: token0,
                token1: token1,
                fee: 10000,
                tickLower: nearestTick - tickSpacing * 10,
                tickUpper: nearestTick + tickSpacing * 10,
                amount0Desired: amount0,
                amount1Desired: amount1,
                amount0Min: 0,
                amount1Min: 0,
                recipient: marketing_wallet,
                deadline: block.timestamp
            });

        nonfungiblePositionManager.mint(params);
    }


    function getNearestUsableTick(int24 currentTick, int24 space) public view returns(int24 nearestTick) {
        // 0 is always a valid tick
        if(currentTick == 0){
            return 0;
        }
        // Determines direction
        int24 direction = -1;
        if(currentTick >= 0)
            direction = 1;
        // Changes direction
        currentTick *= direction;
        // Calculates nearest tick based on how close the current tick remainder is to space / 2
        nearestTick = (currentTick%space <= space/2) ? currentTick - (currentTick%space) : currentTick + (space-(currentTick%space));
        // Changes direction back
        nearestTick *= direction;
    }

    fallback() external payable {}
    receive() external payable {}
}