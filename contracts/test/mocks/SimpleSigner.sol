// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import { TrustedForwarder } from "contracts/utils/TrustedForwarder.sol";
import { ISignerValidator } from "contracts/interfaces/ISignerValidator.sol";
import {ECDSA} from "solady/utils/ECDSA.sol";

contract SimpleSigner is ISignerValidator, TrustedForwarder {

    mapping(address => uint256) public usedIds;
    mapping(bytes32 signerId => mapping(address smartAccount => address)) public signer;

    function checkSignature(bytes32 signerId, address sender, bytes32 hash, bytes calldata sig)
        external
        view
        override
        returns (bytes4)
    {
        address owner = signer[signerId][sender];
        if (owner == ECDSA.recover(hash, sig)) {
            return 0x1626ba7e;
        }
        bytes32 ethHash = ECDSA.toEthSignedMessageHash(hash);
        address recovered = ECDSA.recover(ethHash, sig);
        if (owner != recovered) {
            return 0xffffffff;
        }
        return 0x1626ba7e;
    }

    function _onInstallSigner(bytes32 signerId, bytes calldata _data) internal {
        address smartAccount = _getAccount(signerId);
        require(signer[signerId][smartAccount] == address(0));
        usedIds[smartAccount]++;
        signer[signerId][smartAccount] = address(bytes20(_data[0:20]));
    }

    function _onUninstallSigner(bytes32 signerId, bytes calldata) internal {
        address smartAccount = _getAccount(signerId);
        require(signer[signerId][smartAccount] != address(0));
        usedIds[smartAccount]--;
    }

    function isInitialized(address smartAccount) external view returns (bool) {
        return usedIds[smartAccount] > 0;
    }

    function onInstall(bytes calldata data) external payable {
        bytes32 id = bytes32(data[0:32]);
        bytes calldata _data = data[32:];
        _onInstallSigner(id, _data);
    }

    function onUninstall(bytes calldata data) external payable {
        bytes32 id = bytes32(data[0:32]);
        bytes calldata _data = data[32:];
        _onUninstallSigner(id, _data);
    }

}
