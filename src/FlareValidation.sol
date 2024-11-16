// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// import "./interfaces/IDatasetInfoApi.sol";
import "./generated/interfaces/verification/IDatasetInfoApiVerification.sol";
import "./generated/implementation/verification/DatasetInfoApiVerification.sol";

import {TestFtsoV2Interface} from "@flarenetwork/flare-periphery-contracts/coston2/TestFtsoV2Interface.sol";
import {ContractRegistry} from "@flarenetwork/flare-periphery-contracts/coston2/ContractRegistry.sol";

import "./interfaces/IAttestation.sol";

contract FlareValidation {
    // Individual contribution of one user to the dataset
    struct DataContribution {
        bytes32 id;
        address contributor;
        bytes32 datasetId;
        bytes32 dataHash;
        uint256 contributionAmount;
        uint256 variance;
    }

    // Dataset information (joint contributions of all users)
    struct DatasetInfo {
        bytes32 id;
        bytes32 dataHash;
        DataContribution[] dataContributions;
    }

    struct TeeHashInfo {
        bytes32 id;
        bytes32 dataHash;
        bool success;
    }

    error AttestationAllreadyProcessed();

    IDatasetInfoApiVerification internal dbApiAttestationVerification;
    TestFtsoV2Interface internal ftsoV2;
    IAttestation internal teeAttestation;

    mapping(bytes32 => bool) public processedAttestations;

    // The hashes of data contributions that have been verified in the TEE during Proof-of-Learning
    mapping(bytes32 => bool) public verifiedContributions; // dataHash => Success

    mapping(address => uint256) public pendingPayouts; // contributor => payout(scaled by 1e8)

    bytes21 public flrUsdId = 0x01464c522f55534400000000000000000000000000;

    constructor() {
        dbApiAttestationVerification = new DatasetInfoApiVerification();
        ftsoV2 = ContractRegistry.getTestFtsoV2();
        teeAttestation = IAttestation(address(0x0));
    }

    function verifyTeeLearning(bytes calldata teeQuote, TeeHashInfo memory teeHashInfo) external {
        // Verify the attestation
        // Todo: teeAttestation.verifyAndAttestOnChain(teeQuote);

        // Todo: Hash the teeHashInfo and compare to the teeQuote hash

        // Store the verified contribution (if valid)
        verifiedContributions[teeHashInfo.dataHash] = teeHashInfo.success;
    }

    function addDatabaseInfo(IDatasetInfoApi.Response calldata dbInfoResponse) external {
        // We mock the proof for testing and hackathon
        IDatasetInfoApi.Proof memory proof =
            IDatasetInfoApi.Proof({merkleProof: new bytes32[](0), data: dbInfoResponse});
        require(dbApiAttestationVerification.verifyDatasetInfoApi(proof), "Invalid proof");

        DatasetInfo memory _dbInfo = abi.decode(dbInfoResponse.responseBody.abi_encoded_data, (DatasetInfo));

        if (processedAttestations[_dbInfo.id]) {
            revert AttestationAllreadyProcessed();
        }

        require(verifiedContributions[_dbInfo.dataHash], "Contribution hasn't been verified by the TEE");

        for (uint256 i = 0; i < _dbInfo.dataContributions.length; i++) {
            DataContribution memory dataContribution = _dbInfo.dataContributions[i];

            // require(dataContribution.datasetId == _dbInfo.id, "Invalid dataset ID");
            pendingPayouts[dataContribution.contributor] +=
                dataContribution.contributionAmount * dataContribution.variance;
        }

        processedAttestations[_dbInfo.id] = true;
    }

    function getFlrUsdPrice() public view returns (uint256, int8, uint64) {
        (uint256 feedValue, int8 decimals, uint64 timestamp) = ftsoV2.getFeedById(flrUsdId);

        return (feedValue, decimals, timestamp);
    }

    function payout(address payable contributor) external {
        require(contributor != address(0), "invalid address");

        uint256 payoutAmount = pendingPayouts[contributor];
        if (payoutAmount > 0) {
            pendingPayouts[contributor] = 0;

            // Get the current FLR price
            (uint256 flrUsdPrice, int8 decimals, uint64 timestamp) = getFlrUsdPrice();

            // Calculate the amount of FLR to send
            uint256 flrAmount = (payoutAmount * 1e8 * 10 ** uint8(decimals)) / flrUsdPrice;

            // Send FLR
            (bool success,) = contributor.call{value: flrAmount}("");

            // Check if the transfer was successful
            require(success, "Transfer failed");
        }
    }

    // For receiving plain ETH transfers
    receive() external payable {}

    // For receiving ETH with data
    fallback() external payable {}
}
