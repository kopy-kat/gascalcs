// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {UserOperation, UserOperationLib} from "account-abstraction/interfaces/UserOperation.sol";
import {ECDSA} from "solady/src/utils/ECDSA.sol";
import {IEntryPoint, EntryPoint} from "account-abstraction/core/EntryPoint.sol";
import {SimpleAccountFactory} from "account-abstraction/samples/SimpleAccountFactory.sol";
import {SimpleAccount} from "account-abstraction/samples/SimpleAccount.sol";

contract GasTest is Test {
    IEntryPoint public entryPoint;
    AccountFactory public factory;

    EntryPoint public solidityEntryPoint = new EntryPoint();
    SimpleAccountFactory public simpleAccountFactory = new SimpleAccountFactory(solidityEntryPoint);

    address entrypointAddress = 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789;

    Owner owner;

    function setUp() public {
        address huffEntryPoint = HuffDeployer.deploy("EntryPoint");
        entryPoint = IEntryPoint(entrypointAddress);
        vm.etch(entrypointAddress, huffEntryPoint.code);

        owner = Owner({key: uint256(1), addr: vm.addr(uint256(1))});

        factory = AccountFactory(MINIMAL_ACCOUNT_FACTORY_ADDRESS);
        vm.etch(address(factory), MINIMAL_ACCOUNT_FACTORY_BYTECODE);
    }

    function testGasCalcDiff() public {
        address simpleAccount1 = simpleAccountFactory.getAddress(owner.addr, 0);
        simpleAccountFactory.createAccount(owner.addr, 0);
        vm.deal(simpleAccount1, 1 ether);
        UserOperation memory simpleAccountUserOp = UserOperation({
            sender: simpleAccount1,
            nonce: 0,
            initCode: "",
            callData: abi.encodeWithSignature("execute(address,uint256,bytes)", address(0x696969), 1 wei, ""),
            callGasLimit: 60_000,
            verificationGasLimit: 800_000,
            preVerificationGas: 7,
            maxFeePerGas: 6,
            maxPriorityFeePerGas: 5,
            paymasterAndData: "",
            signature: ""
        });
        simpleAccountUserOp.signature = getSolidityUOSignature(simpleAccountUserOp);

        UserOperation[] memory simpleAccountOps = new UserOperation[](1);
        simpleAccountOps[0] = simpleAccountUserOp;
        uint256 solidityGas = gasleft();
        solidityEntryPoint.handleOps(simpleAccountOps, payable(address(0xdeadbeef)));
        solidityGas = solidityGas - gasleft();
        console.log("solidity gas: %s", solidityGas);
    }

    function testGasCalcDirect() public {
        SimpleAccount simpleAccount1 = simpleAccountFactory.createAccount(owner.addr, 0);
        vm.deal(address(simpleAccount1), 1 ether);
        UserOperation memory simpleAccountUserOp = UserOperation({
            sender: address(simpleAccount1),
            nonce: 0,
            initCode: "",
            callData: abi.encodeWithSignature("execute(address,uint256,bytes)", address(0x696969), 1 wei, ""),
            callGasLimit: 60_000,
            verificationGasLimit: 800_000,
            preVerificationGas: 7,
            maxFeePerGas: 6,
            maxPriorityFeePerGas: 5,
            paymasterAndData: "",
            signature: ""
        });
        simpleAccountUserOp.signature = getSolidityUOSignature(simpleAccountUserOp);

        bytes32 uoHash = solidityEntryPoint.getUserOpHash(simpleAccountUserOp);

        vm.startPrank(address(solidityEntryPoint));
        uint256 gas = gasleft();
        simpleAccount1.validateUserOp(simpleAccountUserOp, uoHash, 1 wei);
        simpleAccount1.execute(address(0x696969), 1 wei, "");
        gas = gas - gasleft();
        console.log("gas: %s", gas);
        vm.stopPrank();
    }

    function getSolidityUOSignature(UserOperation memory userOp) public returns (bytes memory) {
        bytes32 opHash = solidityEntryPoint.getUserOpHash(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(owner.key, ECDSA.toEthSignedMessageHash(opHash));
        bytes memory signature = abi.encodePacked(r, s, v);
        return signature;
    }
}
