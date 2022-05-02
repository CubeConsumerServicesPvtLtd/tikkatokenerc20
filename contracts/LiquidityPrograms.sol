// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./TokenLiquidity.sol";

/**
 * @title LiquidityPrograms
 */
contract LiquidityPrograms is Ownable {
    using SafeMath for uint256;

    // address of the TokenLiquidity smart contract
    TokenLiquidity private immutable _tokenLiquidity;

    constructor(address payable tokenLiquidity) {
        _tokenLiquidity = TokenLiquidity(tokenLiquidity);
    }

    /**
     * @dev create liquidity schedule for an advisor.
     *
     * Term duration for initial investor is 91 days (~quarterly)
     * Percent amount liquidated per term is 2.72
     */
    function createAdvisorLiquiditySchedule(
        address forBeneficiary,
        uint256 startTime,
        uint256 amount
    ) public onlyOwner {
        uint256 _termSeconds = 7862400; // seconds in 91 days - for quarterly liquidity
        uint256 amountPerTerm = amount.div(100).mul(10);
        _tokenLiquidity.createLiquiditySchedule(
            forBeneficiary,
            startTime,
            amountPerTerm,
            _termSeconds,
            amount,
            true
        );
    }

    /**
     * @dev create liquidity schedule for a team member.
     *
     * Term duration for initial investor is 91 days (~quarterly)
     * Percent amount liquidated per term is 2.72
     */
    function createTeamLiquiditySchedule(
        address forBeneficiary,
        uint256 startTime,
        uint256 amount
    ) public onlyOwner {
        uint256 _termSeconds = 7862400; // seconds in 91 days - for quarterly liquidity
        uint256 amountPerTerm = amount.div(1000).mul(75);
        _tokenLiquidity.createLiquiditySchedule(
            forBeneficiary,
            startTime,
            amountPerTerm,
            _termSeconds,
            amount,
            true
        );
    }

    /**
     * @dev create liquidity schedule for a private sale investor.
     *
     * Term duration for initial investor is 91 days (~quarterly)
     * Percent amount liquidated per term is 2.72
     */
    function createPrivateSaleLiquiditySchedule(
        address forBeneficiary,
        uint256 startTime,
        uint256 amount
    ) public onlyOwner {
        uint256 _termSeconds = 7862400; // seconds in 91 days - for quarterly liquidity
        uint256 amountPerTerm = amount.div(100).mul(10);
        _tokenLiquidity.createLiquiditySchedule(
            forBeneficiary,
            startTime,
            amountPerTerm,
            _termSeconds,
            amount,
            true
        );
    }

    /**
     * @dev create liquidity schedule for an initial investor.
     *
     * Term duration for initial investor is 91 days (~quarterly)
     * Percent amount liquidated per term is 2.72
     */
    function createInitialInvestorLiquiditySchedule(
        address forBeneficiary,
        uint256 startTime,
        uint256 amount
    ) public onlyOwner {
        uint256 _termSeconds = 7862400; // seconds in 91 days - for quarterly liquidity
        uint256 amountPerTerm = amount.div(10000).mul(272);
        _tokenLiquidity.createLiquiditySchedule(
            forBeneficiary,
            startTime,
            amountPerTerm,
            _termSeconds,
            amount,
            true
        );
    }

    /**
     * @dev create liquidity schedule for marketing and community.
     *
     * Term duration for initial investor is 91 days (~quarterly)
     * Percent amount liquidated per term is 1
     */
    function createMarketingCommunityLiquiditySchedule(
        address forBeneficiary,
        uint256 startTime,
        uint256 amount
    ) public onlyOwner {
        uint256 _termSeconds = 7862400; // seconds in 91 days - for quarterly liquidity
        uint256 amountPerTerm = amount.div(100).mul(1);
        _tokenLiquidity.createLiquiditySchedule(
            forBeneficiary,
            startTime,
            amountPerTerm,
            _termSeconds,
            amount,
            true
        );
    }
}
