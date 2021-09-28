// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IFundDistributor {
    function distributeTo(address _receiver, uint256 _amount) external;
    function addRequester(address _requester) external;
    function initialize(address _reward) external;
}
