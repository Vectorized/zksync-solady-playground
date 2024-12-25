// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "../src/ZKsyncSafeTransferLib.sol";

contract Griefer {
    uint256 public receiveNumLoops;

    uint256[] internal _junk;

    event Junk(uint256 indexed i);

    function setReceiveNumLoops(uint256 amount) public {
        receiveNumLoops = amount;
    }

    function execute(address to, bytes memory data) public {
        (bool success,) = to.call(data);
        require(success);
    }

    function doStuff() public payable {
        unchecked {
            uint256 n = receiveNumLoops;
            if (n > 0xffffffff) revert();
            for (uint256 i; i < n; ++i) {
                _junk.push(i);
            }
        }
    }

    receive() external payable {
        doStuff();
    }

    fallback() external payable {
        doStuff();
    }
}

contract ZKsyncSafeTransferLibTest is Test {
    Griefer public griefer;

    function setUp() public {
        griefer = new Griefer();
    }

    function testForceSafeTransferETH() public {
        address vault;
        vm.deal(address(this), 1 ether);
        vault = ZKsyncSafeTransferLib.forceSafeTransferETH(address(griefer), 0.1 ether);
        assertEq(address(griefer).balance, 0.1 ether);

        griefer.setReceiveNumLoops(1 << 128);
        vault = ZKsyncSafeTransferLib.forceSafeTransferETH(address(griefer), 0.1 ether);
        assertEq(address(griefer).balance, 0.1 ether);

        griefer.setReceiveNumLoops(0);
        griefer.execute(vault, abi.encode(address(griefer)));
        assertEq(address(griefer).balance, 0.2 ether);

        griefer.setReceiveNumLoops(1 << 128);
        vault = ZKsyncSafeTransferLib.forceSafeTransferETH(address(griefer), 0.1 ether);

        griefer.setReceiveNumLoops(0);
        griefer.execute(vault, "");
        assertEq(address(griefer).balance, 0.3 ether);

        griefer.setReceiveNumLoops(1 << 128);
        vault = ZKsyncSafeTransferLib.forceSafeTransferETH(address(griefer), 0.1 ether);

        griefer.setReceiveNumLoops(0);
        griefer.execute(vault, abi.encodePacked(address(griefer)));
        assertEq(address(griefer).balance, 0.4 ether);

        address anotherRecipient = address(new Griefer());

        griefer.setReceiveNumLoops(1 << 128);
        vault = ZKsyncSafeTransferLib.forceSafeTransferETH(address(griefer), 0.1 ether);

        griefer.setReceiveNumLoops(0);
        griefer.execute(vault, abi.encodePacked(address(anotherRecipient)));
        assertEq(address(anotherRecipient).balance, 0.1 ether);
    }
}
