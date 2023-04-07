// SPDX-License-Identifier: MIT

pragma solidity >=0.8.2 <0.9.0;
contract Loop {
    uint256 count;
    function loop(uint256 iter) public {
        // for loop
        for (uint256 i = 0; i < iter; i++) {
        count += 1;
        }

    }
}