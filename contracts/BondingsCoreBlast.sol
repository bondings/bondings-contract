// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interface/blast.sol";
import "./BondingsCore.sol";

contract BondingsCoreBlast is BondingsCore {
    /**
     * @notice The addresses of ETH and USDB may be changed in Blast Mainnet. 
     *        See https://docs.blast.io/building/guides/weth-yield#getting-usdb for more.
     */
    address public constant BLAST_ETH = 0x4300000000000000000000000000000000000002;
    address public constant BLAST_USDB = 0x4200000000000000000000000000000000000022;
    address public constant BLAST_POINT = 0x2fc95838c71e76ec69ff817983BFf17c710F34E0;

    address public pointsOperator;

    uint256[50] private __gap;

    event ChangedPointsOperator(address oldPointsOperator, address newPointsOperator);

    function initialize(
        address pointsOperator_, address protocolFeeDestination_
    ) public override initializer {
        // super.initialize(backendSigner_, BLAST_USDB, protocolFeeDestination_);
        super.initialize(BLAST_USDB, protocolFeeDestination_);
		IBlast(BLAST_ETH).configureClaimableYield();
        IBlast(BLAST_ETH).configureClaimableGas();
        IERC20Rebasing(BLAST_USDB).configure(YieldMode.CLAIMABLE);
        IBlastPoints(BLAST_POINT).configurePointsOperator(pointsOperator_);
        pointsOperator = pointsOperator_;
    }

    // Claim all the possible yield (including gas refund)
    function claimAllYield(address yieldRecipient) public onlyOwner {
        // Claim the ETH yield
        IBlast(BLAST_ETH).claimAllYield(address(this), yieldRecipient);

        // Claim the ETH gas refund
		IBlast(BLAST_ETH).claimMaxGas(address(this), yieldRecipient);

        // Claim the USDB yield
        IERC20Rebasing(BLAST_USDB).claim(
            yieldRecipient, 
            IERC20Rebasing(BLAST_USDB).getClaimableAmount(address(this))
        );
    }

    // Just claim all the ETH yield (probably not useful in most cases)
    function claimETHYield(address yieldRecipient) public onlyOwner {
        IBlast(BLAST_ETH).claimAllYield(address(this), yieldRecipient);
    }
    
    // Just claim all the gas refund with 100% claim rate (won't claim the last-1-month gas refund)
    function claimMaxGas(address yieldRecipient) public onlyOwner {
        IBlast(BLAST_ETH).claimMaxGas(address(this), yieldRecipient);
    }

    // Just claim all the USDB yield
    function claimUSDBYield(address yieldRecipient) public onlyOwner {
        IERC20Rebasing(BLAST_USDB).claim(
            yieldRecipient, 
            IERC20Rebasing(BLAST_USDB).getClaimableAmount(address(this))
        );
    }

    // [Danger Zone] Just claim all the gas refund with any claim rate (!! will lose some potential gas refund)
    function claimAllGas(address yieldRecipient) public onlyOwner {
        IBlast(BLAST_ETH).claimAllGas(address(this), yieldRecipient);
    }

    // Reset the points operator
    function resetPointsOperator(address newPointsOperator) public onlyOwner {
        address oldPointsOperator = pointsOperator;
        IBlastPoints(BLAST_POINT).configurePointsOperator(newPointsOperator);
        pointsOperator = newPointsOperator;
        emit ChangedPointsOperator(oldPointsOperator, newPointsOperator);
    }

}