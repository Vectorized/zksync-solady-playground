// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice A sufficiently minimal upgradeable beacon tailor-made for ZKsync.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/ext/zksync/ZKsyncUpgradeableBeacon.sol)
contract ZKsyncUpgradeableBeacon {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Emitted when the implementation of the beacon is upgraded.
    event Upgraded(address indexed implementation);

    /// @dev `keccak256(bytes("Upgraded(address)"))`.
    uint256 private constant _UPGRADED_EVENT_SIGNATURE =
        0xbc7cd75a20ee27fd9adebab32041f755214dbc6bffa90cc0225b39da2e5c2d3b;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev To store the implementation.
    uint256 private _implementation;

    /// @dev For upgrades / initialization.
    uint256 private _deployer;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CONSTRUCTOR                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    constructor() payable {
        _deployer = uint256(uint160(msg.sender));
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*               UPGRADEABLE BEACON OPERATIONS                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the implementation stored in the beacon.
    /// See: https://eips.ethereum.org/EIPS/eip-1967#beacon-contract-address
    function implementation() public view returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := sload(_implementation.slot)
        }
    }

    fallback() external virtual {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x40, 0) // Optimization trick to remove free memory pointer initialization.
            let newImplementation := calldataload(0x00)
            // Revert if the caller is not the deployer. We will still allow the implementation
            // to be set to an empty contract for simplicity.
            if iszero(eq(caller(), sload(_deployer.slot))) { revert(0x00, 0x00) }
            sstore(_implementation.slot, newImplementation)
            // Emit the {Upgraded} event.
            log2(0x00, 0x00, _UPGRADED_EVENT_SIGNATURE, newImplementation)
        }
    }
}
