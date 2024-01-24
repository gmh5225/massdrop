// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {SSTORE2, Initializable} from "lib/solady/src/Milady.sol";

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Modified from Solmate (htps://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract MassDropERC721 is Initializable {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error NOT_MINTED();

    error WRONG_FROM();

    error ZERO_ADDRESS();

    error NOT_AUTHORIZED();

    error ALREADY_MINTED();

    error UNSAFE_RECIPIENT();

    error INVALID_RECIPIENT();

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event Transfer(
        address indexed from, address indexed to, uint256 indexed id
    );

    event Approval(
        address indexed owner, address indexed spender, uint256 indexed id
    );

    event ApprovalForAll(
        address indexed owner, address indexed operator, bool approved
    );

    /// -----------------------------------------------------------------------
    /// Mutables
    /// -----------------------------------------------------------------------

    mapping(uint256 id => bytes32 data) internal _tokenData;

    mapping(address owner => uint256 balance) internal _accountData;

    mapping(uint256 id => address spender) public getApproved;

    mapping(address owner => mapping(address spender => bool approved)) public
        isApprovedForAll;

    /// -----------------------------------------------------------------------
    /// Immutables
    /// -----------------------------------------------------------------------

    function _INITIAL_HOLDERS_POINTER()
        internal
        pure
        virtual
        returns (address);

    function _INITIAL_HOLDERS_LENGTH()
        internal
        view
        virtual
        returns (uint256 result);

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
    /// Read-Only Accounting
    /// -----------------------------------------------------------------------

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        if ((owner = _safeOwnerOf(id)) == address(0)) {
            revert NOT_MINTED();
        }
    }

    function balanceOf(address owner)
        public
        view
        virtual
        returns (uint256 balance)
    {
        if (owner == address(0)) revert ZERO_ADDRESS();
        return _safeBalanceOf(owner);
    }

    /// -----------------------------------------------------------------------
    /// Actions
    /// -----------------------------------------------------------------------

    function approve(address spender, uint256 id) public virtual {
        address owner = ownerOf(id);

        if (!(msg.sender == owner || isApprovedForAll[owner][msg.sender])) {
            revert NOT_AUTHORIZED();
        }

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
    {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // !IDEA: LibObfuscation

    function transferFrom(address from, address to, uint256 id)
        public
        virtual
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

            bool transfered = tokenData[31] == 0xFF;

            if (!transfered && id < _INITIAL_HOLDERS_LENGTH()) {
                _tokenData[id] = _setTrailingByte(bytes32(bytes20(to)), 0xFF);
            } else {
                _tokenData[id] = _setTrailingByte(bytes32(bytes20(to)), 0xFF);
                _accountData[from]--;
            }
        }

        _accountData[to]++;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(address from, address to, uint256 id)
        public
        virtual
    {
        transferFrom(from, to, id);
        _checkOnERC721Received(msg.sender, from, to, id, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);
        _checkOnERC721Received(msg.sender, from, to, id, data);
    }

    /// -----------------------------------------------------------------------
    /// Read-Only Accounting Helpers
    /// -----------------------------------------------------------------------

    function _safeOwnerOf(uint256 id)
        internal
        view
        virtual
        returns (address owner);

    function _safeBalanceOf(address owner)
        internal
        view
        virtual
        returns (uint256 balance);

    function _searchSorted(address pointer, uint256 needle, uint8 size)
        internal
        view
        virtual
        returns (bool found, uint256 index)
    {
        unchecked {
            uint256 length = _INITIAL_HOLDERS_LENGTH();
            uint256 h = length;
            uint256 l = 0;

            while (l < h) {
                index = (l + h) >> 1;
                uint256 o = index * size;
                uint256 t = uint160(bytes20(SSTORE2.read(pointer, o, o + size)));

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
    
    function _setTrailingByte(bytes32 word, uint8 b) internal pure returns (bytes32) {
        word &= bytes32(type(uint256).max) << 8;

        word |= bytes32(uint256(uint8(b)));

        return word;
    }

    /// -----------------------------------------------------------------------
    /// ERC-721 Helpers
    /// -----------------------------------------------------------------------

    function _mint(address to, uint256 id) internal virtual {
        if (to == address(0)) revert INVALID_RECIPIENT();

        if (_safeOwnerOf(id) != address(0)) revert ALREADY_MINTED();

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _accountData[to]++;
        }

        _tokenData[id] = bytes32(bytes20(to));

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _safeOwnerOf(id);

        if (owner == address(0)) revert NOT_MINTED();

        bytes32 tokenData = _tokenData[id];

        bool neverSent = tokenData[31] == 0;

        if (neverSent && id < _INITIAL_HOLDERS_LENGTH()) {
            _tokenData[id] = _setTrailingByte(bytes32(0), 0xFF);
        } else {
            delete _tokenData[id];

            // Ownership check above ensures no underflow.
            unchecked {
                _accountData[owner]--;
            }
        }

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);
        _checkOnERC721Received(msg.sender, address(0), to, id, "");
    }

    function _safeMint(address to, uint256 id, bytes memory data)
        internal
        virtual
    {
        _mint(to, id);
        _checkOnERC721Received(msg.sender, address(0), to, id, data);
    }

    function _checkOnERC721Received(
        address operator,
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        if (
            to.code.length != 0
                && ERC721TokenReceiver(to).onERC721Received(
                    operator, from, id, data
                ) != ERC721TokenReceiver.onERC721Received.selector
        ) revert UNSAFE_RECIPIENT();
    }

    /// -----------------------------------------------------------------------
    /// ERC-721 Metadata
    /// -----------------------------------------------------------------------

    function name() public view virtual returns (string memory);

    function symbol() public view virtual returns (string memory);

    function tokenURI(uint256 id) public view virtual returns (string memory);
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes calldata)
        external
        virtual
        returns (bytes4)
    {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}
