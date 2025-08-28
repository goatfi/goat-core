// SPDX-License-Identifier: GNU AGPLv3

pragma solidity 0.8.30;

import { Ownable } from "@openzeppelin/access/Ownable.sol";
import { Pausable } from "@openzeppelin/utils/Pausable.sol";
import { IStrategyAdapterAdminable } from "interfaces/IStrategyAdapterAdminable.sol";
import { Errors } from "../libraries/Errors.sol";

abstract contract StrategyAdapterAdminable is IStrategyAdapterAdminable, Ownable, Pausable {
    /*//////////////////////////////////////////////////////////////////////////
                                       STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IStrategyAdapterAdminable
    mapping(address guardianAddress => bool isActive) public guardians;

    constructor(address _owner) Ownable(_owner) {}

    /*//////////////////////////////////////////////////////////////////////////
                                    MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Reverts if called by any account other than the owner, the manager, or a guardian.
    modifier onlyGuardian() {
        require(msg.sender == owner() || guardians[msg.sender], Errors.CallerNotGuardian(msg.sender));
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                               USER-FACING NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IStrategyAdapterAdminable
    function enableGuardian(address _guardian) external onlyOwner {
        guardians[_guardian] = true;
        emit GuardianEnabled(_guardian);
    }

    /// @inheritdoc IStrategyAdapterAdminable
    function revokeGuardian(address _guardian) external onlyOwner {
        guardians[_guardian] = false;
        emit GuardianRevoked(_guardian);
    }
}