// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "contracts/SmartSession.sol";

import "test/mock/SimpleSigner.sol";
import "test/mock/UniActionPolicy.sol";
import "test/mock/UsageLimitPolicy.sol";
import "test/mock/TimeFramePolicy.sol";
import "test/mock/SimpleGasPolicy.sol";
import "test/mock/ValueLimitPolicy.sol";
import "contracts/erc7679/UserOpBuilder.sol";
import "test/mock/YesPolicy.sol";

contract DeploySmartSession is Script {
    uint256 privKey;

    function run() public {
        privKey = vm.envUint("PRIVATE_KEY");
        console2.log("Deployer Addr: ", vm.addr(privKey));

        vm.startBroadcast(privKey);

        _deploySmartSession();
        _deployUOBuilder();
        _deploySubModules();
        _deployWcCosigner();

        vm.stopBroadcast();
    }

    function _deploySmartSession() public returns (address) {
        SmartSession smartSession = new SmartSession();
        console2.log("SmartSession Addr: ", address(smartSession));

        return address(smartSession);
    }

    function _deployUOBuilder() public returns (address) {
        UserOperationBuilder uoBuilder = new UserOperationBuilder(0x0000000071727De22E5E9d8BAf0edAc6f37da032);
        console2.log("UserOperationBuilder Addr: ", address(uoBuilder));

        return address(uoBuilder);
    }

    function _deployWcCosigner() public returns (address) {
        bytes memory bytecode = abi.encodePacked(vm.getCode("./out/WCSigner.sol/WCSigner.json"));

        address anotherAddress;
        address cosigner;
        assembly {
            anotherAddress := create(0, add(bytecode, 0x20), mload(bytecode))
        }
        cosigner = anotherAddress;
        console2.log("WalletConnect CoSigner Addr: ", cosigner);
        vm.label(cosigner, "WalletConnect CoSigner");

        return anotherAddress;
    }

    function _deploySubModules() public returns (address) {
        SimpleSigner ssigner = new SimpleSigner();
        console2.log("Simple Signer Address ", address(ssigner));

        UniActionPolicy uniActionPolicy = new UniActionPolicy();
        console2.log("UniActionPolicy Address ", address(uniActionPolicy));

        TimeFramePolicy tfPolicy = new TimeFramePolicy();
        console2.log("TimeFramePolicy Address ", address(tfPolicy));

        UsageLimitPolicy usageLimitPolicy = new UsageLimitPolicy();
        console.log("UsageLimitPolicy Address ", address(usageLimitPolicy));

        ValueLimitPolicy valueLimitPolicy = new ValueLimitPolicy();
        console.log("ValueLimitPolicy Address ", address(valueLimitPolicy));
    }
}