🏦 KipuBank V2: Bóveda Multi-Token con Contabilidad en USD
💡 Descripción General del Proyecto

KipuBankV2 es una refactorización y extensión de la bóveda personal original. Permite depositar y retirar ETH y cualquier token ERC-20, mientras que el límite global del banco (bankCapUSD) se controla en USD usando Chainlink Data Feeds.

Este proyecto simula un entorno de producción: seguro, escalable y auditable, aplicando patrones de diseño como control de acceso basado en roles, contabilidad multi-token y uso de errores personalizados.

Mejoras Realizadas y Fundamento del Diseño

| Área de Mejora                     | Componente Implementado                    | Razón / Fundamento de Diseño                                                      

| Soporte Multi-token y Contabilidad | Mappings Anidados (`vaults[user][token]`)  | Permite manejar múltiples activos de forma segura y escalable, asignando un saldo a cada par usuario-token.

| Control de Acceso                  | OpenZeppelin AccessControl                 | Rol `MANAGER_ROLE` reservado para funciones administrativas, evitando que usuarios normales manipulen 
parámetros críticos. 

| Límites Dinámicos                  | Oráculos Chainlink (AggregatorV3Interface) | Permite calcular `bankCapUSD` en USD y mantener el riesgo estable pese a la volatilidad de ETH o tokens.                   

| Seguridad de Tokens                | OpenZeppelin SafeERC20                     | Mitiga vulnerabilidades en transferencias ERC-20, incluso de tokens no conformes.                                         
| Consistencia de Errores            | Errores Personalizados (Custom Errors)     | Más eficiente en gas y facilita la decodificación de errores por aplicaciones externas.                                    

| Eficiencia de Gas                  | `unchecked` en contadores                  | Evita overflow donde es seguro, optimizando el consumo de gas.                                                             

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
