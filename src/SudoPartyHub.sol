// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Interfaces/ISudoParty.sol";
import "./Interfaces/ISudoPartyManager.sol";

import "./Interfaces/IPartyFactory.sol";
import "./Interfaces/IManagerFactory.sol";

import "openzeppelin/token/ERC721/IERC721.sol";
import "openzeppelin/utils/Strings.sol";

/// @title SudoParty Hub
/// @author Autocrat
/// @notice creates & routes SudoParties
contract SudoPartyHub {

    /*///////////////////////////////////////////////////////////////
                            INITIALIZATION
    //////////////////////////////////////////////////////////////*/ 

    /// @notice SudoParty Factory
    IPartyFactory public immutable party_factory;

    /// @notice SudoParty Manager Factory
    IManagerFactory public immutable manager_factory;

    constructor(address p_factory, address m_factory) {
        party_factory = IPartyFactory(p_factory);

        manager_factory = IManagerFactory(m_factory);
    }

    /// @notice SudoParty => SudoParty's Manager
    mapping (ISudoParty => ISudoPartyManager) public manager;

    /*///////////////////////////////////////////////////////////////
                            SUDOPARTY CREATION
    //////////////////////////////////////////////////////////////*/ 

    function startParty(
        address[] memory whitelist,
        uint deadline,
        uint consensus,
        address factory,
        address router,
        address pool, 
        address nft, 
        uint id
    ) public returns (address _party) {
        IERC721 _nft = IERC721(nft);

        require(_nft.ownerOf(id) == pool, "NOT_LISTED");

        (string memory name, string memory symbol) = tokenName(_nft, id);

        _party = party_factory.createParty(
            name,
            symbol,
            whitelist, 
            deadline, 
            consensus, 
            factory, 
            router, 
            pool, 
            nft, 
            id
        );

        ISudoParty sudoparty = ISudoParty(_party);

        address _manager = manager_factory.createManager(name, symbol, _party);

        manager[sudoparty] = ISudoPartyManager(_manager);

        sudoparty.setManager(_manager);
    }

    /// @notice creates fractional token name and symbol
    function tokenName(IERC721 nft, uint id) public view returns (string memory name, string memory symbol) {
        // e.g. CRYPTOPUNKS#6529 Fraction
        name = string(abi.encodePacked(IERC721(nft).name(), "#",Strings.toString(id), " Fraction"));

        // e.g. Ͼ#6529
        symbol = string(abi.encode(IERC721(nft).symbol(), "#",Strings.toString(id)));
    }

    /*///////////////////////////////////////////////////////////////
                              SUDOPARTY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function whitelistAdd(address payable party, address new_contributor) public {
        /* address sender = msg.sender; */

        ISudoParty(party).whitelistAdd(/* sender, */ new_contributor);
    }

    function openParty(address payable party) public {
        /* address sender = msg.sender; */

        ISudoParty(party).openParty(/* sender */);
    }

    function contribute(address payable party) public payable {
        /* address sender = msg.sender; */

        ISudoParty(party).contribute{value: msg.value}(/* sender */);
    }

    function buy(address payable party) public payable {
        ISudoParty(party).buy();
    }

    function finalize(address payable party) public {
        ISudoParty(party).finalize();
    }

    function claim(address payable party, address contributor) public {
        ISudoParty(party).claim(contributor);
    }

    /*///////////////////////////////////////////////////////////////
                            SUDOPARTY MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    function stake(address payable party, uint amount) public {
        /* address sender = msg.sender; */

        manager[ISudoParty(party)].stake(/* sender, */ amount);
    }

    function unstake(address payable party, uint amount) public {
        /* address sender = msg.sender; */

        manager[ISudoParty(party)].unstake(/* sender, */ amount);
    }

    function createProposal(
        address payable party, 
        ISudoPartyManager.ProposalType _type, 
        uint amount,
        address withdrawal
    ) public {
        /* address sender = msg.sender; */

        manager[ISudoParty(party)].createProposal(/* sender, */ _type, amount, withdrawal);
    }

    function vote(
        address payable party,
        uint id,
        bool yes
    ) public {
        /* address sender = msg.sender; */

        manager[ISudoParty(party)].vote(/* sender, */ id, yes);
    }

    function finalizeProposal(address payable party, uint id) public {
        manager[ISudoParty(party)].finalize(id);
    }

    function withdraw(address payable party, address withdrawal) public {
        /* address sender = msg.sender; */

        manager[ISudoParty(party)].withdraw(/* sender, */ withdrawal);
    }
}