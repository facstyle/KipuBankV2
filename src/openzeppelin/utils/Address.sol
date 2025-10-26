// src/openzeppelin/utils/Address.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address { 
    /**
     * @dev Returns true if `account` is a contract.
     * ... (Documentation for isContract)
     */
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    /**
     * @dev Converts an `address` into `address payable`. 
     * ... (Documentation for toPayable)
     */
    function toPayable(address account) internal pure returns (address payable) {
        return payable(account);
    }

    // DOCSTRING DELETED HERE (This was the block shown in image_05e71d.png)
    function sendValue(address payable recipient, uint256 value) internal {
        (bool success, ) = recipient.call{value: value}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    // DOCSTRING DELETED HERE
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    // DOCSTRING DELETED HERE
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    // DOCSTRING DELETED HERE
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {functionCallWithValue} but only accepts gas for the call.
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call failed with value");
    }

    /**
     * @dev Same as {functionCall} but only accepts gas for the call.
     */
    function functionCall(address target, bytes memory data, uint256) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {functionCallWithValue} but only accepts gas for the call.
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        uint256 // parameter 'gas' silenced
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call failed with value");
    }

    /**
     * @dev Same as {functionCallWithValue} but only accepts gas for the call,
     * with an explicit message to use for the error.
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        uint256, // parameter 'gas' silenced
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}