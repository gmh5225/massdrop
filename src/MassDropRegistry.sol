// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

contract MassDropRegistry {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error NON_ZERO_VALUE();

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event Registered(address indexed account, uint256 indexed index);

    /// -----------------------------------------------------------------------
    /// Mutables
    /// -----------------------------------------------------------------------

    uint256 public nonce;

    mapping(uint256 => address) public ownerOf;

    mapping(address => uint256) public indexOf;

    /// -----------------------------------------------------------------------
    /// Actions
    /// -----------------------------------------------------------------------
    
    function register(address account) public virtual {
        unchecked {
            uint256 index = (++nonce);

            indexOf[account] = index;

            ownerOf[index] = account;

            emit Registerd(account);
        }
    }

    function register() public virtual {
        register(msg.sender);
    }

    /// -----------------------------------------------------------------------
    /// Fallback
    /// -----------------------------------------------------------------------

    fallback() external payable {
        if (msg.value != 0) revert NON_ZERO_VALUE();

        register(msg.sender);
    }
}