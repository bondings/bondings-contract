// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

contract BONX is ERC721Upgradeable, OwnableUpgradeable {

    /* ===================== Variables & Constructor ==================== */

    uint256 private _nextTokenId;
    address public unitTokenAddress;
    address public backendSigner;           // Signer for renewal funds
    uint256 public signatureValidTime;      // Valid time for a signature
    address public renewalDestination;      // Address for receiving the renewal funds

    // nft token id => bonding name
    mapping(uint256 => string) private _bonxNames;

    // keccak256(signature) => [whether this signature is used]
    mapping(bytes32 => bool) public signatureIsUsed;

    event Renewal(uint256 nftTokenId, uint256 usdtAmount);

    function initialize(
        address backendSigner_, address unitTokenAddress_, address renewalDestination_
    ) initializer public {
        __ERC721_init("BONX", "BONX NFT");
        __Ownable_init(msg.sender);

        _nextTokenId = 1;        // Skip 0 as tokenId
        unitTokenAddress = unitTokenAddress_;
        backendSigner = backendSigner_;
        signatureValidTime = 3 minutes;
        renewalDestination = renewalDestination_;
    }

    modifier onlySigner() {
        require(_msgSender() == backendSigner, "Only signer can call this function!");
        _;
    }
    
    /* ============================ Signature =========================== */
    function disableSignatureMode() public virtual pure returns (bool) {
        return false;       // Override this for debugging in the testnet
    }

    function consumeSignature(
        bytes4 selector,
        uint256 amount,
        address user,
        uint256 timestamp,
        bytes memory signature
    ) public {
        // Prevent replay attack
        bytes32 sigHash = keccak256(signature);
        require(!signatureIsUsed[sigHash], "Signature already used!");
        signatureIsUsed[sigHash] = true;

        // Check the signature timestamp
        require(block.timestamp <= timestamp + signatureValidTime, "Signature expired!");
        require(block.timestamp >= timestamp, "Timestamp error!");

        // Check the signature content
        bytes memory data = abi.encodePacked(selector, amount, user, timestamp);
        bytes32 signedMessageHash = MessageHashUtils.toEthSignedMessageHash(data);
        address signer = ECDSA.recover(signedMessageHash, signature);
        require(signer == backendSigner || disableSignatureMode(), "Signature invalid!");
    }


    /* ========================= View functions ========================= */
    function getNextTokenId() public view returns (uint256) {
        return _nextTokenId;
    }

    function getBonxName(uint256 tokenId) public view returns (string memory) {
        return _bonxNames[tokenId];
    }


    /* ========================= Write functions ======================== */

    /* ----------- For Backend Signer ----------- */
    function safeMint(address to, string memory name) public onlySigner returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _bonxNames[tokenId] = name;
        _safeMint(to, tokenId);
        return tokenId;
    }

    function retrieveNFT(uint256 tokenId) public onlySigner {
        _transfer(ownerOf(tokenId), backendSigner, tokenId);
    }

    /* ---------------- For Admin --------------- */
    function setBackendSigner(address newBackendSigner) public onlyOwner {
        backendSigner = newBackendSigner;
    }

    function setRenewalDestination(address newRenewalDestination) public onlyOwner {
        renewalDestination = newRenewalDestination;
    }

    /* ---------------- For Owner --------------- */
    function renewal(
        uint256 nftTokenId, 
        uint256 usdtAmount,
        uint256 timestamp,
        bytes memory signature
    ) public {
        // Check the signature
        consumeSignature(
            this.renewal.selector, usdtAmount, _msgSender(), timestamp, signature
        );

        // Update storage, transfer token and emit event
        IERC20(unitTokenAddress).transferFrom(_msgSender(), renewalDestination, usdtAmount);
        emit Renewal(nftTokenId, usdtAmount);
    }

}
