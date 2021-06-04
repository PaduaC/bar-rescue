// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.1;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract BarOwners {
    using SafeMath for uint256;
    struct Owner {
        address addr;
        uint256 id;
        string name;
        uint256 equity;
    }

    // For investment period
    enum State {INACTIVE, ACTIVE}

    // What to do
    // 1. Equity
    // 2. Opt-out of ownership
    // 3. Realocate equity

    State public state;
    uint256 public nextOwnerId;
    uint256 public totalEquity;
    uint256 public availableFunds;
    uint256 public remainingFunds;
    string public barName;
    uint256 private startupCost;
    uint256 private end;

    uint256[] public ownerList;

    mapping(address => uint256) public shares;
    mapping(uint256 => Owner) public owners;
    mapping(address => bool) public isOwner;

    event NewOwner(
        address indexed addr,
        uint256 indexed id,
        string name,
        uint256 equity
    );

    constructor(
        string memory _barName,
        uint256 _startupCost,
        uint256 _investmentTime
    ) {
        barName = _barName;
        startupCost = _startupCost;
        end = block.timestamp.add(_investmentTime);
        state = State.INACTIVE;
    }

    function getOwners() external view returns (Owner[] memory) {
        Owner[] memory _owners = new Owner[](ownerList.length);
        for (uint256 i = 0; i < _owners.length; i++) {
            _owners[i] = Owner(
                owners[ownerList[i]].addr,
                owners[ownerList[i]].id,
                owners[ownerList[i]].name,
                owners[ownerList[i]].equity
            );
        }
        return _owners;
    }

    function createNewOwner(string calldata _name) external payable {
        require(
            msg.value > 0 && msg.value <= startupCost,
            "Must contribute to investment"
        );
        owners[nextOwnerId] = Owner(msg.sender, nextOwnerId, _name, 0);
        _invest(msg.value);
        emit NewOwner(
            msg.sender,
            nextOwnerId,
            _name,
            owners[nextOwnerId].equity
        );
        _addOwner(msg.sender, nextOwnerId, _name, owners[nextOwnerId].equity);

        nextOwnerId++;
    }

    function _addOwner(
        address _ownerAddr,
        uint256 _id,
        string memory _name,
        uint256 _equity
    ) internal {
        owners[_id] = Owner(_ownerAddr, _id, _name, _equity);
        ownerList.push(_id);
    }

    function _invest(uint256 _amount) internal {
        require(block.timestamp < end, "Cannot invest after investment period");
        require(
            _amount <= startupCost && _amount <= startupCost.sub(totalEquity),
            "Amount must be <= startupCost"
        );
        isOwner[msg.sender] = true;
        shares[msg.sender] = owners[nextOwnerId].equity = owners[nextOwnerId]
            .equity
            .add(_amount);
        totalEquity = totalEquity.add(_amount);
        availableFunds = availableFunds.add(_amount);
        remainingFunds = startupCost.sub(availableFunds);
    }

    // Idk what im doing with this right now
    // Should be helpful for later functions
    modifier ownerOnly() {
        require(isOwner[msg.sender] == true, "Must be bar owner");
        _;
    }
}
