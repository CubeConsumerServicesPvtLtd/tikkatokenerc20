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

    IERC20 private immutable usdcContract =
        IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    IERC20 private immutable daiContract =
        IERC20(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063);

    uint256 public daiTokenPrice;
    uint256 public usdcTokenPrice;
    uint256 public tokensSold;
    uint256 public tokensCap;

    event Sale(string _saleName, address _buyer, uint256 _amount);

    constructor(
        string memory _saleName,
        address _liquidityProgramsContract,
        uint256 _daiTokenPrice,
        uint256 _usdcTokenPrice,
        uint256 _tokensCap
    ) {
        admin = payable(msg.sender);
        saleName = _saleName;
        liquidityProgramsContract = LiquidityPrograms(
            _liquidityProgramsContract
        );
        daiTokenPrice = _daiTokenPrice;
        usdcTokenPrice = _usdcTokenPrice;
        tokensCap = _tokensCap;
    }

    function multiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    modifier ifTikkaAvailable(uint256 _numberOfTokens) {
        require(
            _numberOfTokens <= tokensCap - tokensSold,
            "Tokens exhausted for the sale"
        );
        _;
    }

    function buyTokensWithDAI(uint256 _numberOfTokens)
        public
        payable
        ifTikkaAvailable(_numberOfTokens)
    {
        uint256 orderPrice = multiply(_numberOfTokens, daiTokenPrice);
        require(
            daiContract.allowance(msg.sender, address(this)) >= orderPrice,
            "No allowance from buyer for DAI"
        );
        require(
            daiContract.transferFrom(msg.sender, address(this), orderPrice),
            "Couldn't transfer DAI Coins to Dapp"
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

    function buyTokensWithUSDC(uint256 _numberOfTokens)
        public
        payable
        ifTikkaAvailable(_numberOfTokens)
    {
        uint256 orderPrice = multiply(_numberOfTokens, usdcTokenPrice);
        require(
            usdcContract.allowance(msg.sender, address(this)) >= orderPrice,
            "No allowance from buyer for USDC"
        );
        require(
            usdcContract.transferFrom(msg.sender, address(this), orderPrice),
            "Couldn't transfer USDC Coins to Dapp"
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
