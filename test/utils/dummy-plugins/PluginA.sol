// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;

import {TrustedForwarder} from "../../../src/utils/TrustedForwarder.sol";

import {IDAO} from "@aragon/osx-commons-contracts-new/src/dao/IDAO.sol";
import {
    IProposal
} from "@aragon/osx-commons-contracts-new/src/plugin/extensions/proposal/IProposal.sol";

contract PluginA is IProposal {
    bool public created;
    uint256 public proposalId;
    TrustedForwarder public trustedForwarder;
    mapping(uint256 => IDAO.Action) public actions;

    constructor(address _trustedForwarder) {
        trustedForwarder = TrustedForwarder(_trustedForwarder);
    }

    event ProposalCreated(uint256 proposalId, uint64 startDate, uint64 endDate);

    function createProposal(
        bytes calldata,
        IDAO.Action[] calldata _actions,
        uint64 startDate,
        uint64 endDate
    ) external override returns (uint256 _proposalId) {
        _proposalId = proposalId;
        proposalId = proposalId + 1;
        actions[_proposalId] = _actions[0];
        created = true;

        emit ProposalCreated(_proposalId, startDate, endDate);
        return _proposalId;
    }

    function execute(
        uint256 _proposalId
    ) external returns (bytes[] memory execResults, uint256 failureMap) {
        IDAO.Action[] memory mainActions = new IDAO.Action[](1);
        mainActions[0] = actions[_proposalId];
        (execResults, failureMap) = trustedForwarder.execute(bytes32(_proposalId), mainActions, 0);
    }

    function proposalCount() external view override returns (uint256) {
        return proposalId;
    }
}
