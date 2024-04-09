// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";

type PackedModuleTypes is uint32;

type ModuleType is uint256;

using { moduleTypeEq as == } for ModuleType global;
using { moduleTypeNeq as != } for ModuleType global;

function moduleTypeEq(ModuleType uid1, ModuleType uid2) pure returns (bool) {
    return ModuleType.unwrap(uid1) == ModuleType.unwrap(uid2);
}

function moduleTypeNeq(ModuleType uid1, ModuleType uid2) pure returns (bool) {
    return ModuleType.unwrap(uid1) != ModuleType.unwrap(uid2);
}

contract PackTest is Test {
    function isType(PackedModuleTypes self, ModuleType moduleType) internal pure returns (bool) {
        return (PackedModuleTypes.unwrap(self) & 2 ** ModuleType.unwrap(moduleType)) != 0;
    }

    function isType(uint32 packed, uint256 check) internal pure returns (bool) {
        return (packed & 2 ** check) != 0;
    }

    function pack(ModuleType[] memory moduleTypes) internal pure returns (PackedModuleTypes) {
        uint256 length = moduleTypes.length;
        uint32 packed;
        uint256 _type;
        for (uint256 i; i < length; i++) {
            _type = ModuleType.unwrap(moduleTypes[i]);
            if (_type > 31 && isType(packed, _type)) revert("InvalidModuleType()");
            packed = packed + uint32(2 ** _type);
        }
        return PackedModuleTypes.wrap(packed);
    }

    function testPack() public {
        ModuleType[] memory moduleTypes = new ModuleType[](2);
        moduleTypes[0] = ModuleType.wrap(1);
        moduleTypes[1] = ModuleType.wrap(2);
        PackedModuleTypes packed = pack(moduleTypes);
        assertTrue(isType(packed, ModuleType.wrap(1)));
        assertTrue(isType(packed, ModuleType.wrap(2)));
        assertFalse(isType(packed, ModuleType.wrap(3)));
    }

    function testPack__Invalid() public {
        ModuleType[] memory moduleTypes = new ModuleType[](2);
        moduleTypes[0] = ModuleType.wrap(1);
        moduleTypes[1] = ModuleType.wrap(1);
        PackedModuleTypes packed = pack(moduleTypes);
        assertTrue(isType(packed, ModuleType.wrap(1)));
        // assertFalse(isType(packed, ModuleType.wrap(2)));
        // assertFalse(isType(packed, ModuleType.wrap(3)));
    }
}
