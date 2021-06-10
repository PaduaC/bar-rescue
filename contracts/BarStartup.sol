// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.1;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract BarStartup {
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
    // uint256 public totalEquity;
    uint256 public availableFunds;
    uint256 public remainingFunds;
    string public barName;
    uint256 private startupCost;
    uint256 private end;
    uint256 private remainingEquity;

    // Stores owner structs
    Owner[] public ownerList;

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
                owners[ownerList[i].id].addr,
                owners[ownerList[i].id].id,
                owners[ownerList[i].id].name,
                owners[ownerList[i].id].equity
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

    function payStartupCost() external ownerOnly afterInvestmentPeriod {
        require(availableFunds == startupCost, "Start up cost must be payed");
        startupCost = startupCost.sub(availableFunds);
        state = State.ACTIVE;
    }

    // WORK IN PROGRESS
    // This function is for situations like hostile takeovers
    function removeOwner(uint256 _id) external ownerOnly afterInvestmentPeriod {
        // I don't like have 2 for loops. It may use up a large amount of gas
        // I plan on fixing this later

        // Store owner equity in remainingEquity
        remainingEquity = remainingEquity.add(owners[_id].equity);
        // Doing this causes the former owner to give up their share in the bar
        owners[_id].equity = owners[_id].equity.sub(remainingEquity);

        for (uint256 i = _id; i < ownerList.length; i++) {
            ownerList[i] = ownerList[i.add(1)];
        }
        delete ownerList[ownerList.length.sub(1)];
        ownerList.pop();

        isOwner[owners[_id].addr] = false;

        _divideRemainingShares(_id);
    }

    // When an owner is removed
    function _divideRemainingShares(uint256 _id) internal {
        require(remainingEquity > 0, "Must have unused equity");
        require(owners[_id].addr == address(0), "Owner must be removed");
        uint256 dividend = remainingEquity.div(ownerList.length);
        for (uint256 i = 0; i < ownerList.length; i++) {
            owners[ownerList[i].id].equity = owners[ownerList[i].id].equity.add(
                dividend
            );
        }
    }

    function _addOwner(
        address _ownerAddr,
        uint256 _id,
        string memory _name,
        uint256 _equity
    ) internal {
        owners[_id] = Owner(_ownerAddr, _id, _name, _equity);
        ownerList.push(owners[_id]);
    }

    function _invest(uint256 _amount) internal {
        require(block.timestamp < end, "Cannot invest after investment period");
        // Using remainingFunds create a bug in the code
        // Using 'startupCost - availableFunds' prevents this bug
        require(
            _amount <= startupCost &&
                _amount <= startupCost.sub(availableFunds),
            "Amount must be <= remaining funds"
        );
        isOwner[msg.sender] = true;
        owners[nextOwnerId].equity = owners[nextOwnerId].equity.add(_amount);
        shares[msg.sender] = owners[nextOwnerId].equity;
        availableFunds = availableFunds.add(_amount);
        remainingFunds = startupCost.sub(availableFunds);
    }

    modifier ownerOnly() {
        require(isOwner[msg.sender] == true, "Must be bar owner");
        _;
    }

    modifier afterInvestmentPeriod() {
        require(block.timestamp > end, "Can only call after investment period");
        _;
    }
}
