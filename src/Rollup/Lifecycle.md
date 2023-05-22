## State Root Life Cycle

### Stage 1
1. Proposer burns a fixed-size fee, places a bid, and generates a valid work nonce in order to propose a state root.
2. Proposer has a grace period during which the root can be revoked or replaced.
3. Once grace period ends, the state root becomes subject to fraud reporting, and the root for the next epoch can be proposed.

### Stage 2
Initial Fraud Period
- Validators can detect invalid reporting and generate fraud proofs, but must also propose a correct state root in place of the invalidated one.

### Stage 3
Secondary Fraud Period
- Batches of Settlements, but must be collateralized.
    - Amount owed to recipient can be immediately withdrawn. The collateral and settlement fee is held until state root is considered finalized.

### Stage 4
Finalized
- Any collateral used for state root, settlements, or fees can be released
- Any proposed Settlements or Fees that passed their individual fraud periods can be finalized
- Settlements and Fees can be proposed without collateral but are stil subject to individual fraud periods
- During this stage, fees from settlements can be withdrawn.

### Fraud
1. Validator reports a fraud proof that passes validation and flags a reported state root as invalid.
2. The bid placed on the state root can be slashed and sent to the reporter.
    - If error was due to SDP reporting the wrong data, a new state root can be proposed for the epoch
        - In cases of missing state updates or out-of-sequence state updates, the subsequent state root should not be affected
    - If error was due to exchange generating and signing invalid state updates, then the system enters recovery mode.
3. Any settlements or fees being proposed from that state root can be marked as invalid and slashed.

