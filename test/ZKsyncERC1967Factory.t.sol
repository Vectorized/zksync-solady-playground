// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ZKsyncERC1967Factory, ZKsyncMinimalERC1967Proxy} from "../src/ZKsyncERC1967Factory.sol";

contract SampleImplementation {
    uint256 public x;

    bytes public constant NAME = "Implementation";

    event Foo();

    function foo() public {
        emit Foo();
    }

    function setX(uint256 newX) public {
        x = newX;
    }
}

contract ZKsyncERC1967FactoryTest is Test {
    ZKsyncERC1967Factory public factory;
    SampleImplementation public implementation;

    event LogBytes32(bytes32 x);

    event LogBytes(bytes x);

    function setUp() public {
        factory = new ZKsyncERC1967Factory();
        implementation = new SampleImplementation();
    }

    function testDeployDeterministic() public {
        bytes32 salt = 0x0000000000000000000000000000000000000000ff112233445566778899aabb;
        address predicted = factory.predictDeterministicAddress(salt);
        assertEq(factory.implementationOf(predicted), address(0));
        address instance = factory.deployDeterministic(address(implementation), address(this), salt);
        assertEq(factory.implementationOf(predicted), address(implementation));
        assertEq(predicted, instance);
        SampleImplementation(instance).setX(123);
        assertEq(SampleImplementation(instance).x(), 123);
        assertGt(instance.code.length, 0);
    }
}
