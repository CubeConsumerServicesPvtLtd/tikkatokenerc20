// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./LiquidityPrograms.sol";

contract DappTokenSale {
    using SafeERC20 for IERC20;
    address payable admin;
    string public saleName;
    LiquidityPrograms private immutable liquidityProgramsContract;
    IERC20 private immutable phantomContract;
    uint256 public tokenPrice;
    uint256 public tokensSold;
    uint256 public tokensCap;

    event Sale(string _saleName, address _buyer, uint256 _amount);

    constructor(
        string memory _saleName,
        address _liquidityProgramsContract,
        address _phantomContract,
        uint256 _tokenPrice,
        uint256 _tokensCap
    ) {
        admin = payable(msg.sender);
        saleName = _saleName;
        liquidityProgramsContract = LiquidityPrograms(
            _liquidityProgramsContract
        );
        phantomContract = IERC20(_phantomContract);
        tokenPrice = _tokenPrice;
        tokensCap = _tokensCap;
    }

    function multiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function buyTokens(uint256 _numberOfTokens) public payable {
        // require(msg.value == multiply(_numberOfTokens, tokenPrice));
        uint256 amount = multiply(_numberOfTokens, tokenPrice);
        require(
            amount <= tokensCap - tokensSold,
            "Tokens exhausted for the sale"
        );
        require(
            phantomContract.allowance(msg.sender, address(this)) >= amount,
            "No allowance from buyer for Phantom"
        );
        require(
            phantomContract.transferFrom(msg.sender, address(this), amount),
            "Couldn't transfer Phantom Coins to Dapp"
        );
        uint256 startTime = block.timestamp;

        liquidityProgramsContract.createPrivateSaleLiquiditySchedule(
            msg.sender,
            startTime,
            _numberOfTokens
        );

        tokensSold += _numberOfTokens;

        emit Sale(saleName, msg.sender, _numberOfTokens);
    }

    function endSale() public {
        require(msg.sender == admin);
        tokensCap = 0;
    }
}
