// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../ERC1155s.sol";
import "./helpers/Owned.sol";
import "./helpers/Strings.sol";

contract Mock1155s is ERC1155s, Owned {

    mapping(uint256 => bool) public idExists;
    uint256 private _lastId;

    constructor() Owned(msg.sender){}

    function uri(
        uint256 id
    ) public view override returns (string memory) {
        uint256 id_ = uint256(uint160(bytes20(address(this)))) + id;
        return string.concat("https://api.hexheads.io/metadata?id=", Strings.toString(id_));
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public {
        require(id != 0 && id <= _lastId, "ID_DOES_NOT_EXIST");
        _mint(to, id, amount, "");
    }

    function newId(
        bool linkErc20s,
        string calldata name,
        string calldata symbol
    ) public onlyOwner {
        _lastId += 1;
        if (linkErc20s) _createErc20s(_lastId, name, symbol);
    }

}
