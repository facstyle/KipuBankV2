// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support for an interface.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    function __ERC165_init() internal onlyInitializing {
        // Derived contracts need only register the interface itself.
        _registerInterface(type(IERC165).interfaceId);
    }

    // solhint-disable-next-line func-name-mixedcase
    function __ERC165_init_unchained() internal onlyInitializing {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Internal function that registers an interface id as being supported.
     * @param interfaceId The interface id to register.
     * @custom:oz-upgradable
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }

    /**
     * @dev Modifier to allow initializations in derived contracts.
     */
    modifier onlyInitializing() {
        if (_initializing) revert ("Invalid initialization");
        _;
    }

    /**
     * @dev Internal variable to track if the contract is initializing.
     */
    bool private _initializing;

    /**
     * @dev Internal function to set the initializing state.
     */
    function _setInitializing(bool initializing) internal {
        _initializing = initializing;
    }
}