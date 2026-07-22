// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {MexiMonstersNFT} from "../src/MexiMonstersNFT.sol";

contract DeployNFT is Script {

    MexiMonstersNFT public nft;

    address owner = 0xca067E20db2cDEF80D1c7130e5B71C42c0305529;
    string baseURI = "";
    uint256 maxSupply = 2000;
    uint256 mintPrice = 0;
    uint256 updateLorePrice = 0;

    // function setUp() public {}

    function run() public returns(MexiMonstersNFT, address) {
        vm.startBroadcast();

        nft = new MexiMonstersNFT(baseURI, owner, maxSupply, mintPrice, updateLorePrice);

        vm.stopBroadcast();

        return (nft, nft.owner());
    }

}