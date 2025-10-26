// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Importaciones corregidas a la forma absoluta "src/openzeppelin/..."
// Se asume que ReentrancyGuard está en 'utils/' y AccessControl en 'access/'

import "src/openzeppelin/access/AccessControl.sol";
import "src/openzeppelin/utils/ReentrancyGuard.sol";

import "src/openzeppelin/token/ERC20/IERC20.sol";
import "src/openzeppelin/utils/SafeERC20.sol";

// Se mantiene esta ruta relativa si interfaces/ AggregatorV3Interface.sol está al lado de openzeppelin/
import "./interfaces/AggregatorV3Interface.sol"; 

interface IERC20Decimals {
    function decimals() external view returns (uint8);
}

contract KipuBankV2 is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    address public constant ETH_ADDRESS = address(0);
    uint8 public constant USD_DECIMALS = 6;

    error Err_ZeroAmount();
    error Err_BankCapExceeded();
    error Err_InsufficientBalance();
    error Err_NotSupportedToken();
    error Err_OracleNotFound();
    error Err_InvalidPrice();
    error Err_ETHValueMismatch();
    error Err_TransferFailed();

    event Deposit(address indexed user, address indexed token, uint256 amount);
    event Withdraw(address indexed user, address indexed token, uint256 amount);
    event BankCapUpdated(uint256 newCapUSD);
    event PriceFeedSet(address indexed token, address indexed feed);

    mapping(address => mapping(address => uint256)) public vaults;
    mapping(address => AggregatorV3Interface) public priceFeeds;
    address[] public supportedTokens;
    uint256 public bankCapUSD;
    uint256 public totalBankUSDValue;

    constructor(uint256 _bankCapUSD, address _ethUsdPriceFeed) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);

        bankCapUSD = _bankCapUSD;
        priceFeeds[ETH_ADDRESS] = AggregatorV3Interface(_ethUsdPriceFeed);
        supportedTokens.push(ETH_ADDRESS);
    }

    function deposit(address tokenAddress, uint256 amount) external payable nonReentrant {
        if (amount == 0) revert Err_ZeroAmount();

        uint256 usdAmount = _convertToUSD(tokenAddress, amount);
        if (totalBankUSDValue + usdAmount > bankCapUSD) revert Err_BankCapExceeded();

        unchecked {
            vaults[msg.sender][tokenAddress] += amount;
            totalBankUSDValue += usdAmount;
        }

        if (tokenAddress == ETH_ADDRESS) {
            if (msg.value != amount) revert Err_ETHValueMismatch();
        } else {
            if (msg.value > 0) revert Err_ETHValueMismatch();
            IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), amount);
            if (!_isSupportedToken(tokenAddress)) supportedTokens.push(tokenAddress);
        }

        emit Deposit(msg.sender, tokenAddress, amount);
    }

    function withdraw(address tokenAddress, uint256 amount) external nonReentrant {
        if (amount == 0) revert Err_ZeroAmount();
        uint256 userBalance = vaults[msg.sender][tokenAddress];
        if (userBalance < amount) revert Err_InsufficientBalance();

        uint256 usdAmount = _convertToUSD(tokenAddress, amount);

        unchecked {
            vaults[msg.sender][tokenAddress] -= amount;
            totalBankUSDValue -= usdAmount;
        }

        if (tokenAddress == ETH_ADDRESS) {
            (bool sent,) = msg.sender.call{value: amount}("");
            if (!sent) revert Err_TransferFailed();
        } else {
            IERC20(tokenAddress).safeTransfer(msg.sender, amount);
        }

        emit Withdraw(msg.sender, tokenAddress, amount);
    }

    function _convertToUSD(address tokenAddress, uint256 amount) internal view returns (uint256 usdValue) {
        AggregatorV3Interface feed = priceFeeds[tokenAddress];
        if (address(feed) == address(0)) revert Err_OracleNotFound();

        (, int256 price,,,) = feed.latestRoundData();
        if (price <= 0) revert Err_InvalidPrice();

        uint8 feedDecimals = feed.decimals();
        uint8 tokenDecimals = tokenAddress == ETH_ADDRESS ? 18 : IERC20Decimals(tokenAddress).decimals();

        usdValue = (amount * uint256(price) * (10 ** USD_DECIMALS)) / (10 ** (tokenDecimals + feedDecimals));
    }

    function setBankCapUSD(uint256 newCap) external onlyRole(MANAGER_ROLE) {
        bankCapUSD = newCap;
        emit BankCapUpdated(newCap);
    }

    function setPriceFeed(address token, address feed) external onlyRole(MANAGER_ROLE) {
        priceFeeds[token] = AggregatorV3Interface(feed);
        if (!_isSupportedToken(token)) supportedTokens.push(token);
        emit PriceFeedSet(token, feed);
    }

    function _isSupportedToken(address token) internal view returns (bool) {
        for (uint i = 0; i < supportedTokens.length; i++) {
            if (supportedTokens[i] == token) return true;
        }
        return false;
    }

    receive() external payable {}
}
