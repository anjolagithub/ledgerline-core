// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title LedgerLineDecoder
/// @notice Decodes the ABI-encoded transaction + receipt bytes returned by the
///         Attestcoin Protocol's proof builder, so LedgerLineReadabilityManager can
///         extract real event data instead of trusting a pre-decoded payload param.
/// @dev Encoding confirmed against Creditcoin's documented format:
///      abi.encode(uint8 txType, bytes[] chunks) — chunk[0] = common tx fields,
///      chunk[last] = receipt fields (status, gasUsed, logs, logsBloom).
///      This is our own implementation of that decoding pattern, not copied from
///      any example repository — the pattern itself is dictated by the protocol's
///      fixed encoding, same as any other on-chain interface we implement to spec.
library LedgerLineDecoder {
    struct LogEntry {
        address emitter;
        bytes32[] topics;
        bytes data;
    }

    struct ReceiptFields {
        uint8 status;
        uint64 gasUsed;
        LogEntry[] logs;
    }

    error EmptyTransactionBytes();
    error UnsupportedTxType(uint8 txType);
    error UnexpectedChunkCount(uint256 got);

    /// @notice Reads the tx type byte without a full decode — cheap early check.
    function getTransactionType(bytes memory encodedTx) internal pure returns (uint8 txType) {
        if (encodedTx.length == 0) revert EmptyTransactionBytes();
        assembly {
            txType := byte(31, mload(add(encodedTx, 32)))
        }
    }

    /// @notice Decodes just the receipt — the only part LedgerLine actually needs.
    function decodeReceipt(bytes memory encodedTx) internal pure returns (ReceiptFields memory receipt) {
        uint8 txType = getTransactionType(encodedTx);
        if (txType > 4) revert UnsupportedTxType(txType);

        (, bytes[] memory chunks) = abi.decode(encodedTx, (uint8, bytes[]));

        // Types 0-2 have 3 chunks (common, type-specific, receipt).
        // Types 3-4 have 4 chunks (common, type-specific, extra, receipt).
        uint256 receiptIdx;
        if (txType <= 2) {
            if (chunks.length != 3) revert UnexpectedChunkCount(chunks.length);
            receiptIdx = 2;
        } else {
            if (chunks.length != 4) revert UnexpectedChunkCount(chunks.length);
            receiptIdx = 3;
        }

        (uint8 status, uint64 gasUsed, LogEntry[] memory logs, ) =
            abi.decode(chunks[receiptIdx], (uint8, uint64, LogEntry[], bytes));

        receipt.status = status;
        receipt.gasUsed = gasUsed;
        receipt.logs = logs;
    }

    /// @notice Finds the first log matching both an event signature and an expected emitter.
    ///         Checking the emitter here (not just the topic) is deliberate — it's the same
    ///         defense-in-depth principle as the manager's authorized-emitter check: don't
    ///         trust a log just because its first topic matches, confirm who emitted it too.
    function findLog(
        ReceiptFields memory receipt,
        bytes32 eventSignature,
        address expectedEmitter
    ) internal pure returns (bool found, LogEntry memory log) {
        for (uint256 i = 0; i < receipt.logs.length; i++) {
            LogEntry memory entry = receipt.logs[i];
            if (
                entry.emitter == expectedEmitter &&
                entry.topics.length > 0 &&
                entry.topics[0] == eventSignature
            ) {
                return (true, entry);
            }
        }
        return (false, log);
    }
}