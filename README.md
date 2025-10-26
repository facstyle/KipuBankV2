# 💰 KipuBankV2

### Contrato bancario descentralizado con soporte multi-token, oráculos Chainlink y control de acceso basado en roles.

---

## 🧩 Descripción General

**KipuBankV2** es una evolución del contrato original **KipuBank**, diseñado para simular un banco descentralizado en la blockchain de Ethereum.  
Esta versión incorpora **mejoras avanzadas en seguridad, arquitectura y escalabilidad**, aplicando buenas prácticas de Solidity y patrones de diseño modernos.

El contrato permite:
- Depósitos y retiros tanto en **ETH** como en **tokens ERC-20**.
- Conversión de valores en tiempo real a **USD**, utilizando **oráculos de Chainlink**.
- Límite total de valor almacenado en el banco (“**bank cap**”) expresado en USD.
- **Control de acceso por roles**, restringiendo operaciones administrativas.
- **Manejo seguro de tokens** mediante `SafeERC20` y protección `ReentrancyGuard`.

---


---

## 🚀 Mejoras Principales

### 🧱 1. Control de Acceso
Se utiliza **AccessControl** de OpenZeppelin para definir roles:
- `DEFAULT_ADMIN_ROLE`: acceso completo al contrato.
- `MANAGER_ROLE`: puede actualizar límites y oráculos.

Esto permite delegar funciones administrativas sin exponer la seguridad del sistema.

---

### 💱 2. Integración con Chainlink
Cada token soportado puede tener un **oráculo de precio** asociado (por ejemplo, ETH/USD).  
El contrato consulta estos feeds a través de la interfaz `AggregatorV3Interface`.

- Ejemplo del feed ETH/USD en **Sepolia**:
0x694AA1769357215DE4FAC081bf1f309aDC325306


Esto permite expresar el valor total del banco en dólares y controlar límites en USD.

---

### 🧾 3. Contabilidad Interna Multi-token
Los saldos se gestionan mediante:
```solidity
mapping(address => mapping(address => uint256)) public vaults;

donde:

vaults[usuario][token] representa el balance individual por activo.

address(0) se usa para representar ETH.

🧮 4. Conversión de Decimales

Los valores se normalizan a 6 decimales (USD_DECIMALS).
La función _convertToUSD() convierte cualquier token o ETH a USD considerando:

Decimales del token (IERC20.decimals())

Decimales del feed de Chainlink (feed.decimals())

🔒 5. Seguridad y Buenas Prácticas

Patrón Checks-Effects-Interactions.

Protección contra reentradas (ReentrancyGuard).

Transferencias seguras (SafeERC20).

Uso de constantes e inmutables donde corresponde.

Errores personalizados (e.g. Err_ZeroAmount, Err_TransferFailed).

🧪 Instrucciones de Despliegue
✅ Requisitos

Node.js y Hardhat instalados.

Cuenta configurada en Metamask.

Acceso a la red de prueba Sepolia.

API Key opcional de Etherscan (para verificación del contrato).

📜 Pasos

Clonar el repositorio

git clone https://github.com/tu-usuario/KipuBankV2.git
cd KipuBankV2


Instalar dependencias

npm install


Configurar tu archivo .env

PRIVATE_KEY=tu_clave_privada
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/tu_api_key
ETHERSCAN_API_KEY=opcional


Desplegar en Sepolia

npx hardhat run scripts/deploy.js --network sepolia


Ejemplo de salida

KipuBankV2 deployed to: 0xd60C38c6d83d1B6D58398eBD81ae18Bdd9282601

🔍 Interacción Básica
💰 Depositar ETH
deposit(address(0), 1 ether);

💸 Retirar tokens
withdraw(tokenAddress, 500 * 1e18);

⚖️ Actualizar límite del banco
setBankCapUSD(2_000_000 * 1e6);

📊 Establecer nuevo oráculo
setPriceFeed(tokenAddress, chainlinkFeedAddress);

📘 Decisiones de Diseño y Trade-offs

Se priorizó claridad y seguridad sobre micro-optimizaciones de gas.

Los feeds Chainlink se manejan por token, lo cual ofrece flexibilidad pero requiere gestión manual.

supportedTokens se almacena en un array para simplicidad, aunque podría reemplazarse por un mapping(bool) si se busca optimización.

La función _convertToUSD usa precisión decimal basada en USD_DECIMALS para consistencia con tokens tipo USDC/USDT.

🌐 Dirección del Contrato en Testnet

Red: Sepolia
Dirección: 0xd60C38c6d83d1B6D58398eBD81ae18Bdd9282601

Verificación: Exitosa vía Sourcify ✅

👩‍💻 Autor

Felipe
Proyecto presentado para evaluación final del módulo de desarrollo en Solidity.


