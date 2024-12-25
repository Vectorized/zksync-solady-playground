// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ZKsyncMinimalERC1967Proxy} from "./ZKsyncMinimalERC1967Proxy.sol";

/// @notice A factory for deploying minimal ERC1967 proxies on ZKsync.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/ext/zksync/ZKsyncERC1967Factory.sol)
contract ZKsyncERC1967Factory {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The caller is not authorized to call the function.
    error Unauthorized();

    /// @dev The proxy deployment failed.
    error DeploymentFailed();

    /// @dev The upgrade failed.
    error UpgradeFailed();

    /// @dev The salt does not start with the caller.
    error SaltDoesNotStartWithCaller();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The admin of a proxy contract has been changed.
    event AdminChanged(address indexed proxy, address indexed admin);

    /// @dev The implementation for a proxy has been upgraded.
    event Upgraded(address indexed proxy, address indexed implementation);

    /// @dev A proxy has been deployed.
    event Deployed(address indexed proxy, address indexed implementation, address indexed admin);

    /// @dev `keccak256(bytes("AdminChanged(address,address)"))`.
    uint256 internal constant _ADMIN_CHANGED_EVENT_SIGNATURE =
        0x7e644d79422f17c01e4894b5f4f588d331ebfa28653d42ae832dc59e38c9798f;

    /// @dev `keccak256(bytes("Upgraded(address,address)"))`.
    uint256 internal constant _UPGRADED_EVENT_SIGNATURE =
        0x5d611f318680d00598bb735d61bacf0c514c6b50e1e5ad30040a4df2b12791c7;

    /// @dev `keccak256(bytes("Deployed(address,address,address)"))`.
    uint256 internal constant _DEPLOYED_EVENT_SIGNATURE =
        0xc95935a66d15e0da5e412aca0ad27ae891d20b2fb91cf3994b6a3bf2b8178082;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         IMMUTABLES                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The hash of the proxy.
    bytes32 public immutable proxyHash;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CONSTRUCTOR                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    constructor() payable {
        proxyHash = _extcodehash(address(new ZKsyncMinimalERC1967Proxy()));
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      ADMIN FUNCTIONS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the admin of the proxy.
    function adminOf(address proxy) public view returns (address admin) {
        assembly {
            admin := sload(proxy)
        }
    }

    /// @dev Sets the admin of the proxy.
    /// The caller of this function must be the admin of the proxy on this factory.
    function changeAdmin(address proxy, address admin) public {
        assembly {
            // Check if the caller is the admin of the proxy.
            if iszero(eq(sload(proxy), caller())) {
                mstore(0x00, 0x82b42900) // `Unauthorized()`.
                revert(0x1c, 0x04)
            }
            // Store the admin for the proxy.
            sstore(proxy, admin)
            // Emit the {AdminChanged} event.
            log3(0x00, 0x00, _ADMIN_CHANGED_EVENT_SIGNATURE, proxy, admin)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     UPGRADE FUNCTIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Upgrades the proxy to point to `implementation`.
    /// The caller of this function must be the admin of the proxy on this factory.
    function upgrade(address proxy, address implementation) public payable {
        upgradeAndCall(proxy, implementation, _emptyData());
    }

    /// @dev Upgrades the proxy to point to `implementation`.
    /// Then, calls the proxy with abi encoded `data`.
    /// The caller of this function must be the admin of the proxy on this factory.
    function upgradeAndCall(address proxy, address implementation, bytes calldata data) public payable {
        assembly {
            // Check if the caller is the admin of the proxy.
            if iszero(eq(sload(proxy), caller())) {
                mstore(0x00, 0x82b42900) // `Unauthorized()`.
                revert(0x1c, 0x04)
            }
            // Set up the calldata to upgrade the proxy.
            let m := mload(0x40)
            mstore(m, implementation)
            calldatacopy(add(m, 0x20), data.offset, data.length)
            // Try upgrading the proxy and revert upon failure.
            if iszero(call(gas(), proxy, callvalue(), m, add(0x20, data.length), 0x00, 0x00)) {
                // Revert with the `UpgradeFailed` selector if there is no error returndata.
                if iszero(returndatasize()) {
                    mstore(0x00, 0x55299b49) // `UpgradeFailed()`.
                    revert(0x1c, 0x04)
                }
                // Otherwise, bubble up the returned error.
                returndatacopy(0x00, 0x00, returndatasize())
                revert(0x00, returndatasize())
            }
            // Emit the {Upgraded} event.
            log3(0, 0, _UPGRADED_EVENT_SIGNATURE, proxy, implementation)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      DEPLOY FUNCTIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Deploys a proxy for `implementation`, with `admin`,
    /// and returns its address.
    /// The value passed into this function will be forwarded to the proxy.
    function deploy(address implementation, address admin) public payable returns (address proxy) {
        proxy = deployAndCall(implementation, admin, _emptyData());
    }

    /// @dev Deploys a proxy for `implementation`, with `admin`,
    /// and returns its address.
    /// The value passed into this function will be forwarded to the proxy.
    /// Then, calls the proxy with abi encoded `data`.
    function deployAndCall(address implementation, address admin, bytes calldata data)
        public
        payable
        returns (address proxy)
    {
        proxy = _deploy(uint160(implementation), uint160(admin), bytes32(0), 0, data);
    }

    /// @dev Deploys a proxy for `implementation`, with `admin`, `salt`,
    /// and returns its deterministic address.
    /// The value passed into this function will be forwarded to the proxy.
    function deployDeterministic(address implementation, address admin, bytes32 salt)
        public
        payable
        returns (address proxy)
    {
        proxy = deployDeterministicAndCall(implementation, admin, salt, _emptyData());
    }

    /// @dev Deploys a proxy for `implementation`, with `admin`, `salt`,
    /// and returns its deterministic address.
    /// The value passed into this function will be forwarded to the proxy.
    /// Then, calls the proxy with abi encoded `data`.
    function deployDeterministicAndCall(address implementation, address admin, bytes32 salt, bytes calldata data)
        public
        payable
        returns (address proxy)
    {
        assembly {
            // If the salt does not start with the zero address or the caller.
            if iszero(or(iszero(shr(96, salt)), eq(caller(), shr(96, salt)))) {
                mstore(0x00, 0x2f634836) // `SaltDoesNotStartWithCaller()`.
                revert(0x1c, 0x04)
            }
        }
        proxy = _deploy(uint160(implementation), uint160(admin), salt, 1, data);
    }

    /// @dev Deploys the proxy, with optionality to deploy deterministically with a `salt`.
    function _deploy(uint256 implementation, uint256 admin, bytes32 salt, uint256 useSalt, bytes calldata data)
        internal
        returns (address proxy)
    {
        bytes memory c = type(ZKsyncMinimalERC1967Proxy).creationCode;
        assembly {
            // Create the proxy.
            switch useSalt
            case 0 { proxy := create(0, add(c, 0x20), mload(c)) }
            default { proxy := create2(0, add(c, 0x20), mload(c), salt) }
            // Revert if the creation fails.
            if iszero(proxy) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }

            // Set up the calldata to set the implementation of the proxy.
            let m := mload(0x40)
            mstore(m, implementation)
            calldatacopy(add(m, 0x20), data.offset, data.length)
            // Try setting the implementation on the proxy and revert upon failure.
            if iszero(call(gas(), proxy, callvalue(), m, add(0x20, data.length), 0x00, 0x00)) {
                // Revert with the `DeploymentFailed` selector if there is no error returndata.
                if iszero(returndatasize()) {
                    mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                    revert(0x1c, 0x04)
                }
                // Otherwise, bubble up the returned error.
                returndatacopy(0x00, 0x00, returndatasize())
                revert(0x00, returndatasize())
            }
            // Store the admin for the proxy.
            sstore(proxy, admin)
            // Emit the {Deployed} event.
            log4(0x00, 0x00, _DEPLOYED_EVENT_SIGNATURE, proxy, implementation, admin)
        }
    }

    /// @dev Returns the address of the proxy deployed with `salt`.
    function predictDeterministicAddress(bytes32 salt) public view returns (address) {
        bytes32 h = keccak256(
            abi.encode(
                keccak256("zksyncCreate2"), bytes32(uint256(uint160(address(this)))), salt, proxyHash, keccak256("")
            )
        );
        return address(uint160(uint256(h)));
    }

    /// @dev Returns if `proxy` is a valid minimal ZKsync ERC1967 proxy that is deployed.
    function isValidProxy(address proxy) public view returns (bool) {
        return _extcodehash(proxy) == proxyHash;
    }

    /// @dev Returns the implementation of `proxy`.
    /// If the `proxy` has not been deployed, or is not a valid proxy, returns `address(0)`.
    function implementationOf(address proxy) public view returns (address result) {
        if (!isValidProxy(proxy)) return address(0);
        assembly {
            mstore(0x00, 0)
            if iszero(staticcall(gas(), proxy, 0x00, 0x01, 0x00, 0x20)) { revert(0x00, 0x00) }
            result := mload(0x00)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          HELPERS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Helper function to return an empty bytes calldata.
    function _emptyData() internal pure returns (bytes calldata data) {
        assembly {
            data.length := 0
        }
    }

    /// @dev Returns the hash of `instance`.
    function _extcodehash(address instance) internal view returns (bytes32 result) {
        assembly {
            result := extcodehash(instance)
        }
    }
}
