# Query Planning

## Before SQL

Spend a few seconds on three questions:

```text
One row per what?
Start from which table?
What must happen to those rows?
```

## While Writing

Let each part of the question add to the query:

```text
Required fields             -> SELECT
Starting data               -> FROM
Related fields              -> JOIN
Source-row conditions       -> WHERE
One result per X            -> GROUP BY X
Conditions on group metrics -> HAVING
Top, highest or lowest      -> ORDER BY, then LIMIT
```

Reason through the rows in this order:

```text
FROM/JOIN -> WHERE -> GROUP BY -> HAVING -> SELECT -> ORDER BY -> LIMIT
```

## After SQL

Check only what could realistically make this answer wrong:

```text
Did a join multiply rows?
Am I counting or summing at the intended grain?
Are NULLs, zero matches or date boundaries relevant?
Can I verify one result with a smaller query?
```

## Decision Guide

```text
Matching-row columns       -> JOIN
Summary per group          -> GROUP BY + aggregate
Keep unmatched rows        -> LEFT JOIN or NOT EXISTS
Proof of a match           -> EXISTS or IN
Calculated comparison      -> scalar subquery
Changing benchmark         -> correlated subquery
Calculation using totals   -> another stage, often a CTE
```

## Northwind Example

List suppliers associated with at least one discontinued product:

```text
One row per supplier.
Start from suppliers.
Products only prove a match, so use EXISTS.
Check that multiple products do not duplicate suppliers.
```
