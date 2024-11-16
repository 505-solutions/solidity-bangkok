// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";

import {FlareValidation} from "../src/FlareValidation.sol";

contract DeployFlareValidationScript is Script {
    function run() external returns (FlareValidation) {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerKey);
        FlareValidation validationContract = new FlareValidation();

        vm.stopBroadcast();

        return (validationContract);
    }
}
