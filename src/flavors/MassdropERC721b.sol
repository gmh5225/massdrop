// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import {Clone, SSTORE2} from "lib/solady/src/Milady.sol";

import {MassDropERC721} from "src/MassDropERC721.sol";

abstract contract MassDropERC721b is MassDropERC721, Clone {
    /// -----------------------------------------------------------------------
    /// Constants
    /// -----------------------------------------------------------------------

    uint8 internal constant _ADDRESS_INDEX_SIZE = 0x02;

    /// -----------------------------------------------------------------------
    /// Immutables
    /// -----------------------------------------------------------------------

    function accountRegistery()
        public
        pure
        virtual
        returns (IAccountRegistery);

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
            result := shr(1, sub(extcodesize(pointer), 1))
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
            uint256 start = id * _ADDRESS_INDEX_SIZE;

            bytes32 tokenData = _tokenData[id];

            bool transfered = tokenData[31] == 0xFF;

            owner = address(bytes20(tokenData));

            if (
                !transfered && owner == address(0)
                    && id < _INITIAL_HOLDERS_LENGTH()
            ) {
                owner = accountRegistery().ownerOf(
                    uint160(
                        bytes20(
                            SSTORE2.read(
                                _INITIAL_HOLDERS_POINTER(),
                                start,
                                start + _ADDRESS_INDEX_SIZE
                            )
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
            _INITIAL_HOLDERS_POINTER(),
            accountRegistery().identifierOf(owner),
            _ADDRESS_INDEX_SIZE
        );

        bool transfered = _tokenData[index][31] == 0xFF;

        unchecked {
            return !transfered && found
                ? _accountData[owner] + 1
                : _accountData[owner];
        }
    }
}

// QUESTION: Is it possible to store these two values in the same slot?
interface IAccountRegistery {
    function ownerOf(uint256 identifier)
        external
        view
        returns (address owner);
    function identifierOf(address owner)
        external
        view
        returns (uint256 identifier);
}
