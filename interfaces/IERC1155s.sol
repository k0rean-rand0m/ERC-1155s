// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

interface IERC1155s {
    function totalSupply(uint256 id) external returns (uint256);
    function balanceOf(address account, uint256 id) external returns (uint256);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
}
