// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

contract MassDropRegistry {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error ZERO_INDEX();

    error ZERO_ACCOUNT();

    error NON_ZERO_VALUE();

    error ALREADY_REGISTERED();

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event Register(address indexed account, uint256 indexed index);

    /// -----------------------------------------------------------------------
    /// Mutables
    /// -----------------------------------------------------------------------

    uint256 public nonce;

    mapping(uint256 => address) public _ownerOf;

    mapping(address => uint256) public _indexOf;

    function ownerOf(uint256 index)
        public
        view
        virtual
        returns (address account)
    {
        if ((account = _ownerOf[index]) == address(0)) revert ZERO_ACCOUNT();
    }

    function indexOf(address account)
        public
        view
        virtual
        returns (uint256 index)
    {
        return _indexOf[account];
    }

    /// -----------------------------------------------------------------------
    /// Actions
    /// -----------------------------------------------------------------------

    function register(address account) public virtual returns (uint256 index) {
        unchecked {
            if (_indexOf[account] != 0) revert ALREADY_REGISTERED();

            _indexOf[account] = (index = (++nonce));

            _ownerOf[index] = account;

            emit Register(account, index);
        }
    }

    function register() public virtual returns (uint256 index) {
        return register(msg.sender);
    }

    /// -----------------------------------------------------------------------
    /// Fallback
    /// -----------------------------------------------------------------------

    receive() external payable {
        if (msg.value != 0) revert NON_ZERO_VALUE();

        register(msg.sender);
    }
}
