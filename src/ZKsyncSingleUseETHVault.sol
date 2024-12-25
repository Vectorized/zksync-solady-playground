// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice A single-use vault that allows a designated caller to withdraw all ETH in it.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/ext/zksync/ZKsyncSingleUseETHVault.sol)
contract ZKsyncSingleUseETHVault {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Unable to withdraw all.
    error WithdrawAllFailed();

    /// @dev Not authorized.
    error Unauthorized();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         IMMUTABLES                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev For upgrades / initialization.
    uint256 private immutable __owner;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CONSTRUCTOR                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    constructor(address owner) payable {
        __owner = uint256(uint160(owner));
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        WITHDRAW ALL                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Allows the owner to withdraw all ETH in this contract.
    function withdrawAll(address to) public {
        uint256 owner = __owner;
        assembly {
            if iszero(eq(caller(), owner)) {
                mstore(0x00, 0x82b42900) // `Unauthorized()`.
                revert(0x1c, 0x04)
            }
            if iszero(to) { to := caller() }
            if iszero(call(gas(), to, selfbalance(), 0x00, 0x00, 0x00, 0x00)) {
                mstore(0x00, 0x651aee10) // `WithdrawAllFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }

    fallback() external virtual {
        address to;
        assembly {
            to := calldataload(0x00)
            if lt(calldatasize(), 0x20) { to := shr(shl(3, sub(0x20, calldatasize())), to) }
        }
        withdrawAll(to);
    }
}
