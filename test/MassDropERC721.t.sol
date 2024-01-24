// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import {Test, console2} from "forge-std/Test.sol";

import "test/utils/MockMassDrop.sol";

function addr(uint160 a) pure returns (address b) {
    assembly {
        b := a
    }
}

/// @author Modified from Solmate (htps://github.com/transmissions11/solmate/blob/main/src/test/ERC721.t.sol)
contract MassDropERC721Test is Test {
    using LibSort for address[];

    MockMassDropERC721 n;
    MockMassDropERC721Factory f;

    function setUp() public {
        f = new MockMassDropERC721Factory(address(new MockMassDropERC721()));
        bytes memory encoded;
        address[] memory orginalOwners = new address[](1000);
        for (uint160 i; i < 1000; ++i) {
            orginalOwners[i] = addr(i + 1);
        }
        orginalOwners.sort();
        for (uint160 i; i < 1000; ++i) {
            encoded = abi.encodePacked(encoded, orginalOwners[i]);
        }
        n = f.massDrop(encoded);
        for (uint160 i; i < 1000; ++i) {
            assertEq(n.ownerOf(i), addr(i + 1));
            assertEq(n.balanceOf(orginalOwners[i]), 1);
        }
    }

    /// -----------------------------------------------------------------------
    /// Massdrop Unit
    /// -----------------------------------------------------------------------

    function testInitialReMint() public {
        n.burn(999);
        n.mint(addr(1), 999);
        assertEq(n.balanceOf(addr(1)), 2);
        assertEq(n.ownerOf(999), addr(1));
    }

    function testInitialBurn() public {
        n.burn(999);
        assertEq(n.balanceOf(addr(1000)), 0);
    }

    function testOwnerOfInitialNotMinted() public {
        n.burn(999);
        vm.expectRevert(MassDropERC721.NOT_MINTED.selector);
        n.ownerOf(999);
    }

    function testInitialTransferFrom() public {
        vm.prank(addr(1));
        n.transferFrom(addr(1), addr(2), 0);
        assertEq(n.getApproved(0), address(0));
        assertEq(n.ownerOf(0), addr(2));
        assertEq(n.balanceOf(addr(2)), 2);
        assertEq(n.balanceOf(addr(1)), 0);
    }

    /// -----------------------------------------------------------------------
    /// Unit
    /// -----------------------------------------------------------------------

    function testMint() public {
        n.mint(address(0xBEEF), 1000);
        assertEq(n.balanceOf(address(0xBEEF)), 1);
        assertEq(n.ownerOf(1000), address(0xBEEF));
    }

    function testBurn() public {
        n.mint(address(0xBEEF), 1000);
        n.burn(1000);
        assertEq(n.balanceOf(address(0xBEEF)), 0);
        vm.expectRevert(MassDropERC721.NOT_MINTED.selector);
        n.ownerOf(1000);
    }

    function testApprove() public {
        n.mint(address(this), 1000);
        n.approve(address(0xBEEF), 1000);
        assertEq(n.getApproved(1000), address(0xBEEF));
    }

    function testApproveBurn() public {
        n.mint(address(this), 1000);
        n.approve(address(0xBEEF), 1000);
        n.burn(1000);
        assertEq(n.balanceOf(address(this)), 0);
        assertEq(n.getApproved(1000), address(0));
        vm.expectRevert(MassDropERC721.NOT_MINTED.selector);
        n.ownerOf(1000);
    }

    function testApproveAll() public {
        n.setApprovalForAll(address(0xBEEF), true);
        assertTrue(n.isApprovedForAll(address(this), address(0xBEEF)));
    }

    function testTransferFrom() public {
        address from = address(0xABCD);
        n.mint(from, 1000);
        vm.prank(from);
        n.approve(address(this), 1000);
        n.transferFrom(from, address(0xBEEF), 1000);
        assertEq(n.getApproved(1000), address(0));
        assertEq(n.ownerOf(1000), address(0xBEEF));
        assertEq(n.balanceOf(address(0xBEEF)), 1);
        assertEq(n.balanceOf(from), 0);
    }

    function testTransferFromSelf() public {
        n.mint(address(this), 1000);
        n.transferFrom(address(this), address(0xBEEF), 1000);
        assertEq(n.getApproved(1000), address(0));
        assertEq(n.ownerOf(1000), address(0xBEEF));
        assertEq(n.balanceOf(address(0xBEEF)), 1);
        assertEq(n.balanceOf(address(this)), 0);
    }

    function testTransferFromApproveAll() public {
        address from = address(0xABCD);
        n.mint(from, 1000);
        vm.prank(from);
        n.setApprovalForAll(address(this), true);
        n.transferFrom(from, address(0xBEEF), 1000);
        assertEq(n.getApproved(1000), address(0));
        assertEq(n.ownerOf(1000), address(0xBEEF));
        assertEq(n.balanceOf(address(0xBEEF)), 1);
        assertEq(n.balanceOf(from), 0);
    }

    function testSafeTransferFromToEOA() public {
        address from = address(0xABCD);
        n.mint(from, 1000);
        vm.prank(from);
        n.setApprovalForAll(address(this), true);
        n.safeTransferFrom(from, address(0xBEEF), 1000);
        assertEq(n.getApproved(1000), address(0));
        assertEq(n.ownerOf(1000), address(0xBEEF));
        assertEq(n.balanceOf(address(0xBEEF)), 1);
        assertEq(n.balanceOf(from), 0);
    }

    function testSafeMintToEOA() public {
        n.safeMint(address(0xBEEF), 1000);
        assertEq(n.ownerOf(1000), address(address(0xBEEF)));
        assertEq(n.balanceOf(address(address(0xBEEF))), 1);
    }

    /// -----------------------------------------------------------------------
    /// Fuzz
    /// -----------------------------------------------------------------------

    function testMint(uint248 key, uint248 id) public {
        vm.assume(key > 1000);
        vm.assume(id > 1000);
        address to = vm.addr(key);
        n.mint(to, id);
        assertEq(n.balanceOf(to), 1);
        assertEq(n.ownerOf(id), to);
    }

    function testBurn(uint248 key, uint248 id) public {
        vm.assume(key > 1000);
        vm.assume(id > 1000);
        address to = vm.addr(key);
        n.mint(to, id);
        n.burn(id);
        assertEq(n.balanceOf(to), 0);
        vm.expectRevert(MassDropERC721.NOT_MINTED.selector);
        n.ownerOf(id);
    }

    function testApprove(uint248 key, uint248 id) public {
        vm.assume(key > 1000);
        vm.assume(id > 1000);
        address to = vm.addr(key);
        n.mint(address(this), id);
        n.approve(to, id);
        assertEq(n.getApproved(id), to);
    }

    function testApproveBurn(uint248 key, uint248 id) public {
        vm.assume(key > 1000);
        vm.assume(id > 1000);
        address to = vm.addr(key);
        n.mint(address(this), id);
        n.approve(address(to), id);
        n.burn(id);
        assertEq(n.balanceOf(address(this)), 0);
        assertEq(n.getApproved(id), address(0));
        vm.expectRevert(MassDropERC721.NOT_MINTED.selector);
        n.ownerOf(id);
    }

    function testApproveAll(uint248 key, bool approved) public {
        vm.assume(key > 1000);
        address to = vm.addr(key);
        n.setApprovalForAll(to, approved);
        assertEq(n.isApprovedForAll(address(this), to), approved);
    }

    function testTransferFrom(uint248 key, uint248 id) public {
        vm.assume(key > 1000);
        vm.assume(id > 1000);
        address to = vm.addr(key);
        address from = address(0xABCD);
        vm.assume(to != address(0));
        vm.assume(to != from);
        n.mint(from, id);
        vm.prank(from);
        n.approve(address(this), id);
        n.transferFrom(from, to, id);
        assertEq(n.getApproved(id), address(0));
        assertEq(n.ownerOf(id), to);
        assertEq(n.balanceOf(to), 1);
        assertEq(n.balanceOf(from), 0);
    }

    function testTransferFromSelf(uint248 key, uint248 id) public {
        vm.assume(key > 1000);
        vm.assume(id > 1000);
        address to = vm.addr(key);
        vm.assume(to != address(0));
        vm.assume(to != address(this));
        n.mint(address(this), id);
        n.transferFrom(address(this), to, id);
        assertEq(n.getApproved(id), address(0));
        assertEq(n.ownerOf(id), to);
        assertEq(n.balanceOf(to), 1);
        assertEq(n.balanceOf(address(this)), 0);
    }

    function testTransferFromApproveAll(uint248 key, uint248 id) public {
        vm.assume(key > 1000);
        vm.assume(id > 1000);
        address to = vm.addr(key);
        address from = address(0xABCD);
        vm.assume(to != address(0));
        vm.assume(to != from);
        n.mint(from, id);
        vm.prank(from);
        n.setApprovalForAll(address(this), true);
        n.transferFrom(from, to, id);
        assertEq(n.getApproved(id), address(0));
        assertEq(n.ownerOf(id), to);
        assertEq(n.balanceOf(to), 1);
        assertEq(n.balanceOf(from), 0);
    }

    function testSafeTransferFromToEOA(uint248 key, uint248 id) public {
        vm.assume(key > 1000);
        vm.assume(id > 1000);
        address to = vm.addr(key);
        address from = address(0xABCD);
        vm.assume(to != address(0));
        vm.assume(to != from);
        if (uint248(uint160(to)) <= 18 || to.code.length > 0) return;
        n.mint(from, id);
        vm.prank(from);
        n.setApprovalForAll(address(this), true);
        n.safeTransferFrom(from, to, id);
        assertEq(n.getApproved(id), address(0));
        assertEq(n.ownerOf(id), to);
        assertEq(n.balanceOf(to), 1);
        assertEq(n.balanceOf(from), 0);
    }

    function testSafeMintToEOA(uint248 key, uint248 id) public {
        vm.assume(key > 1000);
        vm.assume(id > 1000);
        address to = vm.addr(key);
        if (uint248(uint160(to)) <= 18 || to.code.length > 0) return;
        n.safeMint(to, id);
        assertEq(n.ownerOf(id), address(to));
        assertEq(n.balanceOf(address(to)), 1);
    }

    /// -----------------------------------------------------------------------
    /// Unit
    /// -----------------------------------------------------------------------

    function testMintToZero() public {
        vm.expectRevert(MassDropERC721.INVALID_RECIPIENT.selector);
        n.mint(address(0), 1001);
    }

    function testDoubleMint() public {
        n.mint(address(0xBEEF), 1001);
        vm.expectRevert(MassDropERC721.ALREADY_MINTED.selector);
        n.mint(address(0xBEEF), 1001);
    }

    function testBurnNotMinted() public {
        vm.expectRevert(MassDropERC721.NOT_MINTED.selector);
        n.burn(1001);
    }

    function testDoubleBurn() public {
        n.mint(address(0xBEEF), 1001);
        n.burn(1001);
        vm.expectRevert(MassDropERC721.NOT_MINTED.selector);
        n.burn(1001);
    }

    function testApproveNotMinted() public {
        vm.expectRevert(MassDropERC721.NOT_MINTED.selector);
        n.approve(address(0xBEEF), 1001);
    }

    function testApproveUnAuthorized() public {
        n.mint(address(0xCAFE), 1001);
        vm.expectRevert(MassDropERC721.NOT_AUTHORIZED.selector);
        n.approve(address(0xBEEF), 1001);
    }

    function testTransferFromUnOwned() public {
        vm.expectRevert(MassDropERC721.NOT_MINTED.selector);
        n.transferFrom(address(0xFEED), address(0xBEEF), 1001);
    }

    function testTransferFromWrongFrom() public {
        n.mint(address(0xCAFE), 1001);
        vm.expectRevert(MassDropERC721.WRONG_FROM.selector);
        n.transferFrom(address(0xFEED), address(0xBEEF), 1001);
    }

    function testTransferFromToZero() public {
        n.mint(address(this), 1001);
        vm.expectRevert(MassDropERC721.INVALID_RECIPIENT.selector);
        n.transferFrom(address(this), address(0), 1001);
    }

    function testTransferFromNotOwner() public {
        n.mint(address(0xFEED), 1001);
        vm.expectRevert(MassDropERC721.NOT_AUTHORIZED.selector);
        n.transferFrom(address(0xFEED), address(0xBEEF), 1001);
    }

    function testBalanceOfZeroAddress() public {
        vm.expectRevert(MassDropERC721.ZERO_ADDRESS.selector);
        n.balanceOf(address(0));
    }

    function testOwnerOfNotMinted() public {
        vm.expectRevert(MassDropERC721.NOT_MINTED.selector);
        n.ownerOf(1001);
    }

    /// -----------------------------------------------------------------------
    /// Fuzz
    /// -----------------------------------------------------------------------

    function testMintToZero(uint248 id) public {
        vm.assume(id > 1000);
        vm.expectRevert(MassDropERC721.INVALID_RECIPIENT.selector);
        n.mint(address(0), id);
    }

    function testDoubleMint(uint248 key, uint248 id) public {
        vm.assume(key > 1000);
        vm.assume(id > 1000);
        address to = vm.addr(key);

        n.mint(to, id);
        vm.expectRevert(MassDropERC721.ALREADY_MINTED.selector);
        n.mint(to, id);
    }

    function testBurnNotMinted(uint248 id) public {
        vm.assume(id > 1000);
        vm.expectRevert(MassDropERC721.NOT_MINTED.selector);
        n.burn(id);
    }

    function testDoubleBurn(uint248 key, uint248 id) public {
        vm.assume(key > 1000);
        vm.assume(id > 1000);
        address to = vm.addr(key);

        n.mint(to, id);
        n.burn(id);
        vm.expectRevert(MassDropERC721.NOT_MINTED.selector);
        n.burn(id);
    }

    function testApproveNotMinted(uint248 key, uint248 id) public {
        vm.assume(key > 1000);
        vm.assume(id > 1000);
        address to = vm.addr(key);
        vm.expectRevert(MassDropERC721.NOT_MINTED.selector);
        n.approve(to, id);
    }

    function testApproveUnAuthorized(address owner, uint248 key, uint248 id)
        public
    {
        vm.assume(key > 1000);
        vm.assume(id > 1000);
        address to = vm.addr(key);
        if (owner == address(0) || owner == address(this)) {
            owner = address(0xBEEF);
        }
        n.mint(owner, id);
        vm.expectRevert(MassDropERC721.NOT_AUTHORIZED.selector);
        n.approve(to, id);
    }

    function testTransferFromUnOwned(address from, uint248 key, uint248 id)
        public
    {
        vm.assume(key > 1000);
        vm.assume(id > 1000);
        address to = vm.addr(key);
        vm.expectRevert(MassDropERC721.NOT_MINTED.selector);
        n.transferFrom(from, to, id);
    }

    function testTransferFromWrongFrom(
        address owner,
        address from,
        uint248 key,
        uint248 id
    ) public {
        vm.assume(key > 1000);
        vm.assume(id > 1000);
        vm.assume(owner != from);
        vm.assume(owner != address(0));
        address to = vm.addr(key);
        vm.assume(to != address(this));
        vm.assume(to != address(0));
        n.mint(owner, id);
        vm.expectRevert(MassDropERC721.WRONG_FROM.selector);
        n.transferFrom(from, to, id);
    }

    function testTransferFromToZero(uint248 id) public {
        vm.assume(id > 1000);
        n.mint(address(this), id);
        vm.expectRevert(MassDropERC721.INVALID_RECIPIENT.selector);
        n.transferFrom(address(this), address(0), id);
    }

    function testTransferFromNotOwner(address from, uint248 key, uint248 id)
        public
    {
        vm.assume(key > 1000);
        vm.assume(id > 1000);
        vm.assume(from != address(this));
        vm.assume(from != address(0));
        address to = vm.addr(key);
        n.mint(from, id);
        vm.expectRevert(MassDropERC721.NOT_AUTHORIZED.selector);
        n.transferFrom(from, to, id);
    }

    function testOwnerOfNotMinted(uint248 id) public {
        vm.assume(id > 1000);
        vm.expectRevert(MassDropERC721.NOT_MINTED.selector);
        n.ownerOf(id);
    }
}
