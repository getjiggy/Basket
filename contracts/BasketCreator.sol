pragma solidity 0.8.0;
pragma experimental "ABIEncoderV2";

// simple contract for creating Baskets. can be called by anyone

import { BasketToken } from "./BasketToken.sol";
import { IBasketToken } from './interfaces/IBasketToken.sol';
import { AddressArrayUtils } from './lib/AddressArrayUtils.sol';


contract BasketCreator {
    using AddressArrayUtils for address[];
    
    event basketCreated(address indexed basketToken, string name, string symbol);
    
    // state variables
    
    constructor() public {
        
    }
    function create(
        address[] memory _components,
        uint256[] memory _units,
        string memory _name,
        string memory _symbol
    )
        external
        returns (address)
    {
        require(_components.length > 0, "Must have at least 1 component");
        require(_components.length == _units.length, "Component and unit lengths must be the same");
        require(!_components.hasDuplicate(), "Components must not have a duplicate");
        

        for (uint256 i = 0; i < _components.length; i++) {
            require(_components[i] != address(0), "Component must not be null address");
            require(_units[i] > 0, "Units must be greater than 0");
        }

        
        BasketToken basketToken = new BasketToken(
            _components,
            _units,
            _name,
            _symbol
            );
        
        
        emit basketCreated(address(basketToken), _name, _symbol);
        return address(basketToken);
    }
        
}
