// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @author Felipe A. Cristaldo
/// @title KipuBankV2

/* -------------------------------------------------------------------------- */
/*                             📦 Importaciones                               */
/* -------------------------------------------------------------------------- */
// Se asume que las dependencias están ubicadas bajo `src/openzeppelin/`
import "src/openzeppelin/access/AccessControl.sol";
import "src/openzeppelin/utils/ReentrancyGuard.sol";
import "src/openzeppelin/token/ERC20/IERC20.sol";
import "src/openzeppelin/utils/SafeERC20.sol";

// Interfaz Chainlink para feeds de precios
import "./interfaces/AggregatorV3Interface.sol";

/* -------------------------------------------------------------------------- */
/*                         🧩 Interfaz de utilidad ERC20                      */
/* -------------------------------------------------------------------------- */
interface IERC20Decimals {
    function decimals() external view returns (uint8);
}

/* -------------------------------------------------------------------------- */
/*                               💰 KipuBankV2                                */
/* -------------------------------------------------------------------------- */
/**
 * @title KipuBankV2
 * @notice Contrato bancario con soporte multi-token, integración Chainlink,
 *         control de acceso y límites basados en valor USD.
 * @dev    Mejora del contrato original KipuBank, orientado a producción.
 */
contract KipuBankV2 is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /* ---------------------------------------------------------------------- */
    /*                              CONSTANTES                                */
    /* ---------------------------------------------------------------------- */
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    address public constant ETH_ADDRESS = address(0);
    uint8 public constant USD_DECIMALS = 6;

    /* ---------------------------------------------------------------------- */
    /*                                 ERRORES                                */
    /* ---------------------------------------------------------------------- */
    error Err_ZeroAmount();
    error Err_BankCapExceeded();
    error Err_InsufficientBalance();
    error Err_NotSupportedToken();
    error Err_OracleNotFound();
    error Err_InvalidPrice();
    error Err_ETHValueMismatch();
    error Err_TransferFailed();

    /* ---------------------------------------------------------------------- */
    /*                                 EVENTOS                                */
    /* ---------------------------------------------------------------------- */
    event Deposit(address indexed user, address indexed token, uint256 amount);
    event Withdraw(address indexed user, address indexed token, uint256 amount);
    event BankCapUpdated(uint256 newCapUSD);
    event PriceFeedSet(address indexed token, address indexed feed);

    /* ---------------------------------------------------------------------- */
    /*                                STORAGE                                 */
    /* ---------------------------------------------------------------------- */
    // Usuario => Token => Monto depositado
    mapping(address => mapping(address => uint256)) public vaults;

    // Token => Oráculo Chainlink
    mapping(address => AggregatorV3Interface) public priceFeeds;

    // Lista de tokens soportados
    address[] public supportedTokens;

    // Valor máximo en USD que puede tener el banco
    uint256 public bankCapUSD;

    // Valor total actual del banco expresado en USD
    uint256 public totalBankUSDValue;

    /* ---------------------------------------------------------------------- */
    /*                              CONSTRUCTOR                               */
    /* ---------------------------------------------------------------------- */
    /**
     * @param _bankCapUSD Capacidad máxima del banco expresada en USD (6 decimales)
     * @param _ethUsdPriceFeed Dirección del oráculo ETH/USD de Chainlink
     */
    constructor(uint256 _bankCapUSD, address _ethUsdPriceFeed) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);

        bankCapUSD = _bankCapUSD;
        priceFeeds[ETH_ADDRESS] = AggregatorV3Interface(_ethUsdPriceFeed);
        supportedTokens.push(ETH_ADDRESS);
    }

    /* ---------------------------------------------------------------------- */
    /*                              DEPÓSITOS                                 */
    /* ---------------------------------------------------------------------- */
    /**
     * @notice Permite depositar ETH o tokens ERC-20 en el banco.
     * @param tokenAddress Dirección del token (usar address(0) para ETH)
     * @param amount Cantidad a depositar
     */
    function deposit(address tokenAddress, uint256 amount)
        external
        payable
        nonReentrant
    {
        if (amount == 0) revert Err_ZeroAmount();

        uint256 usdAmount = _convertToUSD(tokenAddress, amount);
        if (totalBankUSDValue + usdAmount > bankCapUSD) revert Err_BankCapExceeded();

        // Actualiza balances internos
        unchecked {
            vaults[msg.sender][tokenAddress] += amount;
            totalBankUSDValue += usdAmount;
        }

        // Transferencias según tipo de activo
        if (tokenAddress == ETH_ADDRESS) {
            if (msg.value != amount) revert Err_ETHValueMismatch();
        } else {
            if (msg.value > 0) revert Err_ETHValueMismatch();
            IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), amount);
            if (!_isSupportedToken(tokenAddress)) supportedTokens.push(tokenAddress);
        }

        emit Deposit(msg.sender, tokenAddress, amount);
    }

    /* ---------------------------------------------------------------------- */
    /*                               RETIROS                                  */
    /* ---------------------------------------------------------------------- */
    /**
     * @notice Permite retirar ETH o tokens ERC-20 previamente depositados.
     * @param tokenAddress Dirección del token a retirar
     * @param amount Cantidad a retirar
     */
    function withdraw(address tokenAddress, uint256 amount)
        external
        nonReentrant
    {
        if (amount == 0) revert Err_ZeroAmount();

        uint256 userBalance = vaults[msg.sender][tokenAddress];
        if (userBalance < amount) revert Err_InsufficientBalance();

        uint256 usdAmount = _convertToUSD(tokenAddress, amount);

        unchecked {
            vaults[msg.sender][tokenAddress] -= amount;
            totalBankUSDValue -= usdAmount;
        }

        if (tokenAddress == ETH_ADDRESS) {
            (bool sent, ) = msg.sender.call{value: amount}("");
            if (!sent) revert Err_TransferFailed();
        } else {
            IERC20(tokenAddress).safeTransfer(msg.sender, amount);
        }

        emit Withdraw(msg.sender, tokenAddress, amount);
    }

    /* ---------------------------------------------------------------------- */
    /*                           FUNCIONES INTERNAS                           */
    /* ---------------------------------------------------------------------- */
    /**
     * @dev Convierte un monto en el token indicado a su valor en USD.
     */
    function _convertToUSD(address tokenAddress, uint256 amount)
        internal
        view
        returns (uint256 usdValue)
    {
        AggregatorV3Interface feed = priceFeeds[tokenAddress];
        if (address(feed) == address(0)) revert Err_OracleNotFound();

        (, int256 price, , , ) = feed.latestRoundData();
        if (price <= 0) revert Err_InvalidPrice();

        uint8 feedDecimals = feed.decimals();
        uint8 tokenDecimals =
            tokenAddress == ETH_ADDRESS ? 18 : IERC20Decimals(tokenAddress).decimals();

        usdValue = (amount * uint256(price) * (10 ** USD_DECIMALS)) /
            (10 ** (tokenDecimals + feedDecimals));
    }

    /**
     * @dev Verifica si un token está soportado por el banco.
     */
    function _isSupportedToken(address token) internal view returns (bool) {
        for (uint256 i = 0; i < supportedTokens.length; i++) {
            if (supportedTokens[i] == token) return true;
        }
        return false;
    }

    /* ---------------------------------------------------------------------- */
    /*                           FUNCIONES ADMIN                              */
    /* ---------------------------------------------------------------------- */
    function setBankCapUSD(uint256 newCap) external onlyRole(MANAGER_ROLE) {
        bankCapUSD = newCap;
        emit BankCapUpdated(newCap);
    }

    function setPriceFeed(address token, address feed) external onlyRole(MANAGER_ROLE) {
        priceFeeds[token] = AggregatorV3Interface(feed);
        if (!_isSupportedToken(token)) supportedTokens.push(token);
        emit PriceFeedSet(token, feed);
    }

    /* ---------------------------------------------------------------------- */
    /*                                RECEIVER                                */
    /* ---------------------------------------------------------------------- */
    receive() external payable {}
}


