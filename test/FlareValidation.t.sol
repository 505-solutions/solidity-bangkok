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
                id: hex"00000000000000000000000000000000000000000000000000006730d6800022",
                dataHash: hex"00000000000000000000000000000000000000000000000000980d1615541c18",
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
                abi_encoded_data: hex"000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000006730d680002200000000000000000000000000000000000000000000000000980d1615541c1800000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000004c5c8c208252dc0000000000000000000000008a448f9d67f70a3a9c78a3ef0ba204b3c43521a900000000000000000000000000000000000000000000000000006730d6800022000000000000000000000000000000000000000000000000006c559ab1f6a138000000000000000000000000000000000000000000000000000000000000000300000000000000000000000000000000000000000000000000000000002340d4000000000000000000000000000000000000000000000000004c5c8c208252dc0000000000000000000000008a448f9d67f70a3a9c78a3ef0ba204b3c43521a900000000000000000000000000000000000000000000000000006730d6800022000000000000000000000000000000000000000000000000006c559ab1f6a13800000000000000000000000000000000000000000000000000000000000000030000000000000000000000000000000000000000000000000000000000268573000000000000000000000000000000000000000000000000004c5c8c208252dc0000000000000000000000008a448f9d67f70a3a9c78a3ef0ba204b3c43521a900000000000000000000000000000000000000000000000000006730d6800022000000000000000000000000000000000000000000000000006c559ab1f6a1380000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000025aaac"
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

    function test_payout() public {
        test_AddDatabaseInfo();

        // fund the contract
        vm.deal(address(validationContract), 1 ether);

        uint256 pendingPayout = validationContract.pendingPayouts(address(0x8A448f9d67F70a3a9C78A3ef0BA204B3c43521a9));
        console.log("pendingPayout", pendingPayout);

        address payable contributor = payable(address(0x8A448f9d67F70a3a9C78A3ef0BA204B3c43521a9));
        validationContract.payout(contributor);

        uint256 pendingPayout2 = validationContract.pendingPayouts(address(0x8A448f9d67F70a3a9C78A3ef0BA204B3c43521a9));
        console.log("pendingPayout2", pendingPayout2);
    }
}
