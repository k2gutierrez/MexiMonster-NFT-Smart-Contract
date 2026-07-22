// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {MexiMonstersNFT} from "../src/MexiMonstersNFT.sol";
import {MexiMonstersNFTScript} from "../script/MexiMonstersNFTScript.s.sol";

contract MexiMonstersNFTTest is Test {

    // constants
    uint256 DEAL_AMOUNT = 100 ether;
    string BASE_TOKEN_IRI = "";
    uint256 MINT_PRICE = 0.005 ether;
    uint256 MAX_SUPPLY = 5;
    uint256 UPDATE_LORE_PRICE = 0.001 ether;
    
    // Main variables for test
    MexiMonstersNFT public nft;
    address owner;
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");


    function setUp() public {
        MexiMonstersNFTScript deployer = new MexiMonstersNFTScript();
        (nft, owner) = deployer.run();

        vm.deal(owner, DEAL_AMOUNT);
        vm.deal(user1, DEAL_AMOUNT);
        vm.deal(user2, DEAL_AMOUNT);
    }

    function testMint() external {
        uint256 amount = 1;
        // First token is ID 1
        uint256 tokenId = 1;
        //string memory lore = "Alcoholic crazy wolf lets go";
        vm.startPrank(user1);
        nft.mint{value: MINT_PRICE}(amount, MexiMonstersNFT.Archetype.Godinez, MexiMonstersNFT.Gender.Male);
        //nft.updateMonsterLore{value: UPDATE_LORE_PRICE}(tokenId, lore);
        nft.toggleDayNight(tokenId);
        vm.stopPrank();

        string memory metadata = nft.tokenURI(tokenId);
        console2.log(metadata);
    }

    function testMintRevertsSoldOut() external {
        uint256 amount = 5;
        vm.startPrank(user1);
        nft.mint{value: (MINT_PRICE * amount)}(amount, MexiMonstersNFT.Archetype.Godinez, MexiMonstersNFT.Gender.Male);
        vm.expectRevert(MexiMonstersNFT.MexiMonstersNFT__ExceedsMaxSupply.selector);
         nft.mint{value: (MINT_PRICE * amount)}(amount, MexiMonstersNFT.Archetype.Godinez, MexiMonstersNFT.Gender.Male);
        vm.stopPrank();
    }

    function testMintRevertsInsufficientEth() external {
        uint256 amount = 2;
        vm.startPrank(user1);
         vm.expectRevert(MexiMonstersNFT.MexiMonstersNFT__InsufficientPayment.selector);
        nft.mint{value: MINT_PRICE}(amount, MexiMonstersNFT.Archetype.Godinez, MexiMonstersNFT.Gender.Male);
        vm.stopPrank();
    }

    function testToggleDayNightRevertsTokenDoesNotExists() external {
        uint256 tokenId = 1;
        vm.prank(user1);
        vm.expectRevert(MexiMonstersNFT.MexiMonstersNFT__TokenDoesNotExist.selector);
        nft.toggleDayNight(tokenId);
    }

    function testToggleDayNightRevertsNotTheOwnerOfToken() external {
        uint256 tokenId = 1;
        uint256 amount = 1;
        vm.prank(user1);
        nft.mint{value: MINT_PRICE}(amount, MexiMonstersNFT.Archetype.Godinez, MexiMonstersNFT.Gender.Male);

        vm.prank(user2);
        vm.expectRevert(MexiMonstersNFT.MexiMonstersNFT__NotTheOwner.selector);
        nft.toggleDayNight(tokenId);

    }

    function testUpdateMonsterLoreRevertsTokenDoesNotExists() external {
        uint256 tokenId = 1;
        string memory lore = "TEST";
        vm.prank(user1);
        vm.expectRevert(MexiMonstersNFT.MexiMonstersNFT__TokenDoesNotExist.selector);
        nft.updateMonsterLore(tokenId, lore);
    }

    function testUpdateMonsterLoreRevertsNotTheOwnerOfToken() external {
        uint256 tokenId = 1;
        uint256 amount = 1;
        string memory lore = "TEST";

        vm.startPrank(user1);
        nft.mint{value: MINT_PRICE}(amount, MexiMonstersNFT.Archetype.Godinez, MexiMonstersNFT.Gender.Male);
        vm.stopPrank();
        
        vm.prank(user2);
        vm.expectRevert(MexiMonstersNFT.MexiMonstersNFT__NotTheOwner.selector);
        nft.updateMonsterLore(tokenId, lore);

    }

    function UpdateMonsterLoreRevertsExceeds32bytesLength() external {
        uint256 tokenId = 1;
        uint256 amount = 1;
        string memory lore = "12345689101112131415161718192021222324252627282930";

        vm.startPrank(user1);
        nft.mint{value: MINT_PRICE}(amount, MexiMonstersNFT.Archetype.Godinez, MexiMonstersNFT.Gender.Male);
        vm.expectRevert("Lore too long, 32 chars max.");
        nft.updateMonsterLore(tokenId, lore);
        vm.stopPrank();

        
    }

    function testRefreshAllMetadataRevertsNotOwner() external {
        vm.prank(user1);
        vm.expectRevert();
        nft.refreshAllMetadata();
    }

    function testRefreshAllMetadataRevertsNoSupply() external {
        vm.prank(owner);
        vm.expectRevert(MexiMonstersNFT.MexiMonstersNFT__NoSupply.selector);
        nft.refreshAllMetadata();
    }

    

}
