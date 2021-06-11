// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// For paying employees
contract Payroll {
    using SafeMath for uint256;

    struct Employee {
        uint256 id;
        address addr;
        string name;
        string title;
    }

    address public admin;
    uint256 public nextEmployeeId;
    Employee[] public employeeList;
    mapping(uint256 => Employee) public employees;

    event NewEmployee(
        uint256 id,
        address indexed addr,
        string name,
        string title
    );

    event EmployeePaid(uint256 id, address indexed addr, uint256 amount);

    constructor() {
        admin = msg.sender;
    }

    function getEmployees() external view returns (Employee[] memory) {
        Employee[] memory _employees = new Employee[](employeeList.length);
        for (uint256 i = 0; i < _employees.length; i++) {
            _employees[i] = Employee(
                employees[employeeList[i].id].id,
                employees[employeeList[i].id].addr,
                employees[employeeList[i].id].name,
                employees[employeeList[i].id].title
            );
        }
        return _employees;
    }

    // Only the owners can call functions on this smart contract
    function addNewEmployee(
        address _addr,
        string memory _name,
        string memory _title
    ) external adminOnly {
        employees[nextEmployeeId] = Employee(
            nextEmployeeId,
            _addr,
            _name,
            _title
        );
        emit NewEmployee(nextEmployeeId, _addr, _name, _title);
        employeeList.push(employees[nextEmployeeId]);
        nextEmployeeId.add(1);
    }

    function payEmployee(uint256 _id, uint256 _amount)
        external
        payable
        adminOnly
    {
        payable(employees[_id].addr).transfer(_amount);
        emit EmployeePaid(employees[_id].id, employees[_id].addr, _amount);
    }

    function removeEmployee(uint256 _id) external adminOnly {
        for (uint256 i = _id; i < employeeList.length; i++) {
            employeeList[i] = employeeList[i.add(1)];
        }
        delete employeeList[employeeList.length.sub(1)];
        employeeList.pop();
    }

    modifier adminOnly() {
        require(admin == msg.sender, "Admin only");
        _;
    }
}
