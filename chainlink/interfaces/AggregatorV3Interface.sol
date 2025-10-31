// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface for Chainlink AggregatorV3 contracts (used for price feeds).
 */
interface AggregatorV3Interface {
    /**
     * @dev Returns the latest price and metadata.
     * @return roundId The round ID.
     * @return answer The price (scaled by decimals).
     * @return startedAt Timestamp when the round started.
     * @return updatedAt Timestamp when the round was updated.
     * @return answeredInRound Round ID when the answer was computed.
     */
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    /**
     * @dev Returns the number of decimals used for the answer.
     */
    function decimals() external view returns (uint256);

    /**
     * @dev Returns the description of the aggregator.
     */
    function description() external view returns (string memory);
}