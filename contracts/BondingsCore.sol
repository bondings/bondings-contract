// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

contract BondingsCore is Ownable2StepUpgradeable {

    /* ============================ Variables =========================== */
    /* ----------------- Supply ----------------- */
    uint256 public fairLaunchSupply;    // Max supply for stage 1
    uint256 public mintLimit;           // Mint limit in stage 1
    uint256 public holdLimit;           // Hold limit in stage 1
    uint256 public maxSupply;           // Max supply for bondings

    /* -------------- Protocol Fee -------------- */
    uint256 public protocolFeePercent;
    address public protocolFeeDestination;

    /* ------------- Unit of account ------------ */
    address public unitTokenAddress;

    /* ----------------- Storage ---------------- */
    // Total amount of different bondings assets
    uint256 public bondingsCount;

    // bondings id => bondings name
    mapping(uint256 => string) public bondingsName;

    // bondings id => [stage information for this bondings (0~3, 0 for not deployed)]
    mapping(uint256 => uint8) public bondingsStage;

    // bondings id => [total share num of the bondings]
    mapping(uint256 => uint256) public bondingsTotalShare;

    // bondings id => user => [user's share num of this bondings]
    mapping(uint256 => mapping(address => uint256)) public userShare;

    /* ----------- Reserve for upgrade ---------- */
    uint256[50] private __gap;
    

    /* ============================= Events ============================= */
    event LaunchBondings(uint256 bondingsId, string bondingsName, address indexed user);
    event BuyBondings(
        uint256 bondingsId, string bondingsName, address indexed user, uint256 share, 
        uint256 lastShare, uint256 buyPrice, uint256 buyPriceAfterFee, uint256 fee
    );
    event SellBondings(
        uint256 bondingsId, string bondingsName, address indexed user, uint256 share, 
        uint256 lastShare, uint256 sellPrice, uint256 sellPriceAfterFee, uint256 fee
    );
    event TransferBondings(
        uint256 bondingsId, string bondingsName,
        address indexed from, address indexed to, uint256 share
    );
    event AdminSetParam(string paramName, bytes32 oldValue, bytes32 newValue);


    /* =========================== Constructor ========================== */
    function initialize(
        address unitTokenAddress_, address protocolFeeDestination_
    ) public virtual initializer {
        __Ownable_init(msg.sender);
        __Ownable2Step_init();

        fairLaunchSupply = 100;
        mintLimit = 1;
        holdLimit = 10;
        maxSupply = 1000000000;

        protocolFeePercent = 100;
        protocolFeeDestination = protocolFeeDestination_;

        unitTokenAddress = unitTokenAddress_;
    }


    /* ====================== Pure / View functions ===================== */
    function getPrice(uint256 supply, uint256 amount) public pure returns (uint256) {
        uint256 sum1 = supply == 0 ? 0 : (supply - 1 ) * (supply) * (2 * (supply - 1) + 1) / 6;
        uint256 sum2 = (supply == 0 && amount == 1) ? 0 : 
            (supply + amount - 1) * (supply + amount) * (2 * (supply + amount - 1) + 1) / 6;
        uint256 summation = sum2 - sum1;
        return summation;
    }

    function getBuyPrice(uint256 bondingsId, uint256 amount) public view returns (uint256) {
        return getPrice(bondingsTotalShare[bondingsId], amount);
    }

    function getSellPrice(uint256 bondingsId, uint256 amount) public view returns (uint256) {
        return getPrice(bondingsTotalShare[bondingsId] - amount, amount);
    }

    function getBuyPriceAfterFee(uint256 bondingsId, uint256 amount) public view returns (uint256) {
        uint256 price = getBuyPrice(bondingsId, amount);
        uint256 fee = price * protocolFeePercent / 10000;
        return price + fee;
    }

    function getSellPriceAfterFee(uint256 bondingsId, uint256 amount) public view returns (uint256) {
        uint256 price = getSellPrice(bondingsId, amount);
        uint256 fee = price * protocolFeePercent / 10000;
        return price - fee;
    }

    function getBondingsTotalShare(uint256 bondingsId) public view returns (uint256) {
        require(bondingsStage[bondingsId] != 0, "Bondings not deployed!");
        return bondingsTotalShare[bondingsId] - 1;
    }


    /* ========================= Write functions ======================== */
    /* ---------------- For User ---------------- */
    function launchBondings(string memory name) public {
        // Deploy the Bondings
        uint256 bondingsId = bondingsCount;
        bondingsCount += 1;
        bondingsName[bondingsId] = name;
        bondingsStage[bondingsId] = 1;
        bondingsTotalShare[bondingsId] = 1;

        // Event
        emit LaunchBondings(bondingsId, name, _msgSender());
    }


    function buyBondings(
        uint256 bondingsId,
        uint256 share, 
        uint256 maxPayTokenAmount
    ) public {
        // Local variables
        address user = _msgSender();
        uint8 stage = bondingsStage[bondingsId];
        uint256 totalShare = bondingsTotalShare[bondingsId];

        // Check requirements
        require(share > 0, "Share must be greater than 0!");
        require(stage != 0, "Bondings not deployed!");
        require(totalShare + share <= maxSupply, "Exceed max supply!");

        // Stage transition
        if (stage == 1) {
            require(share <= mintLimit, "Exceed mint limit in stage 1!");
            require(userShare[bondingsId][user] + share <= holdLimit, "Exceed hold limit in stage 1!");
            if (totalShare + share > fairLaunchSupply) 
                bondingsStage[bondingsId] = 2;           // Stage transition: 1 -> 2
        } else if (stage == 2) {
            if (totalShare + share == maxSupply)
                bondingsStage[bondingsId] = 3;           // Stage transition: 2 -> 3
        }

        // Calculate fees and transfer tokens
        uint256 price = getBuyPrice(bondingsId, share);
        uint256 fee = price * protocolFeePercent / 10000;
        uint256 priceAfterFee = price + fee;
        require(priceAfterFee <= maxPayTokenAmount, "Slippage exceeded!");
        IERC20(unitTokenAddress).transferFrom(user, address(this), priceAfterFee);
        if (fee > 0)
            IERC20(unitTokenAddress).transfer(protocolFeeDestination, fee);
        
        // Update storage
        bondingsTotalShare[bondingsId] += share;
        userShare[bondingsId][user] += share;

        // Event
        emit BuyBondings(
            bondingsId, bondingsName[bondingsId], user, share, 
            totalShare + share - 1, price, priceAfterFee, fee
        );
    }


    function sellBondings(
        uint256 bondingsId,
        uint256 share, 
        uint256 minGetTokenAmount
    ) public {
        // Local variables
        address user = _msgSender();
        uint8 stage = bondingsStage[bondingsId];

        // Check stage and share num
        require(share > 0, "Share must be greater than 0!");
        require(stage != 0, "Bondings not deployed!");
        require(userShare[bondingsId][user] >= share, "Insufficient shares!");

        // Calculate fees and transfer tokens
        uint256 price = getSellPrice(bondingsId, share);
        uint256 fee = price * protocolFeePercent / 10000;
        uint256 priceAfterFee = price - fee;
        require(priceAfterFee >= minGetTokenAmount, "Slippage exceeded!");
        IERC20(unitTokenAddress).transfer(user, priceAfterFee);
        if (fee > 0)
            IERC20(unitTokenAddress).transfer(protocolFeeDestination, fee);
        
        // Update storage
        bondingsTotalShare[bondingsId] -= share;
        userShare[bondingsId][user] -= share;
        
        // Event
        emit SellBondings(
            bondingsId, bondingsName[bondingsId], user, share, 
            bondingsTotalShare[bondingsId], price, priceAfterFee, fee
        );
    }


    function transferBondings(
        uint256 bondingsId,
        address to, 
        uint256 share
    ) public {
        // Local variables
        address user = _msgSender();
        uint8 stage = bondingsStage[bondingsId];

        // Check stage and share num
        require(stage == 3, "Transfer is only allowed in stage 3!");
        require(userShare[bondingsId][user] >= share, "Insufficient shares!");

        // Update storage
        userShare[bondingsId][user] -= share;
        userShare[bondingsId][to] += share;

        // Event
        emit TransferBondings(bondingsId, bondingsName[bondingsId], user, to, share);
    }


    /* ---------------- For Admin --------------- */
    function setFairLaunchSupply(uint256 newFairLaunchSupply) public onlyOwner {
        require(newFairLaunchSupply <= maxSupply, "Fair launch supply must be less than max supply!");
        require(newFairLaunchSupply >= holdLimit, "Fair launch supply must be greater than hold limit!");
        uint256 oldFairLaunchSupply = fairLaunchSupply;
        fairLaunchSupply = newFairLaunchSupply;
        emit AdminSetParam("fairLaunchSupply", bytes32(oldFairLaunchSupply), bytes32(newFairLaunchSupply));
    }

    function setMintLimit(uint256 newMintLimit) public onlyOwner {
        require(newMintLimit <= holdLimit, "Mint limit must be less than hold limit!");
        uint256 oldMintLimit = mintLimit;
        mintLimit = newMintLimit;
        emit AdminSetParam("mintLimit", bytes32(oldMintLimit), bytes32(newMintLimit));
    }

    function setHoldLimit(uint256 newHoldLimit) public onlyOwner {
        require(newHoldLimit >= mintLimit, "Hold limit must be greater than mint limit!");
        require(newHoldLimit <= fairLaunchSupply, "Hold limit must be less than fair launch supply!");
        uint256 oldHoldLimit = holdLimit;
        holdLimit = newHoldLimit;
        emit AdminSetParam("holdLimit", bytes32(oldHoldLimit), bytes32(newHoldLimit));
    }

    function setMaxSupply(uint256 newMaxSupply) public onlyOwner {
        require(newMaxSupply >= fairLaunchSupply, "Max supply must be greater than fair launch supply!");
        uint256 oldMaxSupply = maxSupply;
        maxSupply = newMaxSupply;
        emit AdminSetParam("maxSupply", bytes32(oldMaxSupply), bytes32(newMaxSupply));
    }

    function setProtocolFeePercent(uint256 newProtocolFeePercent) public onlyOwner {
        require(newProtocolFeePercent <= 1000, "Protocol fee percent must be less than 1000 (10%)!");
        uint256 oldProtocolFeePercent = protocolFeePercent;
        protocolFeePercent = newProtocolFeePercent;
        emit AdminSetParam("protocolFeePercent", bytes32(oldProtocolFeePercent), bytes32(newProtocolFeePercent));
    }

    function setProtocolFeeDestination(address newProtocolFeeDestination) public onlyOwner {
        address oldProtocolFeeDestination = protocolFeeDestination;
        protocolFeeDestination = newProtocolFeeDestination;
        emit AdminSetParam(
            "protocolFeeDestination", 
            bytes32(uint256(uint160(oldProtocolFeeDestination))), 
            bytes32(uint256(uint160(newProtocolFeeDestination)))
        );
    }
}