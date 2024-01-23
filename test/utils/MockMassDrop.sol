// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "lib/solady/src/Milady.sol";

import "src/MassDropERC721.sol";

contract MockMassDropERC721 is MassDropERC721 {
    function name() public view virtual override returns (string memory) {}

    function symbol() public view virtual override returns (string memory) {}

    function tokenURI(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {}

    function mint(address to, uint256 id) public virtual {
        _mint(to, id);
    }

    function burn(uint256 id) public virtual {
        _burn(id);
    }

    function safeMint(address to, uint256 id) public virtual {
        _safeMint(to, id);
    }

    function safeMint(address to, uint256 id, bytes memory data)
        public
        virtual
    {
        _safeMint(to, id, data);
    }
}

contract MockMassDropERC721Factory {
    address public immutable implementation;

    constructor(address _implementation) {
        implementation = _implementation;
    }

    function massDrop(bytes calldata addresses)
        external
        virtual
        returns (MockMassDropERC721 instance)
    {
        unchecked {
            require(addresses.length % 20 == 0, "BAD_DATA");

            instance = MockMassDropERC721(
                LibClone.clone(
                    implementation, abi.encodePacked(SSTORE2.write(addresses))
                )
            );

            instance.initialize(addresses);
        }
    }
}
