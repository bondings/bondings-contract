// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

using SafeERC20 for IERC20;

contract BondingsToken is ERC20 {
    constructor(
        string memory name, string memory symbol, address to, uint256 initialSupply
    ) ERC20(name, symbol) {
        require(initialSupply > 0, "Initial supply must be greater than 0!");
        _mint(to, initialSupply);
    }
}

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

    // Phase 2: Supply of each ERC20 token
    uint256 public erc20Supply;

    // Phase 2: Operator role (withdraw liquidity and launch ERC20 token)
    mapping(address => bool) public isOperator;

    // Phase 2: bondings id => bondings symbol
    mapping(uint256 => string) public bondingsSymbol;

    // Phase 2: bondings id => ERC20 token address
    mapping(uint256 => address) public erc20Address;

    // Phase 2: Seed liquidity for ERC20 pool
    uint256 public seedLiquidity;

    /* ----------- Reserve for upgrade ---------- */
    uint256[45] private __gap;


    /* ============================ Modifiers =========================== */
    modifier onlyOperator() {
        require(isOperator[_msgSender()], "Not operator!");
        _;
    }
    

    /* ============================= Events ============================= */
    event LaunchBondings(
        uint256 bondingsId, string bondingsName, string bondingsSymbol, address indexed user
    );
    event BuyBondings(
        uint256 bondingsId, string bondingsName, address indexed user, uint256 share, 
        uint256 lastShare, uint256 buyPrice, uint256 buyPriceAfterFee, uint256 fee
    );
    event SellBondings(
        uint256 bondingsId, string bondingsName, address indexed user, uint256 share, 
        uint256 lastShare, uint256 sellPrice, uint256 sellPriceAfterFee, uint256 fee
    );
    event LaunchERC20(
        uint256 bondingsId, string bondingsName, string bondingsSymbol,
        uint256 finalSupply, address operator, address tokenAddress
    );
    event AdminSetParam(string paramName, bytes32 oldValue, bytes32 newValue);
    event OperatorSet(address operator, bool isOperator_);


    /* =========================== Constructor ========================== */
    function initialize(
        address unitTokenAddress_, address protocolFeeDestination_
    ) public virtual initializer {
        __Ownable_init(msg.sender);
        __Ownable2Step_init();

        fairLaunchSupply = 300;
        mintLimit = 30;
        holdLimit = 30;
        maxSupply = 3000;

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
            // This is for fitting the rules "the 0th share's price is 1, not 0"
    }


    /* ========================= Write functions ======================== */
    /* ---------------- For User ---------------- */
    function launchBondings(string memory name, string memory symbol) public {
        // Check name and symbol not empty
        require(bytes(name).length > 0, "Name cannot be empty!");
        require(bytes(symbol).length > 0, "Symbol cannot be empty!");
        
        // Deploy the Bondings
        uint256 bondingsId = bondingsCount;
        bondingsCount += 1;
        bondingsName[bondingsId] = name;
        bondingsSymbol[bondingsId] = symbol;
        bondingsStage[bondingsId] = 1;
        bondingsTotalShare[bondingsId] = 1;

        // Event
        emit LaunchBondings(bondingsId, name, symbol, _msgSender());
    }


    function buyBondings(
        uint256 bondingsId,
        uint256 share, 
        uint256 maxPayTokenAmount
    ) public {
        // Local variables
        address user = _msgSender();
        uint8 stage = bondingsStage[bondingsId];
        uint256 totalShare = getBondingsTotalShare(bondingsId);

        // Check requirements
        require(share > 0, "Share must be greater than 0!");
        require(stage != 0, "Bondings not deployed!");
        require(totalShare + share <= maxSupply, "Exceed max supply!");

        // Stage transition
        if (stage == 1) {
            require(share <= mintLimit, "Exceed mint limit in stage 1!");
            require(userShare[bondingsId][user] + share <= holdLimit, "Exceed hold limit in stage 1!");
            if (totalShare + share >= fairLaunchSupply) 
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
        IERC20(unitTokenAddress).safeTransferFrom(user, address(this), priceAfterFee);
        if (fee > 0)
            IERC20(unitTokenAddress).safeTransfer(protocolFeeDestination, fee);
        
        // Update storage
        bondingsTotalShare[bondingsId] += share;
        userShare[bondingsId][user] += share;

        // Event
        emit BuyBondings(
            bondingsId, bondingsName[bondingsId], user, share, 
            totalShare + share, price, priceAfterFee, fee
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
        require(stage != 3, "Bondings already in stage 3!");
        require(userShare[bondingsId][user] >= share, "Insufficient shares!");

        // Calculate fees and transfer tokens
        uint256 price = getSellPrice(bondingsId, share);
        uint256 fee = price * protocolFeePercent / 10000;
        uint256 priceAfterFee = price - fee;
        require(priceAfterFee >= minGetTokenAmount, "Slippage exceeded!");
        IERC20(unitTokenAddress).safeTransfer(user, priceAfterFee);
        if (fee > 0)
            IERC20(unitTokenAddress).safeTransfer(protocolFeeDestination, fee);
        
        // Update storage
        bondingsTotalShare[bondingsId] -= share;
        userShare[bondingsId][user] -= share;
        
        // Event
        emit SellBondings(
            bondingsId, bondingsName[bondingsId], user, share, 
            bondingsTotalShare[bondingsId], price, priceAfterFee, fee
        );
    }


    function launchERC20(uint256 bondingsId) public onlyOperator {
        // Retrieve the bondings assets
        require(bondingsStage[bondingsId] == 3, "Bondings not in stage 3!");
        uint256 totalAssets = getPrice(1, maxSupply);
        IERC20(unitTokenAddress).safeTransfer(protocolFeeDestination, totalAssets - seedLiquidity);
        IERC20(unitTokenAddress).safeTransfer(_msgSender(), seedLiquidity);
        
        // Create(deploy) the ERC20 token
        string memory symbol = bytes(bondingsSymbol[bondingsId]).length == 0 ?
            bondingsName[bondingsId] : bondingsSymbol[bondingsId];
        IERC20 bondingsToken = new BondingsToken(
            bondingsName[bondingsId], symbol, _msgSender(), erc20Supply
        );
        erc20Address[bondingsId] = address(bondingsToken);

        // Event
        emit LaunchERC20(
            bondingsId, bondingsName[bondingsId], bondingsSymbol[bondingsId],
            totalAssets, _msgSender(), address(bondingsToken)
        );
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
        require(newProtocolFeeDestination != address(0), "Protocol fee destination cannot be zero address!");
        address oldProtocolFeeDestination = protocolFeeDestination;
        protocolFeeDestination = newProtocolFeeDestination;
        emit AdminSetParam(
            "protocolFeeDestination", 
            bytes32(uint256(uint160(oldProtocolFeeDestination))), 
            bytes32(uint256(uint160(newProtocolFeeDestination)))
        );
    }

    function setERC20Supply(uint256 newErc20Supply) public onlyOwner {
        require(newErc20Supply >= maxSupply, "ERC20 supply must be greater than bondings max supply!");
        uint256 oldErc20Supply = erc20Supply;
        erc20Supply = newErc20Supply;
        emit AdminSetParam("erc20Supply", bytes32(oldErc20Supply), bytes32(newErc20Supply));
    }

    function setSeedLiquidity(uint256 newSeedLiquidity) public onlyOwner {
        uint256 oldSeedLiquidity = seedLiquidity;
        seedLiquidity = newSeedLiquidity;
        emit AdminSetParam("seedLiquidity", bytes32(oldSeedLiquidity), bytes32(newSeedLiquidity));
    }

    function setOperator(address operator, bool isOperator_) public onlyOwner {
        isOperator[operator] = isOperator_;
        emit OperatorSet(operator, isOperator_);
    }
}