// SPDX-License-Identifier: GPL-2.0-or-later
// Reference https://github.com/para-dave/twamm/blob/master

// example AMMS
//  uni style - quickswap: https://polygonscan.com/tx/0x52627b85b816ae66bb772d8d3e35f50a331bdb09ecae10eabe5f5581200e4542
/**
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
 */
// balancer: https://polygonscan.com/tx/0x51b9e1478fa3c2d5b5fb3c7b27c5d99c655c003e6a9f147fa04eaed02590f312
/**
    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) returns (uint256 amountCalculated)
 */
pragma solidity =0.7.6;
pragma abicoder v2;

contract TWAMM {
  uint256 public lastBlockSeen;
  struct Order {
    uint256 amt;
    address token;
    address owner;

  }

  struct LongTermOrder {
    uint256 qty_in;
    uint256 qty_spent;
    uint256 blocks_lifespan;
    uint256 qty_in_per_block;
    uint256 blocks_left;
    uint256 qty_filled;
    address tokenIn;
    address tokenOut;
    address owner;
    uint256 orderId;
  }

  mapping(uint256 => Order) public override orders;
  mapping(uint256 => LongTermOrder) public override longTermOrders;

  // mapping of tokens to orders 
  mapping(address => mapping(uint256 => LongTermOrder)) public longTermOrdersForTokens;
  mapping(address => uint256) public ordersForToken;
  uint256 public numOrders;
  uint256 public numOrdersRemaining;

  constructor() {

  }

  function process_fills() {

  }

  function virtual_swap() {
    // Process all valid ltos using _process_virtual_order
    // set lastBlockSeen to this one
    // do the tx for the user
    // NOTE: Should we prefer orders in the opposite direction to the user? 
  }

  function _swap_via_underlying_amms(address tokenIn, address tokenOut, uint256 amt) internal returns (uint256 tokensRecvd) {
    // todo
  }

  function _calculate_total_order(address tokenIn, address tokenOut) internal {
    // Collate all orders using the two tokens
    // Get a cumulative diff
    // Get a direction
    // e..g user A wants 23X -> Y
    /**
    Alice -> 23 ETH -> DAI
    Bob -> 23 DAI -> ETH
    We don;t need to do both, we just need to calculate the result of 23 ETH to DAI, and deduct that from Bob and ALice

     */


     // Get set of orders in
     // Get set of orders oit
     // Calc diff, and direction of trade
     // Make a swap in that direction with total amt
     // Update state for all LTOs
     // finalize any finished LTOs, deleting them, and sending tokens

    EnumerableSet.LTOSet ltoSetIn = values(longTermOrdersForTokens[tokenIn]);
    EnumerableSet.LTOSet ltoSetOut = values(longTermOrdersForTokens[tokenOut]);

    (inTotal, inAmts) = _sum_set(ltoSetIn);
    (outTotal, outAmts) = _sum_set(ltoSetOut);

    (res, tokenOut) = swap(inTotal, outTotal, inTokens, outTokens);
    _process_virtual_orders(inAmts, ltoSetIn, res);





    //  bytes32[] memory enumSet = EnumerableSet.values()

    //  for (uint256 i=0; )
  }

  function swap(uint256 inTotal, uint256 outTotal, address inToken, address outToken) returns (uint256, address) {
    (tokenIn, tokenOut) = _getTradeDirection(inTotal, outTotal, inToken, outToken);
    uint256 res = _swap_via_underlying_amms(tokenIn, tokenOut, amountToTrade);
    return (res, tokenOut);
  }

  function _getTradeDirection(uint256 inTotal, uint256 outTotal, address inToken, address outToken) {
    // return direction of trade, towards in or out? 
    // i.e. x-> y or y -> x
  }

  function _sum_set(EnumerableSet ltoSet) internal returns (uint256 total, uint256[] amounts){
    uint256 total;
    // Do we need to keep track of the amounts to divvy up rewards?
    uint256[] amounts;
    for (uint256 i; i<ltoSet.length; i++) {
      amounts[i] = _get_inputs_from_lto(ltoSet.at(i));
      total += amounts[i];
    }
    return (total, amounts);
  }

  function _sum_arr(uint256[] amounts) returns (uint256) {
    uint256 res;
    for (uint256 i; i<amounts.length; i++) {
      res += amounts[i];
    }
    return res;
  }

  function _process_virtual_orders(uint256[] amounts, EnumerableSet ltoSet, uint256 tokensRecvd) {
    uint256 totalAmts = _sum_arr(amounts);
    uint256 outPerIn = tokensRecvd / totalAmts; // check for overflow issues and 1e18 bs
    for (uint256 i; i<amounts.length; i++) {
      uint256 (amt, blocks) = _get_inputs_from_lto(ltoSet.at(i));

      _updateAfterFill(
        ltoSet.at(i),
        outPerIn * amt,
        blocks
      )
      // give tokens to each user / fill their order that much

    }
  }

  function _get_inputs_from_lto(LongTermOrder lto) internal return (uint256 amountToTrade) {
    // given an lto, calc total diff and queue a swap?
    uint256 blocknum = block.number;
    uint256 blocksElapsed = blocknum - lastBlockSeen;
    // should we store the result tokens recv'd? for gas saving? or just send to users?
    uint256 blocksToTrade = 0;
    if (lto.blocks_left < blocksElapsed) {
      blocksToTrade = lto.blocks_left;
    } else {
      blocksToTrade = blocksElapsed;
    }
    uint256 amountToTrade = blocksToTrade * lto.qty_in_per_block;
    return (amountToTrade, blocksToTrade);
  }


  function _process_virtual_order(LongTermOrder lto) internal {
    // given an lto, calc total diff and queue a swap?
    uint256 blocknum = block.number;
    uint256 blocksElapsed = blocknum - lastBlockSeen;
    // should we store the result tokens recv'd? for gas saving? or just send to users?
    uint256 blocksToTrade = 0;
    if (lto.blocks_left < blocksElapsed) {
      blocksToTrade = lto.blocks_left;
    } else {
      blocksToTrade = blocksElapsed;
    }
    uint256 amountToTrade = blocksToTrade * lto.qty_in_per_block;
    uint256 res = _swap_via_underlying_amms(lto.tokenIn, lto.tokenOut, amountToTrade);
    _updateAfterFill(lto, res, blocksToTrade);
  }

  function _placeOrder(uint256 qty_in, uint256 blocks_lifespan, address tokenIn, address tokenOut) internal {

    uint256 qty_in_per_block = qty_in/blocks_lifespan;
    LongTermOrder lto = LongTermOrder({
      qty_in: qty_in,
      qty_spent: 0,
      blocks_lifespan: blocks_lifespan,
      qty_in_per_block: qty_in_per_block,
      blocks_left: blocks_lifespan,
      qty_filled: 0,
      tokenIn: tokenIn,
      tokenOut: tokenOut,
      owner: msg.sender,
      orderId: 0,
    });
    _getTokens(lto);
  
    numOrders+=1;
    numOrdersRemaining+=1;
    lto.orderId = numOrders;
    longTermOrders[numOrders] = lto;

    ordersForToken[tokenIn] += 1;
    longTermOrdersForTokens[tokenIn][lto.orderId] = lto;
  }

// https://github.com/chimera-defi/twamm/blob/master/long_term_order.py
  function _updateAfterFill(LongTermOrder lto, uint256 qty_filled, uint256 blocks) internal {
    require(lto.blocks_left > 0);
    require(lto.blocks_left - blocks >= 0);

    lto.qty_filled += qty_filled;
    lto.blocks_left -= blocks;
    lto.qty_spent += blocks * qty_in_per_block;
    if (lto.blocks_left > 0) return;
    _finalizeOrder(lto);
  }

  function _getTokens(LongTermOrder lto) internal {
    IERC20(lto.tokenIn).safeTransferFrom(lto.owner, address(this), lto.qty_in);
  }

  function _sendTokens(LongTermOrder lto) internal {
    IERC20(lto.tokenOut).safeTransferFrom(address(this), lto.owner, lto.qty_filled);
  }

  // triggered if an order is filled to send tokens and delete data
  // Can also be used to cancel order? 

  function _finalizeOrder(LongTermOrder lto) internal {
    if (lto.blocks_left > 0) return;

    delete longTermOrders[lto.order_id];
    ordersForToken[lto.tokenIn] -= 1;
    delete longTermOrdersForTokens[tokenIn][lto.orderId];
    numOrdersRemaining -= 1;
    _sendTokens(lto);
  }
}