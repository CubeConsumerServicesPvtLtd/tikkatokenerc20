// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./TokenLiquidity.sol";

/**
 * @title LiquidityPrograms
 */
contract LiquidityPrograms is Ownable, AccessControl {
    using SafeMath for uint256;

    // address of the TokenLiquidity smart contract
    TokenLiquidity private immutable _tokenLiquidity;

    bytes32 public constant PVTSALE_ROLE = keccak256("PVTSALE_ROLE");
    bytes32 public constant ADVISOR_ROLE = keccak256("ADVISOR_ROLE");
    bytes32 public constant TEAM_ROLE = keccak256("TEAM_ROLE");
    bytes32 public constant INITIALINV_ROLE = keccak256("INITIALINV_ROLE");
    bytes32 public constant MKTCOM_ROLE = keccak256("MKTCOM_ROLE");

    constructor(address payable tokenLiquidity) {
        _tokenLiquidity = TokenLiquidity(tokenLiquidity);
    }

    function assignPrivateSaleRole(address _user) public onlyOwner {
        _grantRole(PVTSALE_ROLE, _user);
    }

    function assignAdvisorRole(address _user) public onlyOwner {
        _grantRole(ADVISOR_ROLE, _user);
    }

    function assignTeamRole(address _user) public onlyOwner {
        _grantRole(TEAM_ROLE, _user);
    }

    function assignInitialInvestorRole(address _user) public onlyOwner {
        _grantRole(INITIALINV_ROLE, _user);
    }

    function assignMarketingCommunityRole(address _user) public onlyOwner {
        _grantRole(MKTCOM_ROLE, _user);
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
    ) public onlyRole(ADVISOR_ROLE) {
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
    ) public onlyRole(TEAM_ROLE) {
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
    ) public onlyRole(PVTSALE_ROLE) {
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
    ) public onlyRole(INITIALINV_ROLE) {
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
    ) public onlyRole(MKTCOM_ROLE) {
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
