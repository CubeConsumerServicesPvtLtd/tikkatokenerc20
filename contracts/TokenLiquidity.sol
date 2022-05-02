// contracts/TokenLiquidity.sol
// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title TokenLiquidity
 *
 * @dev provides the core function of creating and managing a liquidity schedule for
 * an ERC-20 token.
 *
 * A liquidity schedule is created to make a limited number of tokens available in parts to
 * the beneficiary at regular intervals (called term).
 *
 * As a security measure, the contract should be insulated under a facade contract by
 * transferring ownership of this contract to the facade contract.
 *
 */
contract TokenLiquidity is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    struct LiquiditySchedule {
        bool initialized;
        address beneficiary;
        uint256 start; // start time of the liquidity schedule
        uint256 liquidityPerTerm; // amount of tokens liquidated per term
        uint256 termSeconds; // seconds in a term
        uint256 amountTotal;
        uint256 released; // amount of tokens released
        bool revocable;
        bool revoked;
    }

    // address of the ERC20 token
    IERC20 private immutable _token;
    uint256 private _lockUntilDate;

    bytes32[] private liquiditySchedulesIds;
    mapping(bytes32 => LiquiditySchedule) private liquiditySchedules;
    uint256 private liquiditySchedulesTotalAmount;
    mapping(address => uint256) private holdersScheduleCount;

    event Released(uint256 amount);
    event Revoked();

    /**
     * @dev Reverts if no liquidity schedule matches the passed identifier.
     */
    modifier onlyIfScheduleExists(bytes32 scheduleId) {
        require(liquiditySchedules[scheduleId].initialized == true);
        _;
    }

    /**
     * @dev Reverts if the liquidity schedule does not exist or has been revoked.
     */
    modifier onlyIfLiquidityScheduleNotRevoked(bytes32 scheduleId) {
        require(liquiditySchedules[scheduleId].initialized == true);
        require(liquiditySchedules[scheduleId].revoked == false);
        _;
    }

    /**
     * @dev Reverts if the global time lock has expired.
     */
    modifier ifNotLocked() {
        require(_lockUntilDate > getCurrentTime());
        _;
    }

    /**
     * @dev Creates a liquidity contract.
     * @param token_ address of the ERC20 token contract
     * @param lockUntilDate_ time until the tokens are locked for release.
     */
    constructor(address token_, uint256 lockUntilDate_) {
        require(token_ != address(0x0));
        _token = IERC20(token_);
        _lockUntilDate = lockUntilDate_;
    }

    receive() external payable {}

    fallback() external payable {}

    /**
     * @dev Returns the number of liquidity schedules associated to a beneficiary.
     * @return the number of liquidity schedules
     */
    function getSchedulesCountByBeneficiary(address _beneficiary)
        external
        view
        returns (uint256)
    {
        return holdersScheduleCount[_beneficiary];
    }

    /**
     * @dev Returns the liquidity schedule id at the given index.
     * @return the liquidity id
     */
    function getScheduleIdAtIndex(uint256 index)
        external
        view
        returns (bytes32)
    {
        require(
            index < getLiquiditySchedulesCount(),
            "TokenLiquidity: index out of bounds"
        );
        return liquiditySchedulesIds[index];
    }

    /**
     * @notice Returns the liquidity schedule information for a given holder and index.
     * @return the liquidity schedule structure information
     */
    function getScheduleByAddressAndIndex(address holder, uint256 index)
        external
        view
        returns (LiquiditySchedule memory)
    {
        return
            getLiquiditySchedule(
                computeLiquidityScheduleIdForAddressAndIndex(holder, index)
            );
    }

    /**
     * @notice Returns the total amount of liquidity schedules.
     * @return the total amount of liquidity schedules
     */
    function getLiquiditySchedulesTotalAmount()
        external
        view
        returns (uint256)
    {
        return liquiditySchedulesTotalAmount;
    }

    /**
     * @dev Returns the address of the ERC20 token managed by the liquidity contract.
     */
    function getToken() external view returns (address) {
        return address(_token);
    }

    /**
     * @notice Creates a new liquidity schedule for a beneficiary.
     * @param _beneficiary address of the beneficiary to whom liquidated tokens are transferred
     * @param _start start time of the liquidity period
     * @param _liquidityPerTerm percent amount of the total amount liquidated per term
     * @param _termSeconds duration of a term period in the schedule
     * @param _amount total amount of tokens to be released at the end of the liquidity schedule
     * @param _revocable whether the liquidity schedule is revocable or not
     */
    function createLiquiditySchedule(
        address _beneficiary,
        uint256 _start,
        uint256 _liquidityPerTerm,
        uint256 _termSeconds,
        uint256 _amount,
        bool _revocable
    ) public onlyOwner {
        require(
            this.getWithdrawableAmount() >= _amount,
            "TokenLiquidity: cannot create liquidity schedule, insufficient tokens"
        );
        require(
            _liquidityPerTerm > 0,
            "TokenLiquidity: liquidity % per term must be > 0"
        );
        require(_amount > 0, "TokenLiquidity: amount must be > 0");
        require(
            _termSeconds >= 1,
            "TokenLiquidity: term duration must be 1 or more seconds"
        );
        bytes32 liquidityScheduleId = this
            .computeNextLiquidityScheduleIdForHolder(_beneficiary);
        liquiditySchedules[liquidityScheduleId] = LiquiditySchedule(
            true,
            _beneficiary,
            _start,
            _liquidityPerTerm,
            _termSeconds,
            _amount,
            0,
            _revocable,
            false
        );
        liquiditySchedulesTotalAmount = liquiditySchedulesTotalAmount.add(
            _amount
        );
        liquiditySchedulesIds.push(liquidityScheduleId);
        uint256 currentScheduleCount = holdersScheduleCount[_beneficiary];
        holdersScheduleCount[_beneficiary] = currentScheduleCount.add(1);
    }

    /**
     * @notice Revokes the liquidity schedule for given identifier.
     * @param liquidityScheduleId the liquidity schedule identifier
     */
    function revoke(bytes32 liquidityScheduleId)
        public
        onlyOwner
        onlyIfLiquidityScheduleNotRevoked(liquidityScheduleId)
    {
        LiquiditySchedule storage liquiditySchedule = liquiditySchedules[
            liquidityScheduleId
        ];
        require(
            liquiditySchedule.revocable == true,
            "TokenLiquidity: liquidity is not revocable"
        );
        uint256 liquidatedAmount = _computeReleasableAmount(liquiditySchedule);
        if (liquidatedAmount > 0) {
            release(liquidityScheduleId, liquidatedAmount);
        }
        uint256 unreleased = liquiditySchedule.amountTotal.sub(
            liquiditySchedule.released
        );
        liquiditySchedulesTotalAmount = liquiditySchedulesTotalAmount.sub(
            unreleased
        );
        liquiditySchedule.revoked = true;
    }

    /**
     * @notice Withdraw the specified amount if possible.
     * @param amount the amount to withdraw
     */
    function withdraw(uint256 amount) public nonReentrant onlyOwner {
        require(
            this.getWithdrawableAmount() >= amount,
            "TokenLiquidity: not enough withdrawable funds"
        );
        _token.safeTransfer(owner(), amount);
    }

    /**
     * @notice Release liquidated amount of tokens.
     * @param liquidityScheduleId the liquidity schedule identifier
     * @param amount the amount to release
     */
    function release(bytes32 liquidityScheduleId, uint256 amount)
        public
        ifNotLocked
        nonReentrant
        onlyIfLiquidityScheduleNotRevoked(liquidityScheduleId)
    {
        LiquiditySchedule storage liquiditySchedule = liquiditySchedules[
            liquidityScheduleId
        ];
        bool isBeneficiary = msg.sender == liquiditySchedule.beneficiary;
        bool isOwner = msg.sender == owner();
        require(
            isBeneficiary || isOwner,
            "TokenLiquidity: only beneficiary and owner can release liquidated tokens"
        );
        uint256 liquidatedAmount = _computeReleasableAmount(liquiditySchedule);
        require(
            liquidatedAmount >= amount,
            "TokenLiquidity: cannot release tokens, not enough liquidated tokens"
        );
        liquiditySchedule.released = liquiditySchedule.released.add(amount);
        address payable beneficiaryPayable = payable(
            liquiditySchedule.beneficiary
        );
        liquiditySchedulesTotalAmount = liquiditySchedulesTotalAmount.sub(
            amount
        );
        _token.safeTransfer(beneficiaryPayable, amount);
    }

    /**
     * @dev Returns the number of liquidity schedules managed by this contract.
     * @return the number of liquidity schedules
     */
    function getLiquiditySchedulesCount() public view returns (uint256) {
        return liquiditySchedulesIds.length;
    }

    /**
     * @notice Computes the liquidated amount of tokens for the given liquidity schedule identifier.
     * @return the liquidated amount
     */
    function computeReleasableAmount(bytes32 liquidityScheduleId)
        public
        view
        onlyIfLiquidityScheduleNotRevoked(liquidityScheduleId)
        returns (uint256)
    {
        LiquiditySchedule storage liquiditySchedule = liquiditySchedules[
            liquidityScheduleId
        ];
        return _computeReleasableAmount(liquiditySchedule);
    }

    /**
     * @notice Returns the liquidity schedule information for a given identifier.
     * @return the liquidity schedule structure information
     */
    function getLiquiditySchedule(bytes32 liquidityScheduleId)
        public
        view
        returns (LiquiditySchedule memory)
    {
        return liquiditySchedules[liquidityScheduleId];
    }

    /**
     * @dev Returns the amount of tokens that can be withdrawn by the owner.
     * @return the amount of tokens
     */
    function getWithdrawableAmount() public view returns (uint256) {
        return
            _token.balanceOf(address(this)).sub(liquiditySchedulesTotalAmount);
    }

    /**
     * @dev Computes the next liquidity schedule identifier for a given holder address.
     */
    function computeNextLiquidityScheduleIdForHolder(address holder)
        public
        view
        returns (bytes32)
    {
        return
            computeLiquidityScheduleIdForAddressAndIndex(
                holder,
                holdersScheduleCount[holder]
            );
    }

    /**
     * @dev Returns the last liquidity schedule for a given holder address.
     */
    function getLastLiquidityScheduleForHolder(address holder)
        public
        view
        returns (LiquiditySchedule memory)
    {
        return
            liquiditySchedules[
                computeLiquidityScheduleIdForAddressAndIndex(
                    holder,
                    holdersScheduleCount[holder] - 1
                )
            ];
    }

    /**
     * @dev Computes the liquidity schedule identifier for an address and an index.
     */
    function computeLiquidityScheduleIdForAddressAndIndex(
        address holder,
        uint256 index
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(holder, index));
    }

    /**
     * @dev Computes the releasable amount of tokens for a liquidity schedule.
     * @return the amount of releasable tokens
     */
    function _computeReleasableAmount(
        LiquiditySchedule memory liquiditySchedule
    ) internal view returns (uint256) {
        uint256 currentTime = getCurrentTime();
        if (
            currentTime < liquiditySchedule.start ||
            liquiditySchedule.revoked == true
        ) {
            return 0;
        } else {
            uint256 timeFromStart = currentTime.sub(liquiditySchedule.start);
            uint256 termSeconds = liquiditySchedule.termSeconds;
            uint256 termsElapsed = timeFromStart.div(termSeconds);
            uint256 vestedSeconds = termsElapsed.mul(termSeconds);
            uint256 liquidatedAmount = liquiditySchedule.liquidityPerTerm.mul(
                termsElapsed
            );
            if (liquidatedAmount > liquiditySchedule.amountTotal) {
                liquidatedAmount = liquiditySchedule.amountTotal;
            }
            liquidatedAmount = liquidatedAmount.sub(liquiditySchedule.released);
            return liquidatedAmount;
        }
    }

    function getCurrentTime() internal view virtual returns (uint256) {
        return block.timestamp;
    }
}
