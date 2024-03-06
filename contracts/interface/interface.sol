// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

// Generate by https://gnidan.github.io/abi-to-sol/

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external pure returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool);

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IBondingsCore {
    event BuyBondings(
        string bondingsName,
        address indexed user,
        uint256 share,
        uint256 lastId,
        uint256 buyPrice,
        uint256 buyPriceAfterFee,
        uint256 fee
    );
    event Deployed(string bondingsName, address indexed user);
    event Initialized(uint8 version);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event SellBondings(
        string bondingsName,
        address indexed user,
        uint256 share,
        uint256 lastId,
        uint256 sellPrice,
        uint256 sellPriceAfterFee,
        uint256 fee
    );
    event TransferBondings(
        string bondingsName,
        address indexed from,
        address indexed to,
        uint256 share
    );

    function backendSigner() external view returns (address);

    function bondingsStage(string memory) external view returns (uint8);

    function buyBondings(
        string memory name,
        uint256 share,
        uint256 maxOutTokenAmount
    ) external;

    function consumeSignature(
        bytes4 selector,
        string memory name,
        address user,
        uint256 timestamp,
        bytes memory signature
    ) external;

    function deploy(
        string memory name,
        uint256 timestamp,
        bytes memory signature
    ) external;

    function disableSignatureMode() external pure returns (bool);

    function fairLaunchSupply() external view returns (uint256);

    function getBondingsTotalShare(string memory name)
        external
        view
        returns (uint256);

    function getBuyPrice(string memory name, uint256 amount)
        external
        view
        returns (uint256);

    function getBuyPriceAfterFee(string memory name, uint256 amount)
        external
        view
        returns (uint256);

    function getPrice(uint256 supply, uint256 amount)
        external
        pure
        returns (uint256);

    function getSellPrice(string memory name, uint256 amount)
        external
        view
        returns (uint256);

    function getSellPriceAfterFee(string memory name, uint256 amount)
        external
        view
        returns (uint256);

    function holdLimit() external view returns (uint256);

    function initialize(
        address backendSigner_,
        address unitTokenAddress_,
        address protocolFeeDestination_
    ) external;

    function maxSupply() external view returns (uint256);

    function mintLimit() external view returns (uint256);

    function owner() external view returns (address);

    function protocolFeeDestination() external view returns (address);

    function protocolFeePercent() external view returns (uint256);

    function renounceOwnership() external;

    function sellBondings(
        string memory name,
        uint256 share,
        uint256 minInTokenAmount
    ) external;

    function setBackendSigner(address newBackendSigner) external;

    function setFairLaunchSupply(uint256 newFairLaunchSupply) external;

    function setHoldLimit(uint256 newHoldLimit) external;

    function setMaxSupply(uint256 newMaxSupply) external;

    function setMintLimit(uint256 newMintLimit) external;

    function setProtocolFeeDestination(address newProtocolFeeDestination)
        external;

    function setProtocolFeePercent(uint256 newProtocolFeePercent) external;

    function signatureIsUsed(bytes32) external view returns (bool);

    function signatureValidTime() external view returns (uint256);

    function transferBondings(
        string memory name,
        address to,
        uint256 share
    ) external;

    function transferOwnership(address newOwner) external;

    function unitTokenAddress() external view returns (address);

    function userShare(string memory, address) external view returns (uint256);
}

interface IBONX {
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
    event Initialized(uint8 version);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event Renewal(uint256 nftTokenId, uint256 usdtAmount);
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    function approve(address to, uint256 tokenId) external;

    function backendSigner() external view returns (address);

    function balanceOf(address owner) external view returns (uint256);

    function consumeSignature(
        bytes4 selector,
        uint256 amount,
        address user,
        uint256 timestamp,
        bytes memory signature
    ) external;

    function disableSignatureMode() external pure returns (bool);

    function getApproved(uint256 tokenId) external view returns (address);

    function getBonxName(uint256 tokenId) external view returns (string memory);

    function getNextTokenId() external view returns (uint256);

    function initialize(
        address backendSigner_,
        address unitTokenAddress_,
        address renewalDestination_
    ) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function name() external view returns (string memory);

    function owner() external view returns (address);

    function ownerOf(uint256 tokenId) external view returns (address);

    function renewal(
        uint256 nftTokenId,
        uint256 usdtAmount,
        uint256 timestamp,
        bytes memory signature
    ) external;

    function renewalDestination() external view returns (address);

    function renounceOwnership() external;

    function retrieveNFT(uint256 tokenId) external;

    function safeMint(address to, string memory name)
        external
        returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) external;

    function setApprovalForAll(address operator, bool approved) external;

    function setBackendSigner(address newBackendSigner) external;

    function setRenewalDestination(address newRenewalDestination) external;

    function signatureIsUsed(bytes32) external view returns (bool);

    function signatureValidTime() external view returns (uint256);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferOwnership(address newOwner) external;

    function unitTokenAddress() external view returns (address);
}

interface IUSDB {
    error ERC20InsufficientAllowance(
        address spender,
        uint256 allowance,
        uint256 needed
    );
    error ERC20InsufficientBalance(
        address sender,
        uint256 balance,
        uint256 needed
    );
    error ERC20InvalidApprover(address approver);
    error ERC20InvalidReceiver(address receiver);
    error ERC20InvalidSender(address sender);
    error ERC20InvalidSpender(address spender);
    error OwnableInvalidOwner(address owner);
    error OwnableUnauthorizedAccount(address account);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external pure returns (uint8);

    function mint() external;

    function mintAny(address to, uint256 amount) external;

    function name() external view returns (string memory);

    function owner() external view returns (address);

    function renounceOwnership() external;

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function transferOwnership(address newOwner) external;
}
