// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Script} from "forge-std/Script.sol";
import "../src/utils/ext/zksync/ERC1967Factory.sol";

contract DeployERC1967FactoryScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        new ERC1967Factory{salt: bytes32(0)}();
        vm.stopBroadcast();
    }
}
