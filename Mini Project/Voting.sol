// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Voting
 * @notice Simple e-voting system. The admin adds candidates and registers voters,
 *         then opens and closes the election. Each registered voter can vote once.
 * @dev For learning and test networks (Sepolia). Votes are public on-chain.
 */
contract Voting {
    // ---------- Types ----------
    enum Phase { Registration, Voting, Ended }

    struct Candidate {
        uint256 id;
        string name;
        uint256 voteCount;
    }

    // ---------- State ----------
    address public admin;
    Phase public phase;
    uint256 public totalVotes;

    Candidate[] private candidates;
    mapping(address => bool) public isRegistered;
    mapping(address => bool) public hasVoted;

    // ---------- Events ----------
    event CandidateAdded(uint256 indexed id, string name);
    event VoterRegistered(address indexed voter);
    event PhaseChanged(Phase newPhase);
    event Voted(address indexed voter, uint256 indexed candidateId);

    // ---------- Modifiers ----------
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can do this");
        _;
    }

    modifier inPhase(Phase p) {
        require(phase == p, "Not allowed in the current phase");
        _;
    }

    constructor() {
        admin = msg.sender;
        phase = Phase.Registration;
    }

    // ---------- Admin: set up the election ----------
    function addCandidate(string calldata name) external onlyAdmin inPhase(Phase.Registration) {
        require(bytes(name).length > 0, "Name is empty");
        uint256 id = candidates.length;
        candidates.push(Candidate(id, name, 0));
        emit CandidateAdded(id, name);
    }

    function registerVoters(address[] calldata voters) external onlyAdmin inPhase(Phase.Registration) {
        for (uint256 i = 0; i < voters.length; i++) {
            address v = voters[i];
            if (!isRegistered[v]) {
                isRegistered[v] = true;
                emit VoterRegistered(v);
            }
        }
    }

    function startVoting() external onlyAdmin inPhase(Phase.Registration) {
        require(candidates.length >= 2, "Add at least 2 candidates");
        phase = Phase.Voting;
        emit PhaseChanged(phase);
    }

    function endVoting() external onlyAdmin inPhase(Phase.Voting) {
        phase = Phase.Ended;
        emit PhaseChanged(phase);
    }

    // ---------- Voter ----------
    function vote(uint256 candidateId) external inPhase(Phase.Voting) {
        require(isRegistered[msg.sender], "You are not a registered voter");
        require(!hasVoted[msg.sender], "You have already voted");
        require(candidateId < candidates.length, "Invalid candidate");

        hasVoted[msg.sender] = true;
        candidates[candidateId].voteCount += 1;
        totalVotes += 1;

        emit Voted(msg.sender, candidateId);
    }

    // ---------- Read ----------
    function getCandidates() external view returns (Candidate[] memory) {
        return candidates;
    }

    function candidateCount() external view returns (uint256) {
        return candidates.length;
    }

    /// @notice Winner after the election ends (first candidate wins a tie).
    function getWinner() external view inPhase(Phase.Ended) returns (string memory name, uint256 votes) {
        require(candidates.length > 0, "No candidates");
        uint256 best = 0;
        for (uint256 i = 1; i < candidates.length; i++) {
            if (candidates[i].voteCount > candidates[best].voteCount) {
                best = i;
            }
        }
        return (candidates[best].name, candidates[best].voteCount);
    }
}
