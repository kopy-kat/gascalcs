// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";
import { UserOperation, UserOperationLib } from "account-abstraction/interfaces/UserOperation.sol";
import { ECDSA } from "solady/utils/ECDSA.sol";
import { IEntryPoint, EntryPoint } from "account-abstraction/core/EntryPoint.sol";

interface IValidator {
    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash
    )
        external
        returns (uint256 validationData);
}

contract ValidatorEntireSig is IValidator {
    using ECDSA for bytes32;

    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash
    )
        external
        returns (uint256 validationData)
    {
        bytes32 hash = userOpHash.toEthSignedMessageHash();
        hash.recover(userOp.signature[20:]);
        return 0;
    }
}

contract ValidatorEntireSigReversed is IValidator {
    using ECDSA for bytes32;

    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash
    )
        external
        returns (uint256 validationData)
    {
        bytes32 hash = userOpHash.toEthSignedMessageHash();
        (bytes memory sig,) = abi.decode(userOp.signature, (bytes, address));
        hash.recover(sig);
        return 0;
    }
}

contract ValidatorRawSig is IValidator {
    using ECDSA for bytes32;

    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash
    )
        external
        returns (uint256 validationData)
    {
        bytes32 hash = userOpHash.toEthSignedMessageHash();
        hash.recover(userOp.signature);
        return 0;
    }
}

contract AccountEntireSig {
    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    )
        external
        virtual
        returns (uint256 validationData)
    {
        address validationModule = address(uint160(bytes20(userOp.signature[0:20])));
        validationData = IValidator(validationModule).validateUserOp(userOp, userOpHash);
    }
}

contract AccountEntireSigReversed {
    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    )
        external
        virtual
        returns (uint256 validationData)
    {
        (, address validationModule) = abi.decode(userOp.signature, (bytes, address));
        validationData = IValidator(validationModule).validateUserOp(userOp, userOpHash);
    }
}

contract AccountRawSig {
    function validateUserOp(
        UserOperation memory userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    )
        external
        virtual
        returns (uint256 validationData)
    {
        bytes calldata userOpSignature;
        uint256 userOpEndOffset;
        assembly {
            userOpEndOffset := add(calldataload(0x04), 0x24)
            userOpSignature.offset := add(calldataload(add(userOpEndOffset, 0x120)), userOpEndOffset)
            userOpSignature.length := calldataload(sub(userOpSignature.offset, 0x20))
        }
        address validationModule = address(uint160(bytes20(userOpSignature[0:20])));
        userOp.signature = userOpSignature[20:];
        validationData = IValidator(validationModule).validateUserOp(userOp, userOpHash);
    }
}

contract ValidatorSigParsingTest is Test {
    using ECDSA for bytes32;

    EntryPoint entryPoint = new EntryPoint();

    ValidatorEntireSig validatorEntireSig = new ValidatorEntireSig();
    ValidatorEntireSigReversed validatorEntireSigReversed = new ValidatorEntireSigReversed();
    ValidatorRawSig validatorRawSig = new ValidatorRawSig();

    AccountEntireSig accountEntireSig = new AccountEntireSig();
    AccountEntireSigReversed accountEntireSigReversed = new AccountEntireSigReversed();
    AccountRawSig accountRawSig = new AccountRawSig();

    function testGas() public {
        UserOperation memory userOp = getEmptyUserOp();
        bytes memory sig = getRawSignature(userOp);
        bytes32 userOpHash = entryPoint.getUserOpHash(userOp);
        uint256 missingAccountFunds = 0;

        userOp.signature = abi.encodePacked(address(validatorEntireSig), sig);
        uint256 gasEntireSig = gasleft();
        accountEntireSig.validateUserOp(userOp, userOpHash, missingAccountFunds);
        gasEntireSig = gasEntireSig - gasleft();

        userOp.signature = abi.encode(sig, address(validatorEntireSigReversed));
        uint256 gasEntireSigReversed = gasleft();
        accountEntireSigReversed.validateUserOp(userOp, userOpHash, missingAccountFunds);
        gasEntireSigReversed = gasEntireSigReversed - gasleft();

        userOp.signature = abi.encodePacked(address(validatorRawSig), sig);
        uint256 gasRawSig = gasleft();
        accountRawSig.validateUserOp(userOp, userOpHash, missingAccountFunds);
        gasRawSig = gasRawSig - gasleft();

        console.log("entire sig: %s", gasEntireSig);
        console.log("entire sig reversed: %s", gasEntireSigReversed);
        console.log("raw sig: %s", gasRawSig);
    }

    function getEmptyUserOp() public returns (UserOperation memory userOp) {
        userOp = UserOperation({
            sender: address(0),
            nonce: 0,
            initCode: "",
            callData: "",
            callGasLimit: 0,
            verificationGasLimit: 0,
            preVerificationGas: 0,
            maxFeePerGas: 0,
            maxPriorityFeePerGas: 0,
            paymasterAndData: "",
            signature: ""
        });
    }

    function getRawSignature(UserOperation memory userOp) public returns (bytes memory) {
        bytes32 opHash = entryPoint.getUserOpHash(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(uint256(1), ECDSA.toEthSignedMessageHash(opHash));
        bytes memory signature = abi.encodePacked(r, s, v);
        return signature;
    }
}
