pragma solidity 0.8.0;
pragma experimental "ABIEncoderV2";

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { VRFConsumerBase } from "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
//no SafeMath since solidity 0.8.0 includes checked artihmetic operations by default

contract BasketToken is ERC20, VRFConsumerBase {
    using Address for address;
    
    //events
    
    event BasketCreated(address _contract);
    event LotteryCalled(address _caller, address _winner);
    
    //state storage
    
    bytes32 internal keyHash;
    uint256 internal fee;
    uint8 public potFee = 5;
    address[] private lottoArray;
    address[] public components;
    uint256[] public units;
    
    int256 public positionMultiplier;
    uint public randomResult;
    mapping(address => uint256) lottoPot;
    

    constructor(
        address[] memory _components,
        uint256[] memory _units,
        string memory _name,
        string memory _symbol
        ) ERC20(_name, _symbol) VRFConsumerBase(0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, 0x514910771AF9Ca656af840dff83E8264EcF986CA) {
            components = _components;
            units = _units;
            keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
            fee = 2 * 10 ** 18;
            emit BasketCreated(address(this));
        }
  
    function redeem(uint256 amount) external {
        require(IERC20(address(this)).balanceOf(msg.sender) >= amount, 'cannot redeem more than you own');
        //burn
        _burn(msg.sender, amount);
        removeFromLotto(msg.sender, amount);
        //transfer the underlying components
        for (uint i = 0; i < components.length; i++) {
            //amount with no potfee
            //multiply underlyingAmount by 100
            //multiply underlyingAmount by 5
            //subtract subValue from amountPrecise and divide by 100 to return 95% of holdings upon redemption
            
            
            uint underlyingAmount = units[i] * amount;
            uint amountPrecise = underlyingAmount * 100;
            uint subValue = underlyingAmount * potFee;
            uint amountMinusFee = (amountPrecise - subValue) / 100;
            uint rFee = underlyingAmount - amountMinusFee;
            lottoPot[components[i]] += rFee;
            IERC20(components[i]).transfer(msg.sender, amountMinusFee);
        }
        
    }
    
    function mint(uint256 amount) external {
        for (uint i = 0; i < components.length; i++) {
            require(IERC20(components[i]).balanceOf(msg.sender) >= units[i] * amount, "not enough components to mint");
        }
        for (uint i = 0; i < components.length; i++) {
            // for simplicity, baskets have a set compenent distribution, ie no rebalancing, and compenents are held by the basket token address
            uint256 underlyingAmount = units[i] * amount;
            IERC20(components[i]).transferFrom(msg.sender, address(this), underlyingAmount);
        }
        // for each basket unit a user holds their address is added to the lottoArray. 
        
        updateLotto(msg.sender, amount);
        _mint(msg.sender, amount);
        
    }
    //adds user address to lottoArray for each basket token minted.
    function updateLotto(address _user, uint amount) internal {
        for (uint i = 0; i < amount; i++) {
            lottoArray.push(_user);
        }
    }
    // GAS INTENSIVE. upon redemption, users addresses are removed from the lottoArray to accurately reflect their odds of winning.
    //the lottery is done this way because it is impossible to iterate over the mapping of user balances so a different method needs to be employed
    function removeFromLotto(address _toBeRemoved, uint _count) internal {
        
        for (uint i = 0; i < lottoArray.length; i++) {
            if (lottoArray[i] == _toBeRemoved) {
                remove(i);
                _count --;
            }
            if (_count == 0) {
                break;
            }
        }
    }
    //helper function to remove addresses from lottoArray while maintaining order
    function remove(uint index)  internal {
        require(index < lottoArray.length);

        for (uint i = index; i < lottoArray.length - 1; i++){
            lottoArray[i] = lottoArray[i + 1];
        }
        lottoArray.pop();
    }
        
    // Lottery function that makes a request to LINK VRF. requires 2 Link to call. 
    function ImFeelingLucky() public {
        require(LINK.balanceOf(address(this)) > fee, 'must fund contract with 2 link to call lottery');
        getRandomNumber();
        uint[] memory res = expand(randomResult, 1);
        
        uint d10number = (res[0] % 10) + 1;
        if (d10number < 4) {
            uint maxIndex = lottoArray.length;
            uint indexWinner = res[1] % maxIndex;
            for (uint i = 0; i < components.length; i++) {
                IERC20 tok = IERC20(components[i]);
                uint amt = lottoPot[components[i]];
                tok.transfer(lottoArray[indexWinner], amt);
                lottoPot[components[i]] = 0;
                
            }
            emit LotteryCalled(msg.sender, lottoArray[indexWinner]);
        }
        
        
    }
    
   // helper function to turn VRF response into 2 random numbers. 
    function expand(uint randomNumber, uint n) internal pure returns (uint[] memory) {
        uint[] memory expandedValues;
        for (uint i = 0; i < n; i++) {
            expandedValues[i] = uint256(keccak256(abi.encode(randomNumber, i)));
        }
        return expandedValues;
        
    }
    
     //link random number function
    function getRandomNumber() internal returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        
        randomResult = randomness;
    }

    
}
