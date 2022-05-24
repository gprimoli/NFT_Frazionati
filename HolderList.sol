// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "https://github.com/bokkypoobah/BokkyPooBahsRedBlackTreeLibrary/blob/master/contracts/BokkyPooBahsRedBlackTreeLibrary.sol";

contract HolderList {
    using BokkyPooBahsRedBlackTreeLibrary for BokkyPooBahsRedBlackTreeLibrary.Tree;
    BokkyPooBahsRedBlackTreeLibrary.Tree sortedList;

    mapping(uint256 => address[]) values; //Balance => Owners;

    constructor (address firstOwner, uint256 balance){
        sortedList.insert(balance);
        values[balance].push(firstOwner);
    }

    function getAllRichest() view external returns (address[] memory owner){
        return values[sortedList.last()];
    }

    function getFirstRichest() view external returns (address owner){
        return values[sortedList.last()][0];
    }

    function transact(address fOwner, uint256 oldfBalance, uint256 newfBalance, address tOwner, uint256 oldtBalance, uint256 newtBalance) external {
        require(fOwner != tOwner, "You can't do that");
        remove(oldfBalance, fOwner);
        remove(oldtBalance, tOwner);

        insert(newfBalance, fOwner);
        insert(newtBalance, tOwner);
    }

    function insert(uint256 balance, address owner) internal {
        if (balance > 0) {
            if (!sortedList.exists(balance))
                sortedList.insert(balance);
            values[balance].push(owner);
        }
    }

    function remove(uint256 balance, address owner) internal {
        if (balance > 0) {
            require(sortedList.exists(balance), "You can't remove this element");
            uint256 pos = getPosByOwner(balance, owner);

            swap(balance, pos, values[balance].length - 1);
            values[balance].pop();

            if (values[balance].length == 0)
                sortedList.remove(balance);
        }
    }

    function swap(uint256 key, uint256 fpos, uint256 tpos) internal {
        address tmp;
        tmp = values[key][fpos];
        values[key][fpos] = values[key][tpos];
        values[key][tpos] = tmp;
    }

    function getPosByOwner(uint256 key, address owner) view internal returns (uint256 pos) {
        for (uint256 i = 0; i < values[key].length; i++)
            if (values[key][i] == owner)
                return i;
    }

}
