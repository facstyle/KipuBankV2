// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @title KipuBank - Banco descentralizado multi-token con roles, oráculos y contabilidad en USD.
/// @author Felipe A. Cristaldo (revisado por RemixAI)
/// @notice Permite depósitos/retiros de ETH y ERC20 con límites dinámicos en USD (vía Chainlink).
///         Soporte básico para USDC (1 USDC = 1 USD) y extensible a otros tokens con oráculos.
contract KipuBank is AccessControl {

    struct TokenConfig {
        address tokenAddress;
        uint8 decimals;
        bool isSupported;
    }

    event Deposit(address indexed user, address indexed token, uint256 amount);
    event Withdrawal(address indexed user, address indexed token, uint256 amount);
    event TokenSupportAdded(address indexed token, uint8 decimals);
    event BankCapUpdated(uint256 newCapUSD);
    event OracleFeedAdded(address indexed token, address indexed feed);

    error ErrInvalidOwner();
    error ErrZeroAmount();
    error ErrETHAmountMismatch(uint256 sent, uint256 expected);
    error ErrInsufficientBalance();
    error ErrErrInsufficientContractBalance(address token);
    error ErrOverWithdrawalLimit(uint256 maxAllowedUSD);
    error ErrBankCapReached(uint256 currentUSD, uint256 capUSD);
    error ErrTokenNotSupported(address token);
    error ErrTokenAlreadySupported(address token);
    error ErrInvalidDecimals(uint8 decimals);
    error ErrConversionFailed(address token);
    error ErrOracleUnavailable();
    error ErrAccessDenied(bytes32 role);

    // Roles
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ORACLE_MANAGER_ROLE = keccak256("ORACLE_MANAGER_ROLE");
    bytes32 public constant TOKEN_MANAGER_ROLE = keccak256("TOKEN_MANAGER_ROLE");

    // Configuración inmutable
    address public immutable chainlinkETHUSDFeed;
    uint256 public immutable USDC_DECIMALS = 6;
   address public constant USDC_ADDRESS = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F; // USDC Goerli Testnet

    // Configuración mutable
    uint256 public withdrawalLimitUSD;  // 8 decimales
    uint256 public bankCapUSD;          // 8 decimales

    mapping(address => TokenConfig) public tokenConfig;
    mapping(address => mapping(address => uint256)) private _balances;
    mapping(address => uint256) private _tokenTotalSupply;
    mapping(address => address) public tokenToOracleFeed;

    uint256 private _ethUSDPrice;       
    uint256 private lastOracleUpdate;

    uint256 private _depositCount;
    uint256 private _withdrawalCount;

    using SafeERC20 for IERC20;

    constructor(
        address _chainlinkETHUSDFeed,
        uint256 _initialBankCapUSD,
        uint256 _initialWithdrawalLimitUSD
    ) {
        if (msg.sender == address(0)) revert ErrInvalidOwner();
        if (_chainlinkETHUSDFeed == address(0)) revert ErrOracleUnavailable();
        if (_initialBankCapUSD == 0 || _initialWithdrawalLimitUSD == 0) revert ErrZeroAmount();

        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(ORACLE_MANAGER_ROLE, msg.sender);
        _grantRole(TOKEN_MANAGER_ROLE, msg.sender);

        chainlinkETHUSDFeed = _chainlinkETHUSDFeed;
        bankCapUSD = _initialBankCapUSD;
        withdrawalLimitUSD = _initialWithdrawalLimitUSD;

        _addTokenSupport(address(0), 18, true); // ETH
        _addTokenSupport(USDC_ADDRESS, uint8(USDC_DECIMALS), true); // USDC Goerli
    }

    function deposit(address token, uint256 amount) external payable {
        if (amount == 0) revert ErrZeroAmount();
        if (!tokenConfig[token].isSupported) revert ErrTokenNotSupported(token);

        uint256 amountUSD = _toUSD(token, amount);
        uint256 newTotalUSD = _getTotalBankValueUSD() + amountUSD;
        if (newTotalUSD > bankCapUSD) revert ErrBankCapReached(newTotalUSD, bankCapUSD);

        _balances[msg.sender][token] += amount;
        _tokenTotalSupply[token] += amount;
        _incrementDepositCount();

        if (token == address(0)) {
            if (msg.value != amount) revert ErrETHAmountMismatch(msg.value, amount);
        } else {
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        }

        emit Deposit(msg.sender, token, amount);
    }

    function withdraw(address token, uint256 amount) external {
        if (amount == 0) revert ErrZeroAmount();
        if (!tokenConfig[token].isSupported) revert ErrTokenNotSupported(token);
        if (amount > _balances[msg.sender][token]) revert ErrInsufficientBalance();

        uint256 amountUSD = _toUSD(token, amount);
        if (amountUSD > withdrawalLimitUSD) revert ErrOverWithdrawalLimit(withdrawalLimitUSD);

        _balances[msg.sender][token] -= amount;
        _tokenTotalSupply[token] -= amount;
        _incrementWithdrawalCount();

        if (token == address(0)) {
            if (address(this).balance < amount) revert ErrErrInsufficientContractBalance(token);
            payable(msg.sender).transfer(amount);
        } else {
            if (IERC20(token).balanceOf(address(this)) < amount) revert ErrErrInsufficientContractBalance(token);
            IERC20(token).safeTransfer(msg.sender, amount);
        }

        emit Withdrawal(msg.sender, token, amount);
    }

    function updateETHPrice() external onlyRole(ORACLE_MANAGER_ROLE) {
        (, int256 price, , uint256 updatedAt, ) = AggregatorV3Interface(chainlinkETHUSDFeed).latestRoundData();
        if (price <= 0 || updatedAt <= lastOracleUpdate) revert ErrOracleUnavailable();
        _ethUSDPrice = uint256(price);
        lastOracleUpdate = updatedAt;
    }

    function addTokenSupport(address token, uint8 decimals) external onlyRole(TOKEN_MANAGER_ROLE) {
        if (tokenConfig[token].isSupported) revert ErrTokenAlreadySupported(token);
        if (decimals > 36) revert ErrInvalidDecimals(decimals);
        _addTokenSupport(token, decimals, true);
    }

    function setTokenOracleFeed(address token, address feed) external onlyRole(ORACLE_MANAGER_ROLE) {
        if (!tokenConfig[token].isSupported) revert ErrTokenNotSupported(token);
        if (feed == address(0)) revert ErrOracleUnavailable();
        tokenToOracleFeed[token] = feed;
        emit OracleFeedAdded(token, feed);
    }

    function setBankCapUSD(uint256 newCapUSD) external onlyRole(ADMIN_ROLE) {
        if (newCapUSD == 0) revert ErrZeroAmount();
        bankCapUSD = newCapUSD;
        emit BankCapUpdated(newCapUSD);
    }

    function setWithdrawalLimitUSD(uint256 newLimitUSD) external onlyRole(ADMIN_ROLE) {
        if (newLimitUSD == 0) revert ErrZeroAmount();
        withdrawalLimitUSD = newLimitUSD;
    }

    function getBalance(address user, address token) external view returns (uint256) {
        return _balances[user][token];
    }

    function getTotalBankValueUSD() external view returns (uint256) {
        return _getTotalBankValueUSD();
    }

    function getETHUSDPrice() external view returns (uint256) {
        return _ethUSDPrice;
    }

    function isTokenSupported(address token) external view returns (bool) {
        return tokenConfig[token].isSupported;
    }

    function getTokenConfig(address token) external view returns (TokenConfig memory) {
        return tokenConfig[token];
    }

    function getTokenOracleFeed(address token) external view returns (address) {
        return tokenToOracleFeed[token];
    }

    function getDepositCount() external view returns (uint256) {
        return _depositCount;
    }

    function getWithdrawalCount() external view returns (uint256) {
        return _withdrawalCount;
    }

    function _addTokenSupport(address token, uint8 decimals, bool isSupported) private {
        tokenConfig[token] = TokenConfig(token, decimals, isSupported);
        emit TokenSupportAdded(token, decimals);
    }

    function _toUSD(address token, uint256 amount) private view returns (uint256) {
        if (token == address(0)) {
            return (amount * _ethUSDPrice) / (10 ** 10);
        } else if (token == USDC_ADDRESS) {
            return amount / (10 ** (USDC_DECIMALS - 8));
        } else {
            revert ErrConversionFailed(token);
        }
    }

    function _getTotalBankValueUSD() private view returns (uint256) {
        uint256 totalUSD = _toUSD(address(0), _tokenTotalSupply[address(0)]);
        if (_tokenTotalSupply[USDC_ADDRESS] > 0) {
            totalUSD += _toUSD(USDC_ADDRESS, _tokenTotalSupply[USDC_ADDRESS]);
        }
        return totalUSD;
    }

    function _incrementDepositCount() private {
        unchecked { _depositCount++; }
    }

    function _incrementWithdrawalCount() private {
        unchecked { _withdrawalCount++; }
    }
}

