// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that calling functions external to the contract, in addition to
 * continuing to execute the current function, can also cause reentrancy
 * due to the mapping of contract addresses to code in the EVM.
 */
abstract contract ReentrancyGuard {
    // The reentrancy guard is implemented as a contract-global state variable
    // that is set to 1 when a function is entered, and set to 2 when exited.
    // The value 0 is never used, to avoid initialization costs.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is safe, as long as the calls are not nested.
     *
     * Note that because there is a single `_status` variable for all functions
     * guarded by the `nonReentrant` modifier, reentrant calls can only be
     * prevented if the reentrancy is not nested.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after the first one will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By setting to _NOT_ENTERED, the next nonReentrant call will succeed
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the contract is currently inside a non-reentrant function.
     *
     * NOTE: This function is only meant to be used inside the contract itself,
     * and it is not safe to rely on its return value in external contracts.
     */
    function _reentrancyGuardStatus() internal view returns (uint256) {
        return _status;
    }
}