pragma solidity ^0.8.24;

import { SmartAccount } from "../SmartAccount.sol"; // Review: should just use interface IMSA
import { LibClone } from "solady/src/utils/LibClone.sol"; // to be implemented
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";
import { IAccountFactory } from "../interfaces/factory/IAccountFactory.sol";
import { IModuleManager } from "../interfaces/base/IModuleManager.sol";
import { IModularSmartAccount } from "../interfaces/IModularSmartAccount.sol";
import { MODULE_TYPE_VALIDATOR } from "../interfaces/modules/IERC7579Modules.sol";
import { StakeManager } from "account-abstraction/contracts/core/StakeManager.sol";

contract AccountFactory is IAccountFactory, StakeManager {
    address public immutable ACCOUNT_IMPLEMENTATION;

    constructor(address implementation) {
        ACCOUNT_IMPLEMENTATION = implementation;
    }

    /**
     * @dev Computes the expected address of a SmartAccount contract created via the factory.
     * @param validationModule The address of the module to be used in the SmartAccount.
     * @param moduleInstallData The initialization data for the module.
     * @param index The index or type of the module, for differentiation if needed.
     * @return expectedAddress The address at which the new SmartAccount contract will be deployed.
     */
    function createAccount(
        address validationModule,
        bytes calldata moduleInstallData,
        uint256 index
    ) external payable returns (address payable) {
        bytes32 salt = keccak256(abi.encodePacked(validationModule, moduleInstallData, index));

        (bool alreadyDeployed, address account) = LibClone.createDeterministicERC1967(
            msg.value,
            ACCOUNT_IMPLEMENTATION,
            salt
        );

        if (!alreadyDeployed) {
            IModularSmartAccount(account).initialize(validationModule, moduleInstallData);
        }
        // IModuleManager(account).installModule(MODULE_TYPE_VALIDATOR, validationModule, moduleInstallData);
        return payable(account);
    }

    /**
     * @dev Computes the expected address of a SmartAccount contract created via the factory.
     * @param validationModule The address of the module to be used in the SmartAccount.
     * @param moduleInstallData The initialization data for the module.
     * @param index The index or type of the module, for differentiation if needed.
     * @return expectedAddress The address at which the new SmartAccount contract will be deployed.
     */
    function getCounterFactualAddress(
        address validationModule,
        bytes calldata moduleInstallData,
        uint256 index
    ) external view returns (address payable expectedAddress) {
        bytes32 salt = keccak256(abi.encodePacked(validationModule, moduleInstallData, index));
        expectedAddress = payable(
            LibClone.predictDeterministicAddressERC1967(ACCOUNT_IMPLEMENTATION, salt, address(this))
        );
    }
}
