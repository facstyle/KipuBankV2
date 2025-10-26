// src/openzeppelin/utils/SafeERC20.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.3) (utils/token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

// RUTAS CORREGIDAS PARA TU ESTRUCTURA:
// 1. Address.sol: Está al mismo nivel que SafeERC20.sol (Dentro de utils/)
import "./Address.sol"; 
// 2. IERC20.sol: Según tu estructura, está en token/ERC20/
import "../token/ERC20/IERC20.sol"; 
// 3. IERC20Permit.sol: Está en src/openzeppelin/extensions/
import "../extensions/IERC20Permit.sol"; 


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure...
 */
library SafeERC20 {
    using Address for address; 

    // ... (El resto del código interno de SafeERC20.sol es el mismo que el anterior)
    
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    
    // [Se omiten las funciones intermedias para brevedad, pero usa el código completo]

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    // ... (resto de funciones como safeIncreaseAllowance, safeDecreaseAllowance, forceApprove) ...

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}