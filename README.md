🏦 KipuBank V2: Bóveda Multi-Token con Contabilidad en USD
💡 Descripción General del Proyecto

KipuBankV2 es una refactorización y extensión de la bóveda personal original. Permite depositar y retirar ETH y cualquier token ERC-20, mientras que el límite global del banco (bankCapUSD) se controla en USD usando Chainlink Data Feeds.

Este proyecto simula un entorno de producción: seguro, escalable y auditable, aplicando patrones de diseño como control de acceso basado en roles, contabilidad multi-token y uso de errores personalizados.

Mejoras Realizadas y Fundamento del Diseño

💡 Resumen de Mejoras de Diseño en KipuBank V2

1. Soporte Multi-token y Contabilidad
   
Componente Implementado: Mappings Anidados (vaults[user][token]).

Razón / Fundamento de Diseño: Permite manejar múltiples activos de forma segura y escalable, asignando un saldo a cada par usuario-token.

2. Control de Acceso
Componente Implementado: OpenZeppelin AccessControl.

Razón / Fundamento de Diseño: El rol MANAGER_ROLE está reservado para funciones administrativas, evitando que usuarios normales manipulen parámetros críticos del contrato.

3. Límites Dinámicos
Componente Implementado: Oráculos Chainlink (AggregatorV3Interface).

Razón / Fundamento de Diseño: Permite calcular el bankCapUSD en USD, lo que ayuda a mantener el riesgo estable pese a la volatilidad de ETH o de otros tokens soportados.

4. Seguridad de Tokens
Componente Implementado: OpenZeppelin SafeERC20.

Razón / Fundamento de Diseño: Mitiga vulnerabilidades en transferencias ERC-20, incluso de tokens que no siguen estrictamente el estándar (tokens no conformes).

5. Consistencia de Errores
Componente Implementado: Errores Personalizados (Custom Errors).

Razón / Fundamento de Diseño: El uso de errores personalizados es más eficiente en gas y facilita la decodificación de errores por parte de aplicaciones externas (DApps).

6. Eficiencia de Gas
Componente Implementado: unchecked en contadores.

Razón / Fundamento de Diseño: Evita el overflow checking (verificación de desbordamiento) en operaciones donde el overflow es lógicamente imposible, optimizando así el consumo de gas.

Decisiones de Diseño Importantes

Contabilidad Unificada en USD: Todos los saldos internos se convierten y comparan contra bankCapUSD usando 6 decimales (como USDC).

Uso de address(0) para ETH: Permite unificar la lógica de deposit y withdraw en un solo mapping.

totalBankUSDValue: Mantener un contador global en tiempo real evita loops costosos sobre usuarios y tokens.

Custom Errors: Ahorro de gas y claridad profesional.

Seguridad: Patrón checks-effects-interactions y nonReentrant en funciones críticas.

Funciones Principales

deposit(address token, uint256 amount): Deposita ETH o ERC-20, actualiza balances internos y el total en USD.

withdraw(address token, uint256 amount): Retira ETH o ERC-20, actualiza balances internos y el total en USD.

setBankCapUSD(uint256 newCap): Solo MANAGER_ROLE. Cambia el límite global en USD.

setPriceFeed(address token, address feed): Solo MANAGER_ROLE. Configura el oráculo de Chainlink de un token y lo añade a la lista de soportados.

Despliegue e Interacción
Requisitos

Node.js + npm

Hardhat o Remix

Variables de entorno .env con SEPOLIA_URL y PRIVATE_KEY

Feeds de Chainlink para ETH/USD y otros tokens

Pasos

Instalar dependencias:

npm install


Compilar el contrato:

npx hardhat compile


Desplegar en Sepolia:

npx hardhat run scripts/deploy.js --network sepolia


Parámetros del constructor:

bankCapUSD: Límite global en USD (ej.: 1,000,000 * 10^6)

_ethUsdPriceFeed: Dirección del feed ETH/USD en Sepolia

Verificar en Etherscan:

npx hardhat verify --network sepolia <DIRECCION_CONTRATO> <_ethUsdPriceFeed>


Ejecutar pruebas:

npx hardhat test

Autor

Felipe A. Cristaldo
[25/10/2025]
