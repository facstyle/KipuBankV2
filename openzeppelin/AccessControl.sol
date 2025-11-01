// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/Strings.sol";

abstract contract AccessControl {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;  // <-- Almacena el adminRole como bytes32
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members[account];
    }

    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    function _checkRole(bytes32 role) internal view {
        if (!hasRole(role, msg.sender)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(msg.sender),
                        " is missing role ",
                        Strings.toHexString(role)
                    )
                )
            );
        }
    }

    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;  // <-- Ahora devuelve bytes32 correctamente
    }

    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }

    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;  // <-- Almacena el adminRole en la estructura
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _setupRole(bytes32 role, address account) internal virtual {
        _setRoleAdmin(role, DEFAULT_ADMIN_ROLE);
        _grantRole(role, account);
    }

    uint256[49] private __gap;
}

