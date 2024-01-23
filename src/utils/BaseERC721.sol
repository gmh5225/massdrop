// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Modified from Solmate (htps://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract BaseERC721 {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error NOT_MINTED();

    error WRONG_FROM();

    error ZERO_ADDRESS();

    error NOT_AUTHORIZED();

    error ALREADY_MINTED();

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

    mapping(uint256 id => address spender) public getApproved;

    mapping(address owner => mapping(address spender => bool approved)) public
        isApprovedForAll;

    /// -----------------------------------------------------------------------
    /// Read-Only Accounting
    /// -----------------------------------------------------------------------

    function ownerOf(uint256 id) public view virtual returns (address owner);

    function balanceOf(address owner)
        public
        view
        virtual
        returns (uint256 balance);

    /// -----------------------------------------------------------------------
    /// Actions
    /// -----------------------------------------------------------------------

    function approve(address spender, uint256 id) public virtual;

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
    {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint256 id)
        public
        virtual;

    function safeTransferFrom(address from, address to, uint256 id)
        public
        virtual
    {
        transferFrom(from, to, id);

        require(
            to.code.length == 0
                || ERC721TokenReceiver(to).onERC721Received(
                    msg.sender, from, id, ""
                ) == ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0
                || ERC721TokenReceiver(to).onERC721Received(
                    msg.sender, from, id, data
                ) == ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /// -----------------------------------------------------------------------
    /// ERC-721 Metadata
    /// -----------------------------------------------------------------------

    function name() public view virtual returns (string memory);

    function symbol() public view virtual returns (string memory);

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /// -----------------------------------------------------------------------
    /// ERC-165
    /// -----------------------------------------------------------------------

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        returns (bool)
    {
        return interfaceId == 0x01ffc9a7 // ERC165 Interface ID for ERC165
            || interfaceId == 0x80ac58cd // ERC165 Interface ID for ERC721
            || interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /// -----------------------------------------------------------------------
    /// ERC-721 Mint/Burn Helpers
    /// -----------------------------------------------------------------------

    function _mint(address to, uint256 id) internal virtual;

    function _burn(uint256 id) internal virtual;

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0
                || ERC721TokenReceiver(to).onERC721Received(
                    msg.sender, address(0), id, ""
                ) == ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(address to, uint256 id, bytes memory data)
        internal
        virtual
    {
        _mint(to, id);

        require(
            to.code.length == 0
                || ERC721TokenReceiver(to).onERC721Received(
                    msg.sender, address(0), id, data
                ) == ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
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
