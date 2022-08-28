// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "./utils/Utils.sol";

import "src/SudoParty.sol";

import "src/SudoPartyManager.sol";

import "src/Interfaces/ILSSVMPairFactory.sol";

//import "src/Interfaces/ILSSVMRouter.sol";

// forge test --match-contract SudoPartyTest --rpc-url $RINKEBY_RPC_URL --chain-id 4  -vvvv

contract SudoPartyTest is Test {

    SudoParty sudoparty;

    SudoPartyManager manager;

    ILSSVMRouter router;

    ILSSVMPairFactory factory;

    LSSVMPair pool;

    IERC721 nft;

    uint id;

    Utils internal utils;

    address payable[] internal users;

    address ryan;
    address nich;
    address owen;
    address sharelove;

    enum ProposalType {
        sell,
        set_consensus,
        withdraw
    }

    function setUp() public {
        utils = new Utils();
        users = utils.createUsers(4);

        vm.label(users[0], "Ryan");
        vm.label(users[1], "Nich");
        vm.label(users[2], "Owen");
        vm.label(users[3], "Sharelove");

        ryan = users[0];
        nich = users[1];
        owen = users[2];
        sharelove = users[3];

        router = ILSSVMRouter(0x9ABDe410D7BA62fA11EF37984c0Faf2782FE39B5);

        factory = ILSSVMPairFactory(0xcB1514FE29db064fa595628E0BFFD10cdf998F33);

        pool = LSSVMPair(0xbc1703Cc4295Acefb7FbC1Cd107146eD8AfBE4dD);

        nft = IERC721(0x9c70d80558b17a558a33F9DFe922FfF7FBf19AE2);

        id = 10;

        sudopartyWhitelist();

        contribute();
        openAndContribute();
        buy();
        finalize();
        
        claim();
        stake();
        createProposal();
    }

    function sudopartyWhitelist() public {
        uint deadline = block.timestamp + 1 days;

        address[] memory party = new address[](3);

        party[0] = ryan;
        party[1] = nich;
        party[2] = owen;

        sudoparty = new SudoParty(party, 33, deadline, router, factory, pool, nft, id);
    }

    function testWhitelist() public {
        bool ryanListed = sudoparty.whitelisted(ryan);
        bool nichListed = sudoparty.whitelisted(nich);
        bool owenListed = sudoparty.whitelisted(owen);

        assertTrue(ryanListed && nichListed && owenListed);
        assertFalse(sudoparty.whitelisted(sharelove));

        console.log("Nich, Ryan, & Owen Successfully Whitelisted");
    }

    function contribute() public {
        vm.prank(ryan);
        sudoparty.contribute{value: .5 ether}();
        console.log("Ryan contributed .5 ETH");

        vm.prank(nich);
        sudoparty.contribute{value: 1 ether}();
        console.log("Nich contributed 1 ETH");

        vm.prank(owen);
        sudoparty.contribute{value: 1 ether}();
        console.log("Owen contributed 1 ETH");

        vm.expectRevert("NOT_MEMBER");
        vm.prank(sharelove);
        sudoparty.contribute{value: 1 ether}();
        console.log("Sharelove was unable to contribute because they weren't whitelisted");
    }

    function openAndContribute() public {
        vm.prank(ryan);
        sudoparty.openParty();

        vm.prank(sharelove);
        sudoparty.contribute{value: 1 ether}();
        console.log("Sharelove contributed 1 eth");
    }

    function buy() public {
        vm.prank(ryan);
        sudoparty.buy();
        assertEq(nft.ownerOf(id), address(manager));
    }

    function finalize() public {
        sudoparty.finalize();

        manager = sudoparty.manager();

        assertTrue(nft.ownerOf(id) == address(manager));
    }

    function claim() public {
        uint _eth;
        uint _tokens;

        (_eth, _tokens) = sudoparty.claim(ryan);
        // console.log("Ryan spent ", _tokens, " ETH and received as many tokens");
        // console.log("Ryan had ", _eth, " unspent ETH returned to them");

        (_eth, _tokens) = sudoparty.claim(nich);
        // console.log("Nich spent ", _tokens, " ETH and received as many tokens");
        // console.log("Nich had ", _eth, " unspent ETH returned to them");

        (_eth, _tokens) = sudoparty.claim(owen);
        // console.log("Owen spent ", _tokens, " ETH and received as many tokens");
        // console.log("Owen had ", _eth, " unspent ETH returned to them");

        (_eth, _tokens) = sudoparty.claim(sharelove);
        // console.log("Sharelove spent ", _tokens, " ETH and received as many tokens");
        // console.log("Sharelove had ", _eth, " unspent ETH returned to them");
    }

    function stake() public {
        vm.startPrank(ryan);
        sudoparty.approve(address(manager), sudoparty.balanceOf(ryan));
        manager.stake(sudoparty.balanceOf(ryan));
        vm.stopPrank();
        //console.log("Ryan Staked");

        vm.startPrank(nich);
        sudoparty.approve(address(manager), sudoparty.balanceOf(nich));
        manager.stake(sudoparty.balanceOf(nich));
        vm.stopPrank();
        //console.log("Nich Staked");

        vm.startPrank(owen);
        sudoparty.approve(address(manager), sudoparty.balanceOf(owen));
        manager.stake(sudoparty.balanceOf(owen));
        vm.stopPrank();
        //console.log("Owen Staked");

        vm.startPrank(sharelove);
        sudoparty.approve(address(manager), sudoparty.balanceOf(sharelove));
        manager.stake(sudoparty.balanceOf(sharelove));
        vm.stopPrank();
        //console.log("Sharelove Staked");

    }

    function createProposal() public {
        vm.prank(ryan);
        manager.createProposal(SudoPartyManager.ProposalType.sell, 6 ether);
    }

    function vote() public {
        vm.prank(sharelove);
        manager.vote(1, true);

        vm.prank(owen);
        manager.vote(1, true);

        vm.prank(nich);
        manager.vote(1, true);
    }

    function testWhole() public {
        vote();
        vm.prank(ryan);
        manager.finalize(1);
        
        (,uint _price,,bool passed,uint yes,uint no,) = manager.proposal(1);

        console.log("PASSED?", passed);
        console.log("PRICE", _price);
        console.log("YES",yes);
        console.log("NO", no);
    }





}