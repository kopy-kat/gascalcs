// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";

contract MockRegistry {
    struct Attestation {
        address module;
        address attesters;
        uint48 time;
        uint48 revokedAt;
    }

    mapping(uint256 => Attestation) _attestations;

    function init() external {
        Attestation memory _attestation =
            Attestation({ module: address(0), attesters: address(0), time: 123, revokedAt: 0 });
        _attestations[0] = _attestation;
        _attestations[1] = _attestation;
        _attestations[2] = _attestation;
        _attestations[3] = _attestation;
    }

    function check(uint256 _id) external view returns (uint48) {
        Attestation storage attestation = _attestations[_id];
        return attestation.time;
    }

    function check256(uint256 _id) external view returns (uint256) {
        Attestation storage attestation = _attestations[_id];
        return uint256(attestation.time);
    }

    function checkN(uint256[] memory _ids) external view returns (uint48[] memory) {
        uint256 attestersLength = _ids.length;

        uint48[] memory attestedAtArray = new uint48[](attestersLength);

        for (uint256 i = 0; i < attestersLength; i++) {
            Attestation storage attestation = _attestations[_ids[i]];
            attestedAtArray[i] = attestation.time;
        }

        return attestedAtArray;
    }

    function checkN256(uint256[] memory _ids) external view returns (uint256[] memory) {
        uint256 attestersLength = _ids.length;

        uint256[] memory attestedAtArray = new uint256[](attestersLength);

        for (uint256 i = 0; i < attestersLength; i++) {
            Attestation storage attestation = _attestations[_ids[i]];
            attestedAtArray[i] = uint256(attestation.time);
        }

        return attestedAtArray;
    }
}

contract UintTypeReturns is Test {
    function testGas() public {
        uint256[] memory ids = new uint256[](4);
        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 2;
        ids[3] = 3;
        MockRegistry registry = new MockRegistry();
        registry.init();

        uint256 gasCheck = gasleft();
        uint48 timestamp = registry.check(0);
        gasCheck = gasCheck - gasleft();

        uint256 gasCheck256 = gasleft();
        uint256 timestamp256 = registry.check256(0);
        gasCheck256 = gasCheck256 - gasleft();

        console.log("gasCheck: %s", gasCheck);
        console.log("gasCheck256: %s", gasCheck256);

        uint256 gasCheckN = gasleft();
        uint48[] memory timestamps = registry.checkN(ids);
        gasCheckN = gasCheckN - gasleft();

        uint256 gasCheckN256 = gasleft();
        uint256[] memory timestamps256 = registry.checkN256(ids);
        gasCheckN256 = gasCheckN256 - gasleft();

        console.log("gasCheckN: %s", gasCheckN);
        console.log("gasCheckN256: %s", gasCheckN256);
    }
}
