// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.8.0. SEE SOURCE BELOW. !!
pragma solidity ^0.8.20;

interface BondingsCoreInterface {
    error AddressEmptyCode(address target);
    error AddressInsufficientBalance(address account);
    error FailedInnerCall();
    error InvalidInitialization();
    error NotInitializing();
    error OwnableInvalidOwner(address owner);
    error OwnableUnauthorizedAccount(address account);
    error SafeERC20FailedOperation(address token);
    event AdminSetParam(string paramName, bytes32 oldValue, bytes32 newValue);
    event BuyBondings(
        uint256 bondingsId,
        string bondingsName,
        address indexed user,
        uint256 share,
        uint256 lastShare,
        uint256 buyPrice,
        uint256 buyPriceAfterFee,
        uint256 fee
    );
    event Initialized(uint64 version);
    event LaunchBondings(
        uint256 bondingsId,
        string bondingsName,
        string bondingsSymbol,
        address indexed user
    );
    event OperatorSet(address operator, bool isOperator_);
    event OwnershipTransferStarted(
        address indexed previousOwner,
        address indexed newOwner
    );
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event RetrieveAndDeploy(
        uint256 bondingsId,
        string bondingsName,
        string bondingsSymbol,
        uint256 finalSupply,
        address operator,
        address tokenAddress
    );
    event SellBondings(
        uint256 bondingsId,
        string bondingsName,
        address indexed user,
        uint256 share,
        uint256 lastShare,
        uint256 sellPrice,
        uint256 sellPriceAfterFee,
        uint256 fee
    );

    function acceptOwnership() external;

    function bondingsCount() external view returns (uint256);

    function bondingsName(uint256) external view returns (string memory);

    function bondingsStage(uint256) external view returns (uint8);

    function bondingsSymbol(uint256) external view returns (string memory);

    function bondingsTokenAddress(uint256) external view returns (address);

    function bondingsTokenSupply() external view returns (uint256);

    function bondingsTotalShare(uint256) external view returns (uint256);

    function buyBondings(
        uint256 bondingsId,
        uint256 share,
        uint256 maxPayTokenAmount
    ) external;

    function fairLaunchSupply() external view returns (uint256);

    function getBondingsTotalShare(uint256 bondingsId)
        external
        view
        returns (uint256);

    function getBuyPrice(uint256 bondingsId, uint256 amount)
        external
        view
        returns (uint256);

    function getBuyPriceAfterFee(uint256 bondingsId, uint256 amount)
        external
        view
        returns (uint256);

    function getPrice(uint256 supply, uint256 amount)
        external
        pure
        returns (uint256);

    function getSellPrice(uint256 bondingsId, uint256 amount)
        external
        view
        returns (uint256);

    function getSellPriceAfterFee(uint256 bondingsId, uint256 amount)
        external
        view
        returns (uint256);

    function holdLimit() external view returns (uint256);

    function initialize(
        address unitTokenAddress_,
        address protocolFeeDestination_
    ) external;

    function isOperator(address) external view returns (bool);

    function launchBondings(string memory name, string memory symbol) external;

    function maxSupply() external view returns (uint256);

    function mintLimit() external view returns (uint256);

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function protocolFeeDestination() external view returns (address);

    function protocolFeePercent() external view returns (uint256);

    function renounceOwnership() external;

    function retrieveAndDeploy(uint256 bondingsId) external;

    function sellBondings(
        uint256 bondingsId,
        uint256 share,
        uint256 minGetTokenAmount
    ) external;

    function setBondingsTokenSupply(uint256 newBondingsTokenSupply) external;

    function setFairLaunchSupply(uint256 newFairLaunchSupply) external;

    function setHoldLimit(uint256 newHoldLimit) external;

    function setMaxSupply(uint256 newMaxSupply) external;

    function setMintLimit(uint256 newMintLimit) external;

    function setOperator(address operator, bool isOperator_) external;

    function setProtocolFeeDestination(address newProtocolFeeDestination)
        external;

    function setProtocolFeePercent(uint256 newProtocolFeePercent) external;

    function transferOwnership(address newOwner) external;

    function unitTokenAddress() external view returns (address);

    function userShare(uint256, address) external view returns (uint256);
}
