// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import {Clone, SSTORE2} from "lib/solady/src/Milady.sol";

import {MassDropERC721} from "src/MassDropERC721.sol";

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract MassDropERC721a is MassDropERC721, Clone {
    /// -----------------------------------------------------------------------
    /// Constants
    /// -----------------------------------------------------------------------

    uint8 internal constant _ADDRESS_SIZE = 0x14;

    /// -----------------------------------------------------------------------
    /// Immutables
    /// -----------------------------------------------------------------------

    function _INITIAL_HOLDERS_POINTER()
        internal
        pure
        virtual
        override
        returns (address)
    {
        return _getArgAddress(0x00);
    }

    function _INITIAL_HOLDERS_LENGTH()
        internal
        view
        virtual
        override
        returns (uint256 result)
    {
        address pointer = _INITIAL_HOLDERS_POINTER();

        /// @solidity memory-safe-assembly
        assembly {
            result := div(sub(extcodesize(pointer), 1), 0x14)
        }
    }

    /// -----------------------------------------------------------------------
    /// Read-Only Accounting Helpers
    /// -----------------------------------------------------------------------

    function _safeOwnerOf(uint256 id)
        internal
        view
        virtual
        override
        returns (address owner)
    {
        unchecked {
            uint256 start = id * _ADDRESS_SIZE;

            bytes32 tokenData = _tokenData[id];

            bool transfered = tokenData[31] == 0xff;

            owner = address(bytes20(tokenData));

            if (
                !transfered && owner == address(0)
                    && id < _INITIAL_HOLDERS_LENGTH()
            ) {
                owner = address(
                    bytes20(
                        SSTORE2.read(
                            _INITIAL_HOLDERS_POINTER(),
                            start,
                            start + _ADDRESS_SIZE
                        )
                    )
                );
            }
        }
    }

    function _safeBalanceOf(address owner)
        internal
        view
        virtual
        override
        returns (uint256 balance)
    {
        (bool found, uint256 index) = _searchSorted(
            _INITIAL_HOLDERS_POINTER(), uint160(owner), _ADDRESS_SIZE
        );

        bool transfered = _tokenData[index][31] == 0xFF;

        unchecked {
            return !transfered && found
                ? _accountData[owner] + 1
                : _accountData[owner];
        }
    }
}
