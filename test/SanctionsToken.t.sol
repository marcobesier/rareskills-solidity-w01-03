// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {SanctionsToken} from "../src/SanctionsToken.sol";

contract SanctionsTokenTest is Test {
    SanctionsToken public sanctionsToken;
    address public admin;
    address public user1;
    address public user2;

    event Ban(address indexed account);

    error NotAdmin();
    error SenderBanned();
    error RecipientBanned();
    error AccountAlreadyBanned();

    function setUp() public {
        sanctionsToken = new SanctionsToken("SanctionsToken", "ST");
        admin = address(this);
        user1 = address(0x123);
        user2 = address(0x456);
    }

    function testFuzz_MintTokens(uint256 value) public {
        sanctionsToken.mint(user1, value);
        assertEq(sanctionsToken.balanceOf(user1), value);
    }

    function testFuzz_OnlyAdminCanMint(address notAdmin) public {
        vm.assume(notAdmin != admin);
        vm.prank(notAdmin);
        vm.expectRevert(abi.encodeWithSelector(NotAdmin.selector));
        sanctionsToken.mint(notAdmin, 1);
    }

    function testFuzz_BanAccount(address account) public {
        vm.assume(account != admin);
        sanctionsToken.ban(account);
        assertEq(sanctionsToken.banned(account), true);
    }

    function testFuzz_OnlyAdminCanBan(address notAdmin) public {
        vm.assume(notAdmin != admin);
        vm.prank(notAdmin);
        vm.expectRevert(abi.encodeWithSelector(NotAdmin.selector));
        sanctionsToken.ban(notAdmin);
    }

    function testFuzz_CannotBanTwice(address account) public {
        vm.assume(account != admin);
        sanctionsToken.ban(account);
        vm.expectRevert(abi.encodeWithSelector(AccountAlreadyBanned.selector));
        sanctionsToken.ban(account);
    }

    function test_BanEvent() public {
        vm.expectEmit();
        emit Ban(user1);
        sanctionsToken.ban(user1);
    }

    function testFuzz_Transfer(uint256 value) public {
        sanctionsToken.mint(user1, value);
        vm.prank(user1);
        sanctionsToken.transfer(user2, value);
        assertEq(sanctionsToken.balanceOf(user1), 0);
        assertEq(sanctionsToken.balanceOf(user2), value);
    }

    function testFuzz_TransferSenderBanned(address banned) public {
        vm.assume(banned != address(0));
        vm.assume(banned != user1);
        sanctionsToken.mint(banned, 1);
        sanctionsToken.ban(banned);
        vm.prank(banned);
        vm.expectRevert(abi.encodeWithSelector(SenderBanned.selector));
        sanctionsToken.transfer(user1, 1);
    }

    function testFuzz_TransferRecipientBanned(address banned) public {
        vm.assume(banned != user1);
        sanctionsToken.mint(user1, 1);
        sanctionsToken.ban(banned);
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(RecipientBanned.selector));
        sanctionsToken.transfer(banned, 1);
    }

    function testFuzz_TransferFrom(uint256 value) public {
        sanctionsToken.mint(user1, value);
        vm.prank(user1);
        sanctionsToken.approve(user2, value);
        vm.prank(user2);
        sanctionsToken.transferFrom(user1, user2, value);
        assertEq(sanctionsToken.balanceOf(user1), 0);
        assertEq(sanctionsToken.balanceOf(user2), value);
    }

    function testFuzz_TransferFromSenderBanned(address banned) public {
        vm.assume(banned != address(0));
        vm.assume(banned != user1);
        sanctionsToken.mint(banned, 1);
        sanctionsToken.ban(banned);
        vm.prank(banned);
        sanctionsToken.approve(user1, 1);
        vm.expectRevert(abi.encodeWithSelector(SenderBanned.selector));
        sanctionsToken.transferFrom(banned, user1, 1);
    }

    function testFuzz_TransferFromRecipientBanned(address banned) public {
        vm.assume(banned != user1);
        sanctionsToken.mint(user1, 1);
        sanctionsToken.ban(banned);
        vm.prank(user1);
        sanctionsToken.approve(user2, 1);
        vm.expectRevert(abi.encodeWithSelector(RecipientBanned.selector));
        vm.prank(user2);
        sanctionsToken.transferFrom(user1, banned, 1);
    }
}
