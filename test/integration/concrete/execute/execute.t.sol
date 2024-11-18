// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {BaseTest} from "../../../BaseTest.t.sol";
import {Errors} from "../../../../src/libraries/Errors.sol";
import {PluginA} from "../../../utils/dummy-plugins/PluginA/PluginA.sol";
import {EXECUTE_PROPOSAL_PERMISSION_ID} from "../../../utils/Permissions.sol";
import {StagedProposalProcessor as SPP} from "../../../../src/StagedProposalProcessor.sol";

import {DAO} from "@aragon/osx/core/dao/DAO.sol";
import {Action} from "@aragon/osx-commons-contracts/src/executors/IExecutor.sol";
import {DaoUnauthorized} from "@aragon/osx-commons-contracts/src/permission/auth/auth.sol";

contract Execute_SPP_IntegrationTest is BaseTest {
    uint256 proposalId;

    modifier whenProposalExists() {
        proposalId = _configureStagesAndCreateDummyProposal(DUMMY_METADATA);

        _;
    }

    modifier whenCallerIsAllowed() {
        resetPrank(users.manager);
        _;
    }

    function test_WhenProposalCanExecute() external whenProposalExists whenCallerIsAllowed {
        // it should emit event.
        // it should execute proposal.

        _moveToLastStage();

        // check event emitted
        vm.expectEmit({emitter: address(sppPlugin)});
        emit ProposalExecuted(proposalId);

        sppPlugin.execute(proposalId);

        // check proposal executed
        assertTrue(sppPlugin.getProposal(proposalId).executed, "executed");

        // check actions executed
        assertEq(target.val(), TARGET_VALUE, "targetValue");
        assertEq(target.ctrAddress(), TARGET_ADDRESS, "ctrAddress");
    }

    function test_RevertWhen_ProposalCanNotExecute()
        external
        whenProposalExists
        whenCallerIsAllowed
    {
        // it should revert.

        vm.expectRevert(
            abi.encodeWithSelector(Errors.ProposalExecutionForbidden.selector, proposalId)
        );
        sppPlugin.execute(proposalId);
    }

    function test_RevertWhen_CallerIsNotAllowed() external whenProposalExists {
        // it should revert.
        resetPrank(users.unauthorized);

        vm.expectRevert(
            abi.encodeWithSelector(
                DaoUnauthorized.selector,
                address(dao),
                address(sppPlugin),
                users.unauthorized,
                EXECUTE_PROPOSAL_PERMISSION_ID
            )
        );

        sppPlugin.execute(proposalId);
    }

    function test_RevertWhen_ProposalDoesNotExist() external {
        // it should revert.

        vm.expectRevert(abi.encodeWithSelector(Errors.NonexistentProposal.selector, proposalId));
        sppPlugin.execute(proposalId);
    }

    function _moveToLastStage() internal {
        uint256 initialStage;

        // move proposal to last stage to be executable
        // execute proposals on first stage
        _executeStageProposals(initialStage);

        // advance to last stage
        vm.warp(VOTE_DURATION + START_DATE);
        sppPlugin.advanceProposal(proposalId);

        // execute proposals on first stage
        _executeStageProposals(initialStage + 1);

        // advance last stage
        vm.warp(sppPlugin.getProposal(proposalId).lastStageTransition + VOTE_DURATION + START_DATE);
    }
}
