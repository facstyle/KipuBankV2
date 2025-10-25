 🏦 KipuBank V2: Bóveda Multi-Token con Contabilidad en USD
💡 Descripción General del Proyecto
KipuBank V2 es una refactorización y extensión de la bóveda personal original. El objetivo principal fue transformar un contrato básico de depósito en ETH a 
una bóveda multi-token segura y auditable, utilizando estándares profesionales y patrones de diseño avanzados como el control de acceso basado en roles, 
oráculos de precios y contabilidad unificada en USD.

El contrato permite a los usuarios depositar y retirar tokens nativos (ETH) y cualquier token ERC-20 compatible, mientras que el límite global del banco (bankCap) 
es monitoreado en un valor estable (USD).

✨ Mejoras Realizadas y Fundamento del Diseño
A continuación, se detalla la explicación a alto nivel de las principales mejoras implementadas en esta versión y el motivo detrás de ellas:

Área de Mejora,Componente Implementado,Razón / Fundamento de Diseño
Soporte Multi-token y Contabilidad,Mappings Anidados (vaults[user][token]),"El contrato original solo soportaba ETH. Esta mejora permite a la bóveda gestionar múltiples activos de forma segura y escalable, asignando un saldo a cada par usuario-token."
Control de Acceso,OpenZeppelin AccessControl,"Se introdujo para cumplir con el principio de mínima autoridad. El rol MANAGER_ROLE está reservado para funciones administrativas (ej. establecer un nuevo límite del banco), lo que previene que un atacante o usuario normal manipule parámetros críticos."
Límites Dinámicos,Oráculos Chainlink (AggregatorV3Interface),"El bankCap original en ETH se volvía obsoleto con la volatilidad. Al basar el límite (bankCapUSD) en USD, garantizamos que el riesgo financiero del banco se mantenga estable independientemente de las fluctuaciones del precio de ETH o de los tokens."
Seguridad de Tokens,OpenZeppelin SafeERC20,"Uso del patrón SafeERC20 para manejar transferencias de tokens, mitigando vulnerabilidades comunes como la falta de valores de retorno en tokens no conformes (tokens que no devuelven true o false en transfer o transferFrom)."
Consistencia de Errores,Errores Personalizados (Custom Errors),"En lugar de require() con strings de error pesados en gas, se utilizaron error personalizados. Esto es más eficiente en gas y facilita la decodificación de errores por parte de las aplicaciones."
Eficiencia de Gas,unchecked en Contadores,Se utilizó la palabra clave unchecked en el incremento de contadores internos (ej. _depositCount) ya que el overflow es matemáticamente imposible en ese contexto. Esto optimiza el consumo de gas.
