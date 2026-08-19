# LedgerLine — Credit Scoring Model

## Score range and initialization

Scores range 0–1000. A borrower's profile initializes at a base score of 500
on their first verified interaction — not 0, since a new profile isn't
necessarily a risky one; it's simply unproven yet.

## Scoring rule

The score increases by 15 points **only when a loan is fully repaid**
(`repaidAmount >= expectedRepaymentAmount`), capped at 1000. Partial
repayments update `totalVerifiedRepayments` and move loan status to
`PartlyRepaid`, but do not move the score.

## Why full-repayment-only, not per-payment

Scoring on every partial payment would let a borrower inflate their score by
splitting one obligation into many small repayments. Requiring full
completion means the score reflects proven, completed obligations —
consistent with how traditional credit scoring treats "paid as agreed."

## What's tracked per borrower (`CreditMetrics`)

- `score` — 0–1000
- `totalVerifiedRepayments` — cumulative amount, across all loans
- `completedLoanCount` — number of fully repaid loans
- `lastUpdated` — timestamp of the most recent verified event

## Known limitations (by design, documented rather than hidden)

- The model doesn't yet weight for repayment speed, loan size, or default
  history on other loans — those are natural extensions once real usage data
  exists.
- No negative scoring for missed deadlines yet; `LoanExpired` is a stated
  status in `LedgerLineTypes.sol` but not yet wired into a score penalty.
