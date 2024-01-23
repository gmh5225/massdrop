// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import {Clone, SSTORE2, Initializable} from "lib/solady/src/Milady.sol";

import {BaseERC721} from "src/utils/BaseERC721.sol";

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract MassDropERC721 is BaseERC721, Initializable, Clone {
    /// -----------------------------------------------------------------------
    /// Mutables
    /// -----------------------------------------------------------------------

    mapping(uint256 id => bytes32 data) internal _tokenData;

    mapping(address owner => uint256 balance) internal _accountData;

    /// -----------------------------------------------------------------------
    /// Immutables
    /// -----------------------------------------------------------------------

    function _INITIAL_HOLDERS_POINTER()
        internal
        pure
        virtual
        returns (address)
    {
        return _getArgAddress(0x00);
    }

    function _INITIAL_HOLDERS_LENGTH()
        internal
        view
        virtual
        returns (uint256 result)
    {
        address pointer = _INITIAL_HOLDERS_POINTER();

        /// @solidity memory-safe-assembly
        assembly {
            result := div(sub(extcodesize(pointer), 1), 0x14)
        }
    }

    /// -----------------------------------------------------------------------
    /// Setup
    /// -----------------------------------------------------------------------

    function initialize(bytes calldata addresses)
        external
        virtual
        initializer
    {
        unchecked {
            uint256 n = addresses.length / 20;
            for (uint256 i; i < n; ++i) {
                emit Transfer(
                    address(0),
                    address(bytes20(addresses[i * 20:i * 20 + 20])),
                    i
                );
            }
        }
    }

    /// -----------------------------------------------------------------------
    /// Actions
    /// -----------------------------------------------------------------------

    function approve(address spender, uint256 id) public virtual override {
        address owner = ownerOf(id);

        if (!(msg.sender == owner || isApprovedForAll[owner][msg.sender])) {
            revert NOT_AUTHORIZED();
        }

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function transferFrom(address from, address to, uint256 id)
        public
        virtual
        override
    {
        if (!(from == ownerOf(id))) revert WRONG_FROM();

        if (to == address(0)) revert INVALID_RECIPIENT();

        if (
            !(
                msg.sender == from || isApprovedForAll[from][msg.sender]
                    || msg.sender == getApproved[id]
            )
        ) {
            revert NOT_AUTHORIZED();
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            bytes32 tokenData = _tokenData[id];

            bool neverSent = tokenData[0] == 0;

            if (neverSent && id < _INITIAL_HOLDERS_LENGTH()) {
                _tokenData[id] = _setLeadingByte(bytes32(bytes20(to)), 0xFF);
            } else {
                _tokenData[id] = bytes32(bytes20(to));
                _accountData[from]--;
            }
        }

        _accountData[to]++;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    /// -----------------------------------------------------------------------
    /// Read-Only Accounting
    /// -----------------------------------------------------------------------

    function ownerOf(uint256 id)
        public
        view
        virtual
        override
        returns (address owner)
    {
        if ((owner = _safeOwnerOf(id)) == address(0)) {
            revert NOT_MINTED();
        }
    }

    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256 balance)
    {
        if (owner == address(0)) revert ZERO_ADDRESS();
        return _safeBalanceOf(owner);
    }

    /// -----------------------------------------------------------------------
    /// Read-Only Accounting Helpers
    /// -----------------------------------------------------------------------

    function _safeOwnerOf(uint256 id)
        internal
        view
        virtual
        returns (address owner)
    {
        unchecked {
            uint256 start = id * 0x14;

            bytes32 tokenData = _tokenData[id];

            bool neverSent = tokenData[0] == 0;

            owner = address(bytes20(tokenData));

            if (
                neverSent && owner == address(0)
                    && id < _INITIAL_HOLDERS_LENGTH()
            ) {
                owner = address(
                    bytes20(
                        SSTORE2.read(
                            _INITIAL_HOLDERS_POINTER(), start, start + 0x14
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
        returns (uint256 balance)
    {
        (bool found, uint256 index) =
            _searchSorted(_INITIAL_HOLDERS_POINTER(), owner);

        bool neverSent = _tokenData[index] == 0;

        unchecked {
            return neverSent && found
                ? _accountData[owner] + 1
                : _accountData[owner];
        }
    }

    function _searchSorted(address pointer, address needle)
        internal
        view
        returns (bool found, uint256 index)
    {
        unchecked {
            uint256 length = _INITIAL_HOLDERS_LENGTH();
            uint256 h = length;
            uint256 l = 0;

            while (l < h) {
                index = (l + h) >> 1;
                uint256 o = index * 20;
                address t = address(bytes20(SSTORE2.read(pointer, o, o + 20)));

                if (t == needle) {
                    found = true;
                    return (found, index);
                } else if (t < needle) {
                    l = index + 1;
                } else {
                    h = index;
                }
            }

            // `index` will be zero in the case of an empty array,
            // or when the value is less than the smallest value in the array.
            return (false, index);
        }
    }

    function _setLeadingByte(bytes32 data, uint8 b)
        internal
        pure
        returns (bytes32 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := or(and(data, shr(8, not(0))), shl(248, b))
        }
    }

    /// -----------------------------------------------------------------------
    /// ERC-721 Mint/Burn Helpers
    /// -----------------------------------------------------------------------

    function _mint(address to, uint256 id) internal virtual override {
        if (to == address(0)) revert INVALID_RECIPIENT();

        if (_safeOwnerOf(id) != address(0)) revert ALREADY_MINTED();

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _accountData[to]++;
        }

        _tokenData[id] = bytes32(bytes20(to));

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual override {
        address owner = _safeOwnerOf(id);

        if (owner == address(0)) {
            revert NOT_MINTED();
        }

        // Ownership check above ensures no underflow.
        unchecked {
            _accountData[owner]--;
        }

        delete _tokenData[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }
}
