// SPDX-License-Identifier: GNU AGPLv3

pragma solidity 0.8.30;

import { Ownable } from "@openzeppelin/access/Ownable.sol";
import { Pausable } from "@openzeppelin/utils/Pausable.sol";
import { IMultistrategyAdminable } from "../interfaces/IMultistrategyAdminable.sol";
import { Errors } from "../libraries/Errors.sol";

abstract contract MultistrategyAdminable is IMultistrategyAdminable, Ownable, Pausable {
    /*//////////////////////////////////////////////////////////////////////////
                                       STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IMultistrategyAdminable
    address public manager;

    /// @inheritdoc IMultistrategyAdminable
    mapping(address guardianAddress => bool isActive) public guardians;

    /// @notice Sets the Owner and Manager addresses.
    /// @param _owner The address of the initial owner.
    /// @param _manager The address of the initial manager.
    constructor(address _owner, address _manager) Ownable(_owner) {
        manager = _manager;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Reverts if called by any account other than the owner or the manager.
    modifier onlyManager() {
        _onlyManager();
        _;
    }

    /// @notice Reverts if called by any account other than the owner or a guardian.
    modifier onlyGuardian() {
        _onlyGuardian();
        _;
    }

    /// @notice Internal function to check if caller is owner or manager.
    function _onlyManager() internal view {
        require(msg.sender == owner() || msg.sender == manager, Errors.Unauthorized(msg.sender));
    }

    /// @notice Internal function to check if caller is owner or guardian.
    function _onlyGuardian() internal view {
        require(msg.sender == owner() || guardians[msg.sender], Errors.Unauthorized(msg.sender));
    }

    /*//////////////////////////////////////////////////////////////////////////
                               USER-FACING NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IMultistrategyAdminable
    function setManager(address _manager) external onlyOwner {
        require(_manager != address(0), Errors.ZeroAddress());

        manager = _manager;
        emit ManagerSet(_manager);
    }

    /// @inheritdoc IMultistrategyAdminable
    function enableGuardian(address _guardian) external onlyOwner {
        guardians[_guardian] = true;
        emit GuardianEnabled(_guardian);
    }

    /// @inheritdoc IMultistrategyAdminable
    function revokeGuardian(address _guardian) external onlyOwner {
        guardians[_guardian] = false;
        emit GuardianRevoked(_guardian);
    }

    /// @inheritdoc IMultistrategyAdminable
    function pause() external onlyGuardian {
        _pause();
    }

    /// @inheritdoc IMultistrategyAdminable
    function unpause() external onlyOwner {
        _unpause();
    }
}