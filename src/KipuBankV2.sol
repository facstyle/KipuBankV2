// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @title KipuBank - Banco descentralizado multi-token con roles, oráculos y contabilidad en USD.
/// @author Felipe A. Cristaldo  
/// @notice Permite depósitos/retiros de ETH y ERC20 con límites dinámicos en USD (vía Chainlink).
contract KipuBank is AccessControl {
    struct TokenConfig {
        address tokenAddress;
        uint8 decimals;
        bool isSupported;
    }

    // Eventos
    event Deposit(address indexed user, address indexed token, uint256 amount);
    event Withdrawal(address indexed user, address indexed token, uint256 amount);
    event TokenSupportAdded(address indexed token, uint8 decimals);
    event BankCapUpdated(uint256 newCapUSD);
    event OracleFeedAdded(address indexed token, address indexed feed);

    // Errores personalizados
    error ErrInvalidOwner();
    error ErrZeroAmount();
    error ErrETHAmountMismatch(uint256 sent, uint256 expected);
    error ErrInsufficientBalance();
    error ErrInsufficientContractBalance(address token);
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

    // Configuración
    address public immutable chainlinkETHUSDFeed;
    uint256 public immutable USDC_DECIMALS = 6;  // 6 decimales para USDC
    address public usdcAddress;  // Dirección configurable de USDC

    // Estado
    uint256 public withdrawalLimitUSD;
    uint256 public bankCapUSD;

    mapping(address => TokenConfig) public tokenConfig;
    mapping(address => mapping(address => uint256)) private _balances;
    mapping(address => uint256) private _tokenTotalSupply;
    mapping(address => address) public tokenToOracleFeed;

    uint256 private _ethUSDPrice;
    uint256 private lastOracleUpdate;

    uint256 private _depositCount;
    uint256 private _withdrawalCount;

    using SafeERC20 for IERC20Metadata;  // Fix: Usar IERC20Metadata

    constructor(
        address _chainlinkETHUSDFeed,
        uint256 _initialBankCapUSD,
        uint256 _initialWithdrawalLimitUSD,
        address _usdcAddress
    ) {
        if (msg.sender == address(0)) revert ErrInvalidOwner();
        if (_chainlinkETHUSDFeed == address(0)) revert ErrOracleUnavailable();
        if (_initialBankCapUSD == 0 || _initialWithdrawalLimitUSD == 0) revert ErrZeroAmount();
        if (_usdcAddress == address(0)) revert ErrTokenNotSupported(_usdcAddress);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(ORACLE_MANAGER_ROLE, msg.sender);
        _grantRole(TOKEN_MANAGER_ROLE, msg.sender);

        chainlinkETHUSDFeed = _chainlinkETHUSDFeed;
        bankCapUSD = _initialBankCapUSD;
        withdrawalLimitUSD = _initialWithdrawalLimitUSD;
        usdcAddress = _usdcAddress;

        _addTokenSupport(address(0), 18, true); // ETH (18 decimales)
        _addTokenSupport(usdcAddress, uint8(USDC_DECIMALS), true); // Fix: Conversión explícita a uint8
    }

    // Función para depositar tokens (ETH o ERC20)
    function deposit(address token, uint256 amount) external payable {
        if (amount == 0) revert ErrZeroAmount();
        if (!tokenConfig[token].isSupported) revert ErrTokenNotSupported(token);

        uint256 amountUSD = _toUSD(token, amount);
        uint256 newTotalUSD = _getTotalBankValueUSD() + amountUSD;
        if (newTotalUSD > bankCapUSD) revert ErrBankCapReached(newTotalUSD, bankCapUSD);

        _balances[msg.sender][token] += amount;
        _tokenTotalSupply[token] += amount;
        unchecked { ++_depositCount; }

        if (token == address(0)) {
            if (msg.value != amount) revert ErrETHAmountMismatch(msg.value, amount);
        } else {
            if (IERC20Metadata(token).balanceOf(msg.sender) < amount) revert ErrInsufficientBalance();
            IERC20Metadata(token).safeTransferFrom(msg.sender, address(this), amount); // Fix: 3 argumentos
        }

        emit Deposit(msg.sender, token, amount);
    }

    // Función para retirar tokens (ETH o ERC20)
    function withdraw(address token, uint256 amount) external {
        if (amount == 0) revert ErrZeroAmount();
        if (!tokenConfig[token].isSupported) revert ErrTokenNotSupported(token);
        if (_balances[msg.sender][token] < amount) revert ErrInsufficientBalance();

        uint256 amountUSD = _toUSD(token, amount);
        if (amountUSD > withdrawalLimitUSD) revert ErrOverWithdrawalLimit(withdrawalLimitUSD);

        _balances[msg.sender][token] -= amount;
        _tokenTotalSupply[token] -= amount;
        unchecked { ++_withdrawalCount; }

        if (token == address(0)) {
            if (address(this).balance < amount) revert ErrInsufficientContractBalance(token);
            payable(msg.sender).transfer(amount);
        } else {
            if (IERC20Metadata(token).balanceOf(address(this)) < amount) revert ErrInsufficientContractBalance(token);
            IERC20Metadata(token).safeTransfer(msg.sender, amount); // Fix: 2 argumentos
        }

        emit Withdrawal(msg.sender, token, amount);
    }

    // Actualiza el precio de ETH/USD desde Chainlink
    function updateETHPrice() external onlyRole(ORACLE_MANAGER_ROLE) {
        (, int256 price, , uint256 updatedAt, ) = AggregatorV3Interface(chainlinkETHUSDFeed).latestRoundData();
        if (price <= 0 || updatedAt <= lastOracleUpdate) revert ErrOracleUnavailable();
        _ethUSDPrice = uint256(price);
        lastOracleUpdate = updatedAt;
    }

    // Añade soporte para un nuevo token ERC20
    function addTokenSupport(address token, uint8 decimals) external onlyRole(TOKEN_MANAGER_ROLE) {
        if (tokenConfig[token].isSupported) revert ErrTokenAlreadySupported(token);
        if (decimals > 36) revert ErrInvalidDecimals(decimals);

        if (token != address(0)) {
            uint8 actualDecimals = IERC20Metadata(token).decimals(); // Fix: Usar IERC20Metadata
            if (actualDecimals != decimals) revert ErrInvalidDecimals(actualDecimals);
        }

        _addTokenSupport(token, decimals, true);
    }

    // Configura el feed de Chainlink para un token
    function setTokenOracleFeed(address token, address feed) external onlyRole(ORACLE_MANAGER_ROLE) {
        if (!tokenConfig[token].isSupported) revert ErrTokenNotSupported(token);
        if (feed == address(0)) revert ErrOracleUnavailable();

        try AggregatorV3Interface(feed).latestRoundData() returns (uint80, int256, uint256, uint256, uint80) {
            tokenToOracleFeed[token] = feed;
            emit OracleFeedAdded(token, feed);
        } catch {
            revert ErrOracleUnavailable();
        }
    }

    // Configura el límite de capacidad del banco (en USD)
    function setBankCapUSD(uint256 newCapUSD) external onlyRole(ADMIN_ROLE) {
        if (newCapUSD == 0) revert ErrZeroAmount();
        bankCapUSD = newCapUSD;
        emit BankCapUpdated(newCapUSD);
    }

    // Configura el límite de retiro (en USD)
    function setWithdrawalLimitUSD(uint256 newLimitUSD) external onlyRole(ADMIN_ROLE) {
        if (newLimitUSD == 0) revert ErrZeroAmount();
        withdrawalLimitUSD = newLimitUSD;
    }

    // Funciones de lectura
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

    // Funciones internas
    function _addTokenSupport(address token, uint8 decimals, bool isSupported) private {
        tokenConfig[token] = TokenConfig(token, decimals, isSupported);
        emit TokenSupportAdded(token, decimals);
    }

    // Convierte un amount de token a USD
    function _toUSD(address token, uint256 amount) private view returns (uint256) {
        if (token == address(0)) {
            return (amount * _ethUSDPrice) / (10 ** 10); // 18 decimales ETH -> 8 decimales USD
        } else if (token == usdcAddress) {
            return amount / (10 ** (USDC_DECIMALS - 8)); // 6 decimales USDC -> 8 decimales USD
        } else {
            address feed = tokenToOracleFeed[token];
            if (feed == address(0)) revert ErrOracleUnavailable();

            (, int256 price, , , ) = AggregatorV3Interface(feed).latestRoundData();
            if (price <= 0) revert ErrOracleUnavailable();

            uint256 tokenDecimals = tokenConfig[token].decimals;
            return (amount * uint256(price)) / (10 ** (tokenDecimals + (18 - 8)));
        }
    }

    // Calcula el valor total del banco en USD
    function _getTotalBankValueUSD() private view returns (uint256) {
        uint256 totalUSD = _toUSD(address(0), _tokenTotalSupply[address(0)]);

        if (_tokenTotalSupply[usdcAddress] > 0) {
            totalUSD = totalUSD + _toUSD(usdcAddress, _tokenTotalSupply[usdcAddress]);
        }

        return totalUSD;
    }
}
