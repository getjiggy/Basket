pragma solidity 0.8.0;
pragma experimental "ABIEncoderV2";

// simple contract for creating Baskets. can be called by anyone

import { BasketToken } from "./BasketToken.sol";
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
        string memory _symbol,
        address _vrf_coordinator,
        address _link
    )
        external
        returns (address)
    {
        require(_components.length > 0, "Must have at least 1 component");
        require(_components.length == _units.length, "Component and unit lengths must be the same");
        require(!_components.hasDuplicate(), "Components must not have a duplicate");


        for (uint256 i = 0; i < _components.length; i++) {
            require(_components[i] != address(0), "Component must not be null address");
            // if a basket were to contain link anyone could drain the link portion of the portfolio by repeatedly calling the lottery function
            require(_components[i] != address(_link), "Component can not be Link token, Link is used to secure the lottery");
            require(_units[i] > 0, "Units must be greater than 0");
        }


        BasketToken basketToken = new BasketToken(
            _components,
            _units,
            _name,
            _symbol,
            _vrf_coordinator,
            _link
            );


        emit basketCreated(address(basketToken), _name, _symbol);
        return address(basketToken);
    }

}
