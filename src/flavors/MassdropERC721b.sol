// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import {Clone, SSTORE2} from "lib/solady/src/Milady.sol";

import {MassDropERC721} from "src/MassDropERC721.sol";

import {MassDropRegistry} from "src/MassDropRegistry.sol";

abstract contract MassDropERC721b is MassDropERC721, Clone {
    /// -----------------------------------------------------------------------
    /// Constants
    /// -----------------------------------------------------------------------

    uint8 internal constant _ADDRESS_INDEX_SIZE = 0x03;

    /// -----------------------------------------------------------------------
    /// Setup
    /// -----------------------------------------------------------------------

    function initialize(bytes calldata addresses)
        external
        virtual
        initializer
    {
        unchecked {
            uint256 n = addresses.length / _ADDRESS_INDEX_SIZE;
            for (uint256 i; i < n; ++i) {
                uint256 o = i * _ADDRESS_INDEX_SIZE;
                emit Transfer(
                    address(0),
                    address(
                        accountRegistry().ownerOf(
                            uint24(bytes3(addresses[o:o + _ADDRESS_INDEX_SIZE]))
                        )
                    ),
                    i
                );
            }
        }
    }

    /// -----------------------------------------------------------------------
    /// Immutables
    /// -----------------------------------------------------------------------

    function accountRegistry() public pure virtual returns (MassDropRegistry) {
        return MassDropRegistry(payable(_getArgAddress(0x00)));
    }

    function genesisMintersPointer()
        public
        pure
        virtual
        override
        returns (address)
    {
        return _getArgAddress(0x14);
    }

    function totalGenesisMinters()
        public
        view
        virtual
        override
        returns (uint256 result)
    {
        address pointer = genesisMintersPointer();

        /// @solidity memory-safe-assembly
        assembly {
            result := shr(1, sub(extcodesize(pointer), 1))
        }
    }

    function isGenesisMinter(address owner)
        public
        view
        virtual
        override
        returns (bool)
    {
        (bool found,) = _searchSorted(
            genesisMintersPointer(),
            accountRegistry().indexOf(owner),
            _ADDRESS_INDEX_SIZE
        );

        return found;
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

            bool transfered = tokenData[_LAST_BYTE] == 0xFF;

            owner = address(bytes20(tokenData));

            if (
                !transfered && owner == address(0) && id < totalGenesisMinters()
            ) {
                owner = accountRegistry().ownerOf(
                    uint24(
                        bytes3(
                            SSTORE2.read(
                                genesisMintersPointer(),
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
            genesisMintersPointer(),
            accountRegistry().indexOf(owner),
            _ADDRESS_INDEX_SIZE
        );

        bool transfered = _tokenData[index][_LAST_BYTE] == 0xFF;

        unchecked {
            return !transfered && found
                ? _accountData[owner] + 1
                : _accountData[owner];
        }
    }
}
