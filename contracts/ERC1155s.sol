// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "./ERC20s.sol";

/// @notice ERC1155s is ERC1155 with several ERC20 tokens linked to IDs
/// @author k0rean_rand0m (twitter.com/k0rean_rand0m). Based on Solmate by t11s (twitter.com/transmissions11)
/// @dev in this contract safety checks are removed from safeTransfers because NFTs should follow corresponding ERC20s flow
///      and might be retrieved with ERC20s tokens from contracts that don't support NFT receiving.
abstract contract ERC1155s {

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                           ERC1155s STORAGE
   //////////////////////////////////////////////////////////////*/

    // @dev ERC1155s id to ERC20s
    mapping(uint256 => ERC20s) public idToErc20s;
    // @dev ERC1155s id to supply
    mapping(uint256 => uint256) public totalSupply;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {

        // If msg.sender is not linked ERC20s token, auth
        ERC20s linkedToken = idToErc20s[id];
        if(msg.sender != address(linkedToken)) {
            require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");
            // If there is a linked ERC20s token, transfer it
            if(address(linkedToken) != address(0)) {
                linkedToken.transferFrom(from, to, amount);
            }
        }

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);
    }

    // @dev this function will never be used as a callback by ERC20s
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // If there is a linked ERC20s token, transfer it
            ERC20s linkedToken = idToErc20s[id];
            if(address(linkedToken) != address(0)) {
                linkedToken.transferFrom(from, to, amount);
            }

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);
    }

    function balanceOfBatch(
        address[] calldata owners,
        uint256[] calldata ids
    ) public view virtual returns (uint256[] memory balances){
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
        interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
        interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
        interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                       INTERNAL ERC20s LINK LOGIC
    //////////////////////////////////////////////////////////////*/

    // @dev it's preferably to create ERC20s before minting corresponding ERC1155s id
    function _createErc20s (
        uint256 id,
        string calldata name,
        string calldata symbol
    ) internal virtual returns(ERC20s) {
        require(address(idToErc20s[id]) == address(0), "ID_IS_LINKED");
        ERC20s token = new ERC20s(id, name, symbol);
        return token;
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        ERC20s linkedToken = idToErc20s[id];
        if(address(linkedToken) != address(0)) {
            linkedToken.transferFrom(address(0), to, amount);
        }

        emit TransferSingle(msg.sender, address(0), to, id, amount);
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            ERC20s linkedToken = idToErc20s[ids[i]];
            if(address(linkedToken) != address(0)) {
                linkedToken.transferFrom(address(0), to, amounts[i]);
            }

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            ERC20s linkedToken = idToErc20s[ids[i]];
            if(address(linkedToken) != address(0)) {
                linkedToken.transferFrom(from, address(0), amounts[i]);
            }

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        balanceOf[from][id] -= amount;

        ERC20s linkedToken = idToErc20s[id];
        if(address(linkedToken) != address(0)) {
            linkedToken.transferFrom(from, address(0), amount);
        }

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }

}