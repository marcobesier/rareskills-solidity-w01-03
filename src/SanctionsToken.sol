// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title SanctionsToken
 * @author Marco Besier
 * @notice This contract implements an ERC-20 token that allows the contract admin to mint tokens to an arbitrary
 * address. Furthermore, the contract admin can ban specified addresses from sending and receiving tokens.
 */
contract SanctionsToken is ERC20 {
    address public immutable admin;
    mapping(address => bool) public banned;

    event Ban(address account);

    error NotAdmin();
    error SenderBanned();
    error RecipientBanned();
    error AccountAlreadyBanned();

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        admin = msg.sender;
    }

    /**
     * @dev Mints new tokens and assigns them to the specified account.
     * Only the admin is allowed to call this function.
     * Emits a {Transfer} event with `from` set to the zero address.
     * @param to The account that will receive the minted tokens.
     * @param value The amount of tokens to mint in units of the smallest denomination.
     */
    function mint(address to, uint256 value) external {
        if (msg.sender != admin) {
            revert NotAdmin();
        }
        _mint(to, value);
    }

    /**
     * @dev Bans an account from using the token.
     * @param account The address of the account to be banned.
     * Emits a {Ban} event.
     * Requirements:
     * - The sender must be the admin.
     * - The account must not already be banned.
     */
    function ban(address account) external {
        if (msg.sender != admin) {
            revert NotAdmin();
        }
        if (banned[account]) {
            revert AccountAlreadyBanned();
        }
        banned[account] = true;
        emit Ban(account);
    }

    /**
     * @dev Overrides the transfer function to check if the sender or recipient is banned before executing the
     * transfer.
     * @param to The address of the recipient.
     * @param value The amount of tokens to transfer in units of the smallest denomination.
     * @return A boolean value indicating whether the transfer was successful.
     */
    function transfer(address to, uint256 value) public override returns (bool) {
        if (banned[msg.sender]) {
            revert SenderBanned();
        }
        if (banned[to]) {
            revert RecipientBanned();
        }
        return super.transfer(to, value);
    }
}
