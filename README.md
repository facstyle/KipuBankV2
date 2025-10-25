 🏦 KipuBank V2: Bóveda Multi-Token con Contabilidad en USD
💡 Descripción General del Proyecto
KipuBank V2 es una refactorización y extensión de la bóveda personal original. El objetivo principal fue transformar un contrato básico de depósito en ETH a 
una bóveda multi-token segura y auditable, utilizando estándares profesionales y patrones de diseño avanzados como el control de acceso basado en roles, 
oráculos de precios y contabilidad unificada en USD.

El contrato permite a los usuarios depositar y retirar tokens nativos (ETH) y cualquier token ERC-20 compatible, mientras que el límite global del banco (bankCap) 
es monitoreado en un valor estable (USD).

✨ Mejoras Realizadas y Fundamento del Diseño
A continuación, se detalla la explicación a alto nivel de las principales mejoras implementadas en esta versión y el motivo detrás de ellas:

  Área de Mejora: Soporte Multi-token y Contabilidad
Componente Implementado: Mappings Anidados (vaults[user][token])
Razón / Fundamento de Diseño: El contrato original solo soportaba ETH. Esta mejora permite a la bóveda gestionar múltiples activos de forma segura y escalable, asignando un saldo a cada par usuario-token.

Área de Mejora: Control de Acceso
Componente Implementado: OpenZeppelin AccessControl
Razón / Fundamento de Diseño: Se introdujo para cumplir con el principio de mínima autoridad. El rol MANAGER_ROLE está reservado para funciones administrativas (por ejemplo, establecer un nuevo límite del banco), lo que previene que un atacante o usuario normal manipule parámetros críticos.

Área de Mejora: Límites Dinámicos
Componente Implementado: Oráculos Chainlink (AggregatorV3Interface)
Razón / Fundamento de Diseño: El bankCap original en ETH se volvía obsoleto con la volatilidad. Al basar el límite (bankCapUSD) en USD, garantizamos que el riesgo financiero del banco se mantenga estable independientemente de las fluctuaciones del precio de ETH o de los tokens.

Área de Mejora: Seguridad de Tokens
Componente Implementado: OpenZeppelin SafeERC20
Razón / Fundamento de Diseño: Uso del patrón SafeERC20 para manejar transferencias de tokens, mitigando vulnerabilidades comunes como la falta de valores de retorno en tokens no conformes (tokens que no devuelven true o false en transfer o transferFrom).

Área de Mejora: Consistencia de Errores
Componente Implementado: Errores Personalizados (Custom Errors)
Razón / Fundamento de Diseño: En lugar de require() con strings de error pesados en gas, se utilizaron errores personalizados. Esto es más eficiente en gas y facilita la decodificación de errores por parte de las aplicaciones.

Área de Mejora: Eficiencia de Gas
Componente Implementado: unchecked en Contadores
Razón / Fundamento de Diseño: Se utilizó la palabra clave unchecked en el incremento de contadores internos (por ejemplo, _depositCount) ya que el overflow es matemáticamente imposible en ese contexto. Esto optimiza el consumo de gas.

📐 Decisiones de Diseño Importantes
Contabilidad Unificada en USD (Trade-off)
Decisión: Todos los saldos internos se convierten y comparan contra el bankCapUSD utilizando una base de 6 decimales (similar a USDC).

Trade-off: La conversión de decimales (_convertToUSD) introduce una ligera complejidad en la implementación y depende de la precisión del oráculo. Sin embargo, este trade-off es vital para lograr una contabilidad global y robusta, superior al riesgo de manejar múltiples decimales de tokens volátiles.

Uso de address(0) para ETH
Decisión: Se definió la constante ETH_ADDRESS = address(0) para unificar las funciones deposit y withdraw.

Motivo: Permite usar el mismo mapping anidado (vaults[user][token]) para ETH y ERC-20, simplificando la lógica de la función, ya que solo requiere una comprobación (if (tokenAddress == ETH_ADDRESS)) para diferenciar entre una transferencia nativa y una transferencia ERC-20.

🚀 Instrucciones de Despliegue e Interacción
Este proyecto utiliza Hardhat para el despliegue en la Testnet Sepolia.

Pre-requisitos
Node.js y npm instalados.

Un archivo .env con las variables SEPOLIA_URL y PRIVATE_KEY.

Instalar dependencias de Hardhat, OpenZeppelin y Chainlink:

Bash

npm install
1. Compilación del Contrato
Bash

npx hardhat compile
2. Despliegue en Testnet (Sepolia)
El script de despliegue (scripts/deploy.js) requiere la dirección del oráculo de ETH/USD de Chainlink para la red Sepolia.

Parámetros:

bankCapUSD: Límite global del banco en USD (ej. 1,000,000 * 10^6).

_ethUsdPriceFeed: Dirección del oráculo ETH/USD en Sepolia (ej. 0x694AA1769357215Ef4bE215cd2aa0Ddb242dE17d).

Bash

# Ejemplo de ejecución del script de despliegue:
npx hardhat run scripts/deploy.js --network sepolia
3. Verificación del Código Fuente
Una vez desplegado, el contrato debe verificarse en Etherscan usando sus argumentos de constructor:

Bash

npx hardhat verify --network sepolia <DIRECCION_CONTRATO> <bankCapUSD> <_ethUsdPriceFeed>
4. Ejecución de Pruebas
Para validar toda la lógica, incluyendo los nuevos límites de USD, oráculos y roles:

Bash

npx hardhat test
👨‍💻 Autor
Proyecto desarrollado por Felipe A. Cristaldo

Para la materia de Blockchain y Contratos Inteligentes — [25/10/2025]
