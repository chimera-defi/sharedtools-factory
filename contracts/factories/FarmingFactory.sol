// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;
import "../MasterChef.sol";
import "../FundDistributor.sol";
import "../interfaces/IFundDistributor.sol";
import "../interfaces/ITokenUtilityModule.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract FarmingFactory {
    event FundDistributorCreated(address indexed addr, address indexed reward);
    event MasterChefCreated(address indexed mcAddr, address _reward, address fdAddr);

    constructor() {}

    function createFarming(address _reward) public returns (address mc, address fd) {
        fd = createFundDistributor(_reward);
        mc = createMasterChef(_reward, fd);
        IFundDistributor(fd).addRequester(mc);
        Ownable(fd).transferOwnership(msg.sender);
        Ownable(mc).transferOwnership(msg.sender);
    }

    function createFundDistributor(address _reward) public returns (address fd) {
        fd = address(new FundDistributor(_reward));
        emit FundDistributorCreated(fd, _reward);
        return fd;
    }

    function createMasterChef(address _reward, address _fundDistributor) public returns (address mc) {
        mc = address(
            new MasterChef(IERC20(_reward), IFundDistributor(_fundDistributor), ITokenUtilityModule(address(0)))
        );
        emit MasterChefCreated(mc, _reward, _fundDistributor);
        return mc;
    }
}
