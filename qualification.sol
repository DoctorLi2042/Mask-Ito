// SPDX-License-Identifier: MIT

/**
 * @author          Yisi Liu
 * @contact         yisiliu@gmail.com
 * @author_time     01/06/2021
**/

pragma solidity >= 0.8.0;

import "./IQLF.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract QLF_Parasset is IQLF, Ownable {
    uint256 start_time;
    mapping(address => bool) whitelist_list;
    // chance to be selected as a lucky user, 4 levels supported:
    //      0 : 100%, actually, lucky draw feature disabled
    //      1 : 75% chance
    //      2 : 50% chance
    //      3 : 25% chance
    //      Others : 0%, do NOT use
    // TODO, improve it, 8 bits (0~255) -> (0% ~ 100%)
    uint8 public lucky_factor;

    constructor (uint256 _start_time, uint8 _lucky_factor) {
        start_time = _start_time;
        lucky_factor = _lucky_factor;
    }

    function get_start_time() public view returns (uint256) {
        return start_time;
    }

    function set_start_time(uint256 _start_time) public onlyOwner {
        start_time = _start_time;
    }
    
    function set_lucky_factor(uint8 _lucky_factor) public onlyOwner {
        lucky_factor = _lucky_factor;
    }

    function isQualified(address account)
        public view
        returns (
            bool qualified
        )
    {
        if (start_time > block.timestamp) {
            return false; 
        }
        if (!whitelist_list[account]) {
            return false; 
        }
        return true;  
        
    }

    function ifQualified(address account, bytes32[] memory data)
        public
        view
        override
        returns (
            bool qualified,
            string memory errorMsg
        )
    {
        if (start_time > block.timestamp) {
            return (false, "not started"); 
        }
        if (!whitelist_list[account]) {
            return (false, "not whitelisted"); 
        }
        return (true, "");
    } 

    function add_white_list(address[] memory addrs) external onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            whitelist_list[addrs[i]] = true;
        }
    }

    function remove_white_list(address[] memory addrs) external onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            whitelist_list[addrs[i]] = false;
        }
    }

    function logQualified(address account, bytes32[] memory data)
        public
        override
        returns (
            bool qualified,
            string memory errorMsg
        )
    {
        if (start_time > block.timestamp) {
            return (false, "not started"); 
        }
        if (!whitelist_list[account]) {
            return (false, "not whitelisted"); 
        }
        emit Qualification(account, true, block.number, block.timestamp);
        return (true, "");
    } 

    function supportsInterface(bytes4 interfaceId) external override pure returns (bool) {
        return interfaceId == this.supportsInterface.selector || 
            interfaceId == (this.ifQualified.selector ^ this.logQualified.selector) ||
            interfaceId == this.get_start_time.selector;
    }
    
    /**
     * isLucky() test if an account is lucky
     * account                   address of the account
    **/
    function isLucky(address account) public view returns (bool) {
        if (lucky_factor == 0) {
            return true;
        }
        uint256 blocknumber = block.number;
        uint256 random_block = blocknumber - 1 - uint256(
            keccak256(abi.encodePacked(blockhash(blocknumber-1), account))
        ) % 255;
        bytes32 sha = keccak256(abi.encodePacked(blockhash(random_block), account, block.coinbase, block.difficulty));
        return ((uint8(sha[0]) & 0x03) >= lucky_factor);
    }
}
