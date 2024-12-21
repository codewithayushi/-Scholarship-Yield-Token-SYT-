// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ScholarshipYieldToken {
    string public name = "ScholarshipYieldToken";
    string public symbol = "SYT";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    address public admin;

    struct Scholarship {
        address student;
        uint256 tokenAmount;
        uint256 unlockTime;
        bool claimed; // To track if tokens are claimed
    }

    Scholarship[] public scholarships;

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    function mint(address to, uint256 amount) external onlyAdmin {
        require(to != address(0), "Cannot mint to zero address");
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        require(to != address(0), "Cannot transfer to zero address");
        
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Allowance exceeded");
        require(to != address(0), "Cannot transfer to zero address");

        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;

        emit Transfer(from, to, amount);
        return true;
    }

    function createScholarship(
        address student,
        uint256 tokenAmount,
        uint256 unlockTime
    ) external onlyAdmin {
        require(student != address(0), "Invalid student address");
        require(balanceOf[admin] >= tokenAmount, "Insufficient tokens in admin balance");
        
        // Deduct tokens from admin and allocate to student
        balanceOf[admin] -= tokenAmount;
        balanceOf[student] += tokenAmount;

        // Emit a transfer event for visibility
        emit Transfer(admin, student, tokenAmount);

        // Record the scholarship
        scholarships.push(Scholarship(student, tokenAmount, unlockTime, false));
    }

    function getScholarships() external view returns (Scholarship[] memory) {
        return scholarships;
    }

    function claimTokens(uint256 scholarshipId) external {
        require(scholarshipId < scholarships.length, "Invalid scholarship ID");
        Scholarship storage scholarship = scholarships[scholarshipId];
        require(msg.sender == scholarship.student, "Only the student can claim tokens");
        require(block.timestamp >= scholarship.unlockTime, "Tokens are locked");
        require(!scholarship.claimed, "Tokens already claimed");

        // Transfer tokens to the student
        scholarship.claimed = true; // Mark as claimed
        emit Transfer(admin, scholarship.student, scholarship.tokenAmount);
    }
}
