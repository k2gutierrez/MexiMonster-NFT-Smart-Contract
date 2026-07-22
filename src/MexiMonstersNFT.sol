// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ERC721A} from "../lib/ERC721A/contracts/ERC721A.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {Base64} from "../lib/openzeppelin-contracts/contracts/utils/Base64.sol";
import {Strings} from "../lib/openzeppelin-contracts/contracts/utils/Strings.sol";

/**
 * @title Mexican Monsters NFTs
 * @author Carlos Gutiérrez
 * @notice ERC721A Dynamic NFTs with Manual Day/Night Toggle and On-Chain Metadata
 */
contract MexiMonstersNFT is ERC721A, Ownable {
    // Library for uint256 to string for metadata
    using Strings for uint256;

    // Custom errors
    error MexiMonstersNFT__ExceedsMaxSupply();
    error MexiMonstersNFT__InsufficientPayment();
    error MexiMonstersNFT__NotTheOwner();
    error MexiMonstersNFT__TokenDoesNotExist();
    error MexiMonstersNFT__NoSupply();

    // Types of mexican steriotypes
    enum Archetype {
        Godinez,
        Mirrey,
        Buchon
    }

    // Gender of the NFT
    enum Gender {
        Male,
        Female
    }

    // Struct Monster
    struct MonsterState {
        bool isNight;
        Archetype archetype;
        Gender gender;
        string customLore;
    }

    string private s_baseTokenURI;
    uint256 private s_mintPrice;
    uint256 private s_maxSupply;
    uint256 private s_updateLorePrice;

    // Mapping from token ID to Monster State
    mapping(uint256 tokenId => MonsterState state) private s_tokenStates;

    // Events for Opensea
    event MetadataUpdate(uint256 _tokenId);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
    
    constructor(string memory baseURI, address _initialOwner, uint256 _maxSupply, uint256 _mintPrice, uint256 _updateLorePrice) ERC721A("MexiMonsters", "MXM") Ownable(_initialOwner) {
        s_baseTokenURI = baseURI;
        s_maxSupply = _maxSupply;
        s_mintPrice = _mintPrice;
        s_updateLorePrice = _updateLorePrice;
    }

    /**
     * @dev Mint function for the Mexican Monsters NFTs.
     * @param quantity Amount of tokens to purchase.
     * @param archetype Type of NFT archetype.
     * @param gender Gender of the NFTs to purchase.
     */
    function mint(uint256 quantity, Archetype archetype, Gender gender) external payable {
        if (totalSupply() + quantity > getMaxSupply()) revert MexiMonstersNFT__ExceedsMaxSupply();
        if (msg.value < getMintPrice() * quantity) revert MexiMonstersNFT__InsufficientPayment();

        uint256 startTokenId = _nextTokenId();

        _safeMint(msg.sender, quantity);

        for (uint256 i = 0; i < quantity;) {
            s_tokenStates[startTokenId + i] = MonsterState({
                isNight: false, // Starts in Day mode by default
                archetype: archetype,
                gender: gender,
                customLore: ""
            });
            unchecked { i++; }
        }
    }

    /**
     * @notice Allows the NFT owner to manually toggle between Day and Night for NFTs image change!
     * @dev Emits ERC-4906 MetadataUpdate so OpenSea updates the image automatically.
     */
    function toggleDayNight(uint256 tokenId) external {
        if (!_exists(tokenId)) revert MexiMonstersNFT__TokenDoesNotExist();
        if (ownerOf(tokenId) != msg.sender) revert MexiMonstersNFT__NotTheOwner();

        // Flip the boolean (if true becomes false, if false becomes true).
        s_tokenStates[tokenId].isNight = !s_tokenStates[tokenId].isNight;

        // Tell OpenSea to refresh the metadata and image!
        emit MetadataUpdate(tokenId);
    }

    /**
     * @dev Updates the message in the NFT image.
     * @param tokenId Token Id.
     * @param newLore New message to add as Image.
     */
    function updateMonsterLore(uint256 tokenId, string calldata newLore) external payable {
        if (!_exists(tokenId)) revert MexiMonstersNFT__TokenDoesNotExist();
        if (ownerOf(tokenId) != msg.sender) revert MexiMonstersNFT__NotTheOwner();
        
        bytes memory loreBytes = bytes(newLore);
        require(loreBytes.length < 32, "Lore too long, 32 chars max.");

        if (msg.value < getUpdateLorePrice()) revert MexiMonstersNFT__InsufficientPayment();

        s_tokenStates[tokenId].customLore = newLore;

        emit MetadataUpdate(tokenId);
    }

    /**
     * @dev Only owner function to refresh all Metadata manually / Mainly for Opensea when deployed on mainnet
     * we are looking to have the NFTs images changes acording to day and night time.
     */
    function refreshAllMetadata() external onlyOwner {
        uint256 total = totalSupply();
        if (total > 0) {
            emit BatchMetadataUpdate(1, total);
        } else {
            revert MexiMonstersNFT__NoSupply();
        }
    }

    /**
     * @dev Only owner function to change the baseURI.
     * @param newBaseURI new baseURI.
     */
    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        s_baseTokenURI = newBaseURI;
        uint256 total = totalSupply();
        if (total > 0) {
            emit BatchMetadataUpdate(1, total);
        }
    }

    /**
     * @dev Used to change the lore price update, only owner function.
     * @param newPrice New price for lore update. Can be used to prevent spam in blockchain.
     */
    function setUpdateLorePrice(uint256 newPrice) external onlyOwner {
        s_updateLorePrice = newPrice;
    }

    /**
     * @dev Only owner function to withdraw funds from the smart contract.
     */
    function withdraw() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Transfer Failed");
    }

    /**
     * @dev Only owner function to change the mint price.
     * @param newPrice new mint price.
     */
    function setMintPrice(uint256 newPrice) external onlyOwner {
        s_mintPrice = newPrice;
    }

    /**
     * @dev Override internal function to set the _baseURI.
     */
    function _baseURI() internal view override returns(string memory) {
        return s_baseTokenURI;
    }

    /**
     * @dev Override internal function to set the _startTokenId to 1 instead of 0.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * 
     * @param interfaceId interface Idß
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A) returns (bool) {
        return interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
    }

    /**
     * @notice Generates dynamic on-chain JSON metadata with a composite SVG image containing the lore.
     * @param tokenId Token ID
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert MexiMonstersNFT__TokenDoesNotExist();
        MonsterState memory state = s_tokenStates[tokenId];
        
        string memory imageURI = getArdriveImageURI(tokenId);
        string memory archetypeStr = _getArchetypeString(state.archetype);
        string memory genderStr = _getGenderString(state.gender);
        string memory timeStr = state.isNight ? "Night" : "Day";
        
        // --- 1. DYNAMIC SVG GENERATION ---
        bytes memory svgStart = abi.encodePacked(
            '<svg width="1000" height="1000" xmlns="http://www.w3.org/2000/svg">',
            '<image href="', imageURI, '" width="1000" height="1000" x="0" y="0"/>'
        );

        bytes memory svgTextOverlay = "";
        if (bytes(state.customLore).length > 0) {
            
            // Dynamic styling based on Day/Night state
            string memory bannerColor = state.isNight ? "rgba(0,0,0,0.8)" : "rgba(255,255,255,0.85)";
            string memory textColor = state.isNight ? "#8A0303" : "#000000"; // Bloody Red for Night, Black for Day
            
            // Constructs the banner and text with the dynamic colors
            svgTextOverlay = abi.encodePacked(
                '<rect x="150" y="860" width="700" height="80" fill="', bannerColor, '" rx="20"/>', 
                '<text x="500" y="910" font-family="Verdana, sans-serif" font-size="32" font-weight="bold" fill="', textColor, '" text-anchor="middle">', 
                state.customLore, 
                '</text>'
            );
        }
        
        bytes memory finalSVG = abi.encodePacked(svgStart, svgTextOverlay, '</svg>');
        
        // Convert the full SVG element into a Base64 Image URI
        string memory b64Image = string(
            abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(finalSVG))
        );

        // --- 2. METADATA JSON GENERATION ---
        bytes memory attributes = abi.encodePacked(
            '[',
            '{"trait_type": "Archetype", "value": "', archetypeStr, '"},',
            '{"trait_type": "Gender", "value": "', genderStr, '"},',
            '{"trait_type": "Time of Day", "value": "', timeStr, '"}'
        );

        if (bytes(state.customLore).length > 0) {
            attributes = abi.encodePacked(
                attributes,
                ',{"trait_type": "Custom Lore", "value": "', state.customLore, '"}'
            );
        }
        attributes = abi.encodePacked(attributes, ']');

        bytes memory json = abi.encodePacked(
            '{"name": "MexiMonster #', tokenId.toString(), '",',
            '"description": "Dynamic Mexican Monster NFT with on-chain SVG compositing and Ardrive storage.",',
            '"image": "', b64Image, '",', 
            '"attributes": ', attributes,
            '}'
        );

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(json)));
    }

    /**
     * @dev Internal function to get the Arche Type as String for metadata.
     * @param archetype Arche type from enum.
     */
    function _getArchetypeString(Archetype archetype) internal pure returns (string memory) {
        if (archetype == Archetype.Godinez) return "Godinez";
        if (archetype == Archetype.Mirrey) return "Mirrey";
        return "Buchon";
    }

    /**
     * @dev Gets the gender as string.
     * @param gender Gender from enum.
     */
    function _getGenderString(Gender gender) internal pure returns (string memory) {
        if (gender == Gender.Male) return "Male";
        return "Female";
    }

    /**
     * @dev Gets the Ardrive image URI
     * @param tokenId Token Id
     */
    function getArdriveImageURI(uint256 tokenId) public view returns (string memory) {
        MonsterState memory state = s_tokenStates[tokenId];
        
        string[12] memory ardriveLinks = [
            "tAc9YLLZJRsKo449AjpDMRztW6IJlrnV7BVjsXQ1u7I",
            "MXfNq_WwV6NOe_zUUCiY3QzUDtwVOoXWl8eOr30nQiA",
            "aFs0Ih8C7y_xoMIjolM8uvjG246hHDIya03PRbQZzOk",
            "5f_J7bBxYJ75YOhrHV3H-YSop3nJSzWflLr8g7lCrQk",
            "hXzxmoL6nQxuInfv6lr78NdzcqzomYvm0WezVmUJSrw",
            "i3SOYsEgm7M4rbtiDJEI6P28IG9k2qBcfS0TQz9DfJc",
            "2c3jg28SaNinb725jmrAt4B6SVaatmVaRL-Qbl-vKIg",
            "kwv-yrYKbenRa3dN08SvYUIMPbDttyX8GbHo8UOZWow",
            "je4fdaCpdbT09vIX_i4JUFmz2okpBfdr34LxwN6kDNE",
            "p1o8eZTMEouwrqUwLYUO5Yb6syWbzzmit_luLF93tLI",
            "L6Py4v2wy_uw96hVvXtisSUozeBhNXtOWgdPWw2N9k4",
            "pfsI9ZDIdqKsWbXfB3tj9sGKNXmf6zvxSusM9WSfQNM"
        ];

        // 4. Calculates index using state.isNight
        uint8 index = (uint8(state.archetype) * 4) + (uint8(state.gender) * 2) + (state.isNight ? 1 : 0);
        
        return string(abi.encodePacked("https://arweave.net/", ardriveLinks[index]));
    }

    /**
     * @dev Getter function for mint price.
     */
    function getMintPrice() public view returns(uint256) {
        return s_mintPrice;
    }

    /**
     * @dev Getter function for max supply.
     */
    function getMaxSupply() public view returns(uint256) {
        return s_maxSupply;
    }

    /**
     * @dev Getter function for token State.
     * @param tokenId Token Id
     */
    function getTokenState(uint256 tokenId) external view returns(MonsterState memory) {
        if (!_exists(tokenId)) revert MexiMonstersNFT__TokenDoesNotExist();
        return s_tokenStates[tokenId];
    }

    /**
     * @dev Getter function for the update lore price.
     */
    function getUpdateLorePrice() public view returns(uint256) {
        return s_updateLorePrice;
    }
}