// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {MexiMonstersNFT} from "../src/MexiMonstersNFT.sol";

contract MexiMonstersNFTScript is Script {
    MexiMonstersNFT public nft;

    address owner = makeAddr("owner");
    string baseURI = "";
    uint256 maxSupply = 5;
    uint256 mintPrice = 0.005 ether;
    uint256 updateLorePrice = 0.001 ether;

    // function setUp() public {}

    function run() public returns(MexiMonstersNFT, address) {
        vm.startBroadcast();

        nft = new MexiMonstersNFT(baseURI, owner, maxSupply, mintPrice, updateLorePrice);

        vm.stopBroadcast();

        return (nft, nft.owner());
    }
}
