// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

import {FlareValidation} from "src/FlareValidation.sol";

import "src/generated/interfaces/verification/IDatasetInfoApiVerification.sol";
import "src/generated/implementation/verification/DatasetInfoApiVerification.sol";

contract FlareValidationTest is Test {
    FlareValidation public validationContract;

    function setUp() public {
        validationContract = new FlareValidation();
    }

    function test_AddDatabaseInfo() public {
        // ! Verify the TEE quote
        validationContract.verifyTeeLearning(
            hex"00",
            FlareValidation.TeeHashInfo({
                id: hex"0000000000000000000000000000000000000000000000000004640896c055de",
                dataHash: hex"00000000000000000000000000000000000000000000000000052a6dcb8f223f",
                success: true
            })
        );

        IDatasetInfoApi.Response memory _response = IDatasetInfoApi.Response({
            attestationType: hex"44617461736574496e666f417069000000000000000000000000000000000000",
            sourceId: hex"5745423200000000000000000000000000000000000000000000000000000000",
            votingRound: 0,
            lowestUsedTimestamp: 1000000000000000,
            requestBody: IDatasetInfoApi.RequestBody({
                url: "https://api.freeapi.app/api/v1/public/randomusers/user/random",
                abi_signature: ""
            }),
            responseBody: IDatasetInfoApi.ResponseBody({
                abi_encoded_data: hex"00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000004640896c055de00000000000000000000000000000000000000000000000000052a6dcb8f223f00000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000f3f41fb5fa4d30000000000000000000000008a448f9d67f70a3a9c78a3ef0ba204b3c43521a90000000000000000000000000000000000000000000000000004640896c055de0000000000000000000000000000000000000000000000000003e41f82385ead00000000000000000000000000000000000000000000000000000000000000030000000000000000000000000000000000000000000000000000000000203eac0000000000000000000000000000000000000000000000000005e7e14d0610b30000000000000000000000008a448f9d67f70a3a9c78a3ef0ba204b3c43521a90000000000000000000000000000000000000000000000000004640896c055de0000000000000000000000000000000000000000000000000004301392f3f48e0000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000021f7ea0000000000000000000000000000000000000000000000000002c7f23b2718d40000000000000000000000008a448f9d67f70a3a9c78a3ef0ba204b3c43521a90000000000000000000000000000000000000000000000000004640896c055de00000000000000000000000000000000000000000000000000039e202d9f47e80000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000025a121"
            })
        });

        validationContract.addDatabaseInfo(_response);

        console.log("test passed");

        bool verified = validationContract.processedAttestations(hex"0c68");
        uint256 pendingPayout = validationContract.pendingPayouts(address(0x8A448f9d67F70a3a9C78A3ef0BA204B3c43521a9));

        console.log("verified", verified);
        console.log("pendingPayout", pendingPayout);

        (uint256 flrUsdPrice, int8 decimals, uint64 timestamp) = validationContract.getFlrUsdPrice();

        console.log("price", flrUsdPrice);
        console.log("decimals", decimals);
    }

    // function testFuzz_SetNumber(uint256 x) public {
    //     counter.setNumber(x);
    //     assertEq(counter.number(), x);
    // }
}
