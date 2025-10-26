// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (v5.4.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures.
 *
 * For more information, see https://eips.ethereum.org/EIPS/eip-2612.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The signature is valid for a single usage only.
     *
     * See {IERC20-approve}.
     *
     * May emit {Approval} event.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current value of the nonce for `owner`. This value must be
     * included in all signatures issued by `owner`.
     *
     * 
     *
     * NOTE: the current implementation does not use `ERC20Permit(owner).nonces()`
     * but instead ERC-2612's `nonces(owner)` function.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature.
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}