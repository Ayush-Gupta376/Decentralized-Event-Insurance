// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract DecentralizedEventInsurance {
    struct Policy {
        uint256 policyId;
        address payable policyholder;
        string eventName;
        uint256 eventDate;
        uint256 premiumAmount;
        uint256 coverageAmount;
        bool isActive;
        bool claimSubmitted;
        bool claimApproved;
        uint256 createdAt;
    }
    
    struct Claim {
        uint256 policyId;
        string reason;
        string evidence;
        uint256 submittedAt;
        bool processed;
    }
    
    mapping(uint256 => Policy) public policies;
    mapping(uint256 => Claim) public claims;
    mapping(address => uint256[]) public userPolicies;
    
    uint256 public nextPolicyId = 1;
    uint256 public totalPremiumCollected;
    uint256 public totalClaimsPaid;
    address public owner;
    
    event PolicyCreated(uint256 indexed policyId, address indexed policyholder, string eventName, uint256 coverageAmount);
    event ClaimSubmitted(uint256 indexed policyId, address indexed policyholder, string reason);
    event ClaimProcessed(uint256 indexed policyId, bool approved, uint256 amount);
    event PremiumCollected(uint256 indexed policyId, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier onlyPolicyholder(uint256 _policyId) {
        require(policies[_policyId].policyholder == msg.sender, "Only policyholder can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    function createPolicy(
        string memory _eventName,
        uint256 _eventDate,
        uint256 _coverageAmount
    ) external payable {
        require(_eventDate > block.timestamp, "Event date must be in the future");
        require(msg.value > 0, "Premium amount must be greater than 0");
        require(_coverageAmount > 0, "Coverage amount must be greater than 0");
        
        uint256 policyId = nextPolicyId++;
        
        policies[policyId] = Policy({
            policyId: policyId,
            policyholder: payable(msg.sender),
            eventName: _eventName,
            eventDate: _eventDate,
            premiumAmount: msg.value,
            coverageAmount: _coverageAmount,
            isActive: true,
            claimSubmitted: false,
            claimApproved: false,
            createdAt: block.timestamp
        });
        
        userPolicies[msg.sender].push(policyId);
        totalPremiumCollected += msg.value;
        
        emit PolicyCreated(policyId, msg.sender, _eventName, _coverageAmount);
        emit PremiumCollected(policyId, msg.value);
    }
    
    function submitClaim(
        uint256 _policyId,
        string memory _reason,
        string memory _evidence
    ) external onlyPolicyholder(_policyId) {
        Policy storage policy = policies[_policyId];
        require(policy.isActive, "Policy is not active");
        require(!policy.claimSubmitted, "Claim already submitted");
        require(block.timestamp >= policy.eventDate, "Cannot submit claim before event date");
        
        policy.claimSubmitted = true;
        
        claims[_policyId] = Claim({
            policyId: _policyId,
            reason: _reason,
            evidence: _evidence,
            submittedAt: block.timestamp,
            processed: false
        });
        
        emit ClaimSubmitted(_policyId, msg.sender, _reason);
    }
    
    function processClaim(uint256 _policyId, bool _approve) external onlyOwner {
        Policy storage policy = policies[_policyId];
        Claim storage claim = claims[_policyId];
        
        require(policy.claimSubmitted, "No claim submitted");
        require(!claim.processed, "Claim already processed");
        
        claim.processed = true;
        
        if (_approve) {
            require(address(this).balance >= policy.coverageAmount, "Insufficient contract balance");
            policy.claimApproved = true;
            policy.isActive = false;
            totalClaimsPaid += policy.coverageAmount;
            
            policy.policyholder.transfer(policy.coverageAmount);
            emit ClaimProcessed(_policyId, true, policy.coverageAmount);
        } else {
            emit ClaimProcessed(_policyId, false, 0);
        }
    }
    
    function getUserPolicies(address _user) external view returns (uint256[] memory) {
        return userPolicies[_user];
    }
    
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    function withdrawExcessFunds(uint256 _amount) external onlyOwner {
        require(_amount <= address(this).balance, "Insufficient balance");
        payable(owner).transfer(_amount);
    }
}
