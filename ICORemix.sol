pragma solidity ^0.5.0;


import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC20/ERC20Pausable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC20/ERC20Mintable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/crowdsale/emission/MintedCrowdsale.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/crowdsale/validation/CappedCrowdsale.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/crowdsale/validation/TimedCrowdsale.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/crowdsale/distribution/RefundablePostDeliveryCrowdsale.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/ownership/Ownable.sol";
import "./PupperCoin.sol";


/**
 * Author Abu Bakkar
 * @title SampleCrowdsaleToken
 * @dev Very simple ERC20 Token that can be minted.
 * It is meant to be used in a crowdsale contract.
 */
contract SampleCrowdsaleToken is ERC20Mintable, ERC20Detailed {
    constructor ( 
        string memory name,
        string memory symbol,
        uint initial_supply
        ) public ERC20Detailed(name, symbol, 18) {
        // solhint-disable-previous-line no-empty-blocks
    }
}

// @TODO: Inherit the crowdsale contracts
contract MyCrowdsale is  MintedCrowdsale, CappedCrowdsale, TimedCrowdsale, RefundablePostDeliveryCrowdsale, Ownable {
    
    
     // Track investor contributiofoundationPercentage  = 10;
     uint256 public investorMinCap = 2000000000000000; // 0.002 ether
     uint256 public investorHardCap = 50000000000000000000; // 50 ether
     mapping(address => uint256) public contributions;
     
     
    // // Token Distribution
    // uint256 public tokenSalePercentage   = 70;
    // uint256 public foundersPercentage    = 10;
    // uint256 public foundationPercentage  = 10;
    // uint256 public partnersPercentage    = 10;
     
     
     // Crowdsale Stages
     enum CrowdsaleStage { PreICO, ICO }
     
    // Default to presale stage
    CrowdsaleStage public stage = CrowdsaleStage.PreICO;
    
   
    constructor( 
        uint rate, // rate in TKNbits
        ERC20Mintable token, // token name
        // PupperCoin token, // token name
        address payable wallet, // company's fundraising wallet that holds ETH sent from users
        uint256 goal, // goal of the crowdsale
        uint256 cap,
        uint256 openingTime, // testing: uint fakenow
        uint256 closingTime // testing: closingTime = fakenow + 2 minutes
        )
        
        Crowdsale(rate, wallet, token)
        MintedCrowdsale()
        CappedCrowdsale(cap) //changed from goal
        TimedCrowdsale(openingTime, closingTime) // testing: TimedCrowdsale(fakenow, fakenow + 2 minutes)
        RefundableCrowdsale(goal)
        // FinalizableCrowdsale()
        
        // @TODO: Pass the constructor parameters to the crowdsale contracts.
        public
        
    { 
        require(goal <= cap);
        // constructor can stay empty
    }
    
     /**
  * @dev Returns the amount contributed so far by a sepecific user.
  * @param _beneficiary Address of contributor
  * @return User contribution so far
  */
    function getUserContribution(address _beneficiary) public view returns (uint256)
    {
    return contributions[_beneficiary];
    }
    
    // function raste() public view returns (uint256) {
    //      rate = 500;
    // }
    
    /**
    * @dev Allows admin to update the crowdsale stage
    * @param _stage Crowdsale stage
    */
    function setCrowdsaleStage(uint _stage) public onlyOwner{
    if(uint(CrowdsaleStage.PreICO) == _stage) {
      stage = CrowdsaleStage.PreICO;
    } else if (uint(CrowdsaleStage.ICO) == _stage) {
      stage = CrowdsaleStage.ICO;
    }
    // make the _rate variable public in parent contract
    // if(stage == CrowdsaleStage.PreICO) {
    //   rate = 500;
    // } else if (stage == CrowdsaleStage.ICO) {
    //   rate = 250;
    // }
  }
    /**
   * @dev forwards funds to the wallet during the PreICO stage, then the refund vault during ICO stage
   */
  function _forwardFunds() internal {
    if(stage == CrowdsaleStage.PreICO) {
        
    address payable _wallet = super.wallet();
      _wallet.transfer(msg.value);
    } else if (stage == CrowdsaleStage.ICO) {
      super._forwardFunds();
    }
  }
    
    /**
  * @dev Extend parent behavior requiring purchase to respect investor min/max funding cap.
  * @param _beneficiary Token purchaser
  * @param _weiAmount Amount of wei contributed
  */
  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal 
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
    uint256 _existingContribution = contributions[_beneficiary];
    uint256 _newContribution = _existingContribution.add(_weiAmount);
    require(_newContribution >= investorMinCap && _newContribution <= investorHardCap);
    contributions[_beneficiary] = _newContribution;
  }
  
    /**
   * @dev enables token transfers, called when owner calls finalize()
  */
  function _finalization() internal {
    if(goalReached()) {
    //   ERC20Mintable erc20Mintable = ERC20Mintable(token);
    //   // Do more stuff....
    //   erc20Mintable.renounceMinter();
    //   // Unpause the token
    //   ERC20Pausable erc20Pausable = new ERC20Pausable(token);
    //   erc20Pausable.unpause();
      
    //   erc20Pausable.renounceOwnership(wallet);
    }

    super.finalize();
  }
}

contract MyCrowdsaleDeployer {

    address public token_sale_address;
    address public token_address;
    constructor(
    
        // @TODO: Fill in the constructor parameters!
        string memory name,
        string memory symbol,
        uint rate,
        address payable wallet, // this address will recieve all Ether raised by the sale
        uint256 goal,
        uint256 cap
        // testing: uint fakenow
    )
        public
    {
        // @TODO: create the PupperCoin and keep its address handy
        
        SampleCrowdsaleToken token = new SampleCrowdsaleToken(name, symbol, 18);
        token_address = address(token);

        // @TODO: create the PupperCoinSale and tell it about the token, set the goal, and set the open and close times to now and now + 24 weeks.
        
        MyCrowdsale token_sale = new MyCrowdsale(rate, token, wallet,goal,cap, now, now + 10 minutes);  
        // // testing: replace now with fakenow and replace 24 weeks with 5 minutes
        token_sale_address = address(token_sale);


        // make the PupperCoinSale contract a minter, then have the PupperCoinSaleDeployer renounce its minter role
        token.addMinter(token_sale_address);
        //mush use this in real ICO
        // token.renounceMinter();
        
        token.addMinter(wallet);
        
    }
}
