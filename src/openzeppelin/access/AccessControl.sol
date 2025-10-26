// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

// RUTA CORREGIDA: Se usa la ruta absoluta para Context.sol
import "src/openzeppelin/utils/Context.sol";
import "./IAccessControl.sol";
// RUTA CORREGIDA: Se usa la ruta absoluta para ERC165.sol
import "src/openzeppelin/utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access control mechanisms.
 *
 * Roles are exposed publicly using getters to allow easier inspection.
 * Role initial grants can be accomplished via the {AccessControl-constructor}.
 *
 * NOTE: All calls to `_checkRole` require the caller to have the role's
 * admin role.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Slashes across {AccessControl-checkRole}.
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IAccessControl-hasRole}.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev See {IAccessControl-getRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Checks that the account can be used to perform transactions and reverts
     * with {AccessControl-AccessControlUnauthorizedAccount} if not.
     *
     * In an inherited contract, you should probably use the {onlyRole} modifier instead.
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev AccessControlUnauthorizedAccount is an error containing the account and role
     * that caused the failure.
     *
     * The `_checkRole` function internal implementation uses a custom error
     * rather than a Solidity `require` statement to save gas.
     */
    error AccessControlUnauthorizedAccount(address account, bytes32 role);

    /**
     * @dev Checks that the account can be used to perform transactions and reverts
     * with {AccessControl-AccessControlUnauthorizedAccount} if not.
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert AccessControlUnauthorizedAccount(account, role);
        }
    }

    /**
     * @dev See {IAccessControl-grantRole}.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Internal function without access control.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Internal function without access control.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev See {IAccessControl-revokeRole}.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev See {IAccessControl-renounceRole}.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as the admin role for `role`.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }
}