// SPDX-License-Identifier: GNU AGPLv3

pragma solidity 0.8.30;

import { Ownable } from "@openzeppelin/access/Ownable.sol";
import { Pausable } from "@openzeppelin/utils/Pausable.sol";
import { IAdapterAdminable } from "../interfaces/IAdapterAdminable.sol";
import { Errors } from "../libraries/Errors.sol";

abstract contract AdapterAdminable is IAdapterAdminable, Ownable, Pausable {
    /*//////////////////////////////////////////////////////////////////////////
                                       STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IAdapterAdminable
    mapping(address guardianAddress => bool isActive) public guardians;

    /// @param _owner The address that will be set as owner.
    constructor(address _owner) Ownable(_owner) {}

    /*//////////////////////////////////////////////////////////////////////////
                                    MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Reverts if called by any account other than the owner, or a guardian.
    modifier onlyGuardian() {
        _onlyGuardian();
        _;
    }

    /// @notice Internal function to check if caller is owner or guardian.
    function _onlyGuardian() internal view {
        require(msg.sender == owner() || guardians[msg.sender], Errors.Unauthorized(msg.sender));
    }

    /*//////////////////////////////////////////////////////////////////////////
                               USER-FACING NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IAdapterAdminable
    function enableGuardian(address _guardian) external onlyOwner {
        guardians[_guardian] = true;
        emit GuardianEnabled(_guardian);
    }

    /// @inheritdoc IAdapterAdminable
    function revokeGuardian(address _guardian) external onlyOwner {
        guardians[_guardian] = false;
        emit GuardianRevoked(_guardian);
    }
}