# LedgerLine Credit Scoring Model

## 1. Objective

LedgerLine's scoring engine converts verified repayment behavior into a simple, transparent credit score.

The model deliberately favors explainability over complexity.

Every score change must be attributable to an on-chain verified event.

## 2. Score range

```text
Minimum: 0
Base:    500
Maximum: 1000
```

A new borrower begins at:

```text
500
```

on their first verified repayment interaction.

The base score represents an unproven borrower rather than an automatically bad borrower.

## 3. Full repayment

A borrower receives:

```text
+15
```

when a loan is fully repaid.

The increment occurs only when:

```text
repaidAmount >= expectedRepaymentAmount
```

The score cannot exceed:

```text
1000
```

## 4. Partial repayment

Partial repayment:

* increases `totalVerifiedRepayments`
* changes loan state to `PartlyRepaid`
* updates `lastUpdated`
* does not increase the credit score

This prevents score inflation through artificial payment fragmentation.

For example, a borrower should not be able to turn one obligation into twenty tiny repayments and receive twenty score increases.

## 5. Credit profile

Each borrower has:

```text
score
totalVerifiedRepayments
completedLoanCount
lastUpdated
```

### score

Current score from 0 to 1000.

### totalVerifiedRepayments

Cumulative repayment value verified through LedgerLine.

### completedLoanCount

Number of loans that reached full repayment.

### lastUpdated

Timestamp of the most recent verified repayment interaction.

## 6. Example

A borrower starts with:

```text
500
```

Loan 1 is fully repaid:

```text
500 + 15 = 515
```

Loan 2 is partially repaid:

```text
515
```

No score increase occurs.

Loan 2 is later fully repaid:

```text
515 + 15 = 530
```

## 7. Financing eligibility

The financing layer currently applies:

| Score     | Requirement       | Advance rate |
| --------- | ----------------- | -----------: |
| Below 600 | Any               | Not eligible |
| 600–749   | ≥1 completed loan |          50% |
| 750–899   | ≥1 completed loan |          65% |
| 900–1000  | ≥1 completed loan |          80% |

The calculated advance is then capped by:

```text
totalVerifiedRepayments
```

Therefore financing cannot exceed the borrower's demonstrated verified repayment history.

## 8. Why the model is intentionally simple

The first version of LedgerLine is designed to prove the integrity of the evidence pipeline.

A complicated scoring model would introduce additional assumptions before the underlying cross-chain credit infrastructure has sufficient real-world data.

The initial model therefore emphasizes:

* deterministic behavior
* explainability
* auditability
* resistance to payment fragmentation
* on-chain verifiability

## 9. Known limitations

The current model does not yet incorporate:

* repayment speed
* loan size normalization
* debt-to-income ratio
* default severity
* delinquency duration
* historical utilization
* industry risk
* macroeconomic risk
* external credit bureau data

There is also currently no negative score adjustment for missed deadlines.

`Expired` exists as a loan state but is not yet connected to a score penalty.

## 10. Future scoring model

A production scoring model can introduce weighted components such as:

```text
Repayment reliability
        +
Repayment speed
        +
Loan completion history
        +
Verified borrowing capacity
        +
Default history
        +
Recency
        +
Cross-chain history
```

The important architectural constraint should remain unchanged:

> Any financial evidence used by the scoring engine must be independently verifiable.
