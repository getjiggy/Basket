
pragma solidity 0.8.0;
pragma experimental "ABIEncoderV2";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IBasketToken is IERC20 {
  function redeem(uint256 amount) external;
  function mint(uint256 amount) external; 
  function ImFeelingLucky() external;

  event BasketCreated(address _contract);
  event LotteryCalled(address _caller, address _winner);
    
}
