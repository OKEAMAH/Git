pragma solidity ^0.8.17;
contract A {
    function call() public {
        A callee = A(address(this));
        callee.call();
    }
}