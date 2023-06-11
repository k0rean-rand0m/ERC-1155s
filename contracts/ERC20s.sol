// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "../interfaces/IERC1155s.sol";

contract ERC20s {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;
    string public symbol;
    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                             ERC20s STORAGE
    //////////////////////////////////////////////////////////////*/

    IERC1155s public immutable LINKED_1155S;
    uint256 public immutable LINKED_ID;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        uint256 _linkedId,
        string memory _name,
        string memory _symbol
    ) {
        name = _name;
        symbol = _symbol;
        LINKED_ID = _linkedId;
        LINKED_1155S = IERC1155s(msg.sender);
        decimals = 0;
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalSupply() public virtual returns(uint256) {
        return LINKED_1155S.totalSupply(LINKED_ID);
    }

    function balanceOf(
        address account
    ) public virtual returns(uint256) {
        return LINKED_1155S.balanceOf(account, LINKED_ID);
    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // @dev transfer is never used by ERC1155s
    function transfer(address to, uint256 amount) public virtual returns (bool) {
        LINKED_1155S.safeTransferFrom(msg.sender, to, LINKED_ID, amount, "");
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        if (msg.sender != address(LINKED_1155S)) {
            uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.
            if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;
            LINKED_1155S.safeTransferFrom(from, to, LINKED_ID, amount, "");
        }
        emit Transfer(from, to, amount);
        return true;
    }
}