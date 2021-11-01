
// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
import "@chimera-defi/twamm/contracts/TWAMM.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FrankiesTWAMMFactory {
  event FrankiesTWAMMCreated(
    address indexed addr
  );

  constructor() {}

  function createFrankiesTWAMM(
    string memory _name, string memory _symbol, address _tokenA, address _tokenB, uint256 _orderBlockInterval
  ) external returns (address res) {
    res = address(new TWAMM(_name, _symbol, _tokenA, _tokenB, _orderBlockInterval));
    Ownable(res).transferOwnership(msg.sender);
    emit FrankiesTWAMMCreated(res);
    return res;
  }
}
