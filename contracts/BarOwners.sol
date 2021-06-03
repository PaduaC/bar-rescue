// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.1;

contract BarOwners {
    struct Owner {
        address addr;
        uint256 id;
        string name;
        uint256 equity;
    }

    uint256 public nextOwnerId;
    uint256 public totalEquity;
    uint256 public availableFunds;
    uint256 public remainingFunds;
    string public barName;
    uint256 public startupCost;
    uint256 private end;

    mapping(address => uint256) public shares;
    mapping(uint256 => Owner) public owners;
    mapping(address => bool) public isOwner;

    constructor(
        string memory _barName,
        uint256 _startupCost,
        uint256 _investmentTime
    ) {
        barName = _barName;
        startupCost = _startupCost;
        end = block.timestamp + _investmentTime;
    }

    function newOwner(string calldata _name) external payable {
        require(
            msg.value > 0 && msg.value <= startupCost,
            "Must contribute to investment"
        );
        owners[nextOwnerId] = Owner(msg.sender, nextOwnerId, _name, 0);
        _invest(msg.value);
        nextOwnerId++;
    }

    function _invest(uint256 _amount) internal {
        require(block.timestamp < end, "Cannot invest after investment period");
        require(
            _amount <= startupCost && _amount <= startupCost - totalEquity,
            "Amount must be <= startupCost"
        );
        isOwner[msg.sender] = true;
        shares[msg.sender] = owners[nextOwnerId].equity += _amount;
        remainingFunds = startupCost - _amount;
        totalEquity += _amount;
        availableFunds += _amount;
    }

    // Idk what im doing with this right now
    // Should be helpful for later functions
    modifier ownerOnly() {
        require(isOwner[msg.sender] == true, "Must be bar owner");
        _;
    }
}
