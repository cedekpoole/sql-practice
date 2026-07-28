# Query Planning

Before writing SQL:

```text
OUTPUT: One row per ___ | return ___ | sort/limit ___
SCOPE: Records/dates ___ | include zero matches? ___ | ties? ___
SOURCE: Start at ___ (one row per ___) | connect ___ using ___
LOGIC: Details, summary, existence, benchmark or multiple stages?
CHECK: Duplicates, NULLs, zeros or date boundaries?
```

## Decision Guide

```text
Matching-row columns       -> JOIN
Summary per group          -> GROUP BY + aggregate
Proof of a match           -> EXISTS or IN
Calculated comparison      -> scalar subquery
Calculation using totals   -> another stage, often a CTE
Keep unmatched rows        -> LEFT JOIN or NOT EXISTS
```

## Northwind Example

List suppliers associated with at least one discontinued product:

```text
OUTPUT: One row per supplier | supplier_id, company_name
SCOPE: At least one discontinued product
SOURCE: suppliers -> products using supplier_id
LOGIC: Products only prove a match, so use EXISTS
CHECK: Multiple products must not duplicate suppliers
```
