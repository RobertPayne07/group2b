# DAX Measures — Clinic Patient Wait Time Model

All measures below assume the star schema in `star_schema.sql` (`FactVisits` fact
table with `IsValidWait` and `IsRegisteredPatient` flags carried through from cleaning).
Create every measure in a dedicated `_Measures` table, not scattered across the
dimension/fact tables.

## Core counts

```dax
Total Visits =
COUNTROWS ( FactVisits )
```
Counts every de-duplicated visit, including the 51 with an invalid wait time and
the 1,508 with an Unknown visit type. This is the number that should reconcile to
**25,000** with no filters applied — that reconciliation check is exactly what
Week 6 validation is for.

```dax
Raw Records (Before Cleaning) = 25100
```
A hardcoded reference value for the one KPI card, if you choose to show it, that
explicitly compares the raw file size to the cleaned model — label it clearly so
it is never confused with Total Visits.

```dax
Valid Wait Visits =
CALCULATE (
    COUNTROWS ( FactVisits ),
    FactVisits[IsValidWait] = TRUE
)
```

## Wait time measures

```dax
Average Wait Time =
CALCULATE (
    AVERAGE ( FactVisits[WaitMinutes] ),
    FactVisits[IsValidWait] = TRUE
)
```
This is the headline measure. It automatically respects whatever Department,
Visit Type or Date filters are active on the report page — that is what makes
"Department → Average Wait Time, sorted descending" work as a ranking visual
without any extra DAX.

```dax
Maximum Wait Time =
CALCULATE (
    MAX ( FactVisits[WaitMinutes] ),
    FactVisits[IsValidWait] = TRUE
)
```

```dax
Total Wait Minutes =
CALCULATE (
    SUM ( FactVisits[WaitMinutes] ),
    FactVisits[IsValidWait] = TRUE
)
```

```dax
Median Wait Time =
CALCULATE (
    MEDIAN ( FactVisits[WaitMinutes] ),
    FactVisits[IsValidWait] = TRUE
)
```
Include this alongside the average — with a 0–209 minute spread, the median is
a useful sense-check that the average isn't being pulled around.

```dax
Invalid Wait Records =
CALCULATE (
    COUNTROWS ( FactVisits ),
    FactVisits[IsValidWait] = FALSE
)
```
Surface this somewhere visible (a small "data quality" card or tooltip) rather
than only in the documentation — it is the kind of number a marker or a
skeptical administrator will ask about.

## Ranking helpers

```dax
Department Rank by Wait =
RANKX (
    ALL ( DimDepartment[DepartmentKey] ),
    CALCULATE ( [Average Wait Time] ),
    ,
    DESC
)
```
Use this to label the department bar chart with "#1 longest wait", etc.,
independent of whatever slicer selections are active elsewhere on the page.

```dax
Wait Time vs Overall Average =
[Average Wait Time] -
CALCULATE ( [Average Wait Time], ALL ( DimDepartment ), ALL ( DimVisitType ) )
```
A signed "minutes above/below the whole-clinic average" measure — useful for
conditional formatting on the department table (red above 0, green below),
and it directly supports the finding that department differences are small
(a few minutes either side of the mean) rather than dramatic.

## Time intelligence

```dax
Average Wait Time (Prior Month) =
CALCULATE (
    [Average Wait Time],
    DATEADD ( DimDate[Date], -1, MONTH )
)
```

```dax
Wait Time MoM Change =
[Average Wait Time] - [Average Wait Time (Prior Month)]
```
Requires `DimDate` marked as the official Date Table and related to
`FactVisits` on `DateKey`; `DATEADD` needs a contiguous calendar, which is
why `DimDate` is built for every day in range rather than only for days that
have a visit.

## Data-quality transparency measures

```dax
% Visits with Unknown Type =
DIVIDE (
    CALCULATE ( COUNTROWS ( FactVisits ), DimVisitType[VisitType] = "Unknown" ),
    [Total Visits]
)
```

```dax
% Unregistered Patient Visits =
DIVIDE (
    CALCULATE ( COUNTROWS ( FactVisits ), FactVisits[IsRegisteredPatient] = FALSE ),
    [Total Visits]
)
```
Both of these exist so the dashboard can show its own data-quality caveats
inline (e.g. in a tooltip on the Total Visits card) rather than only in a
separate document nobody opens.

## Fee measures (available if a later page needs them; not part of the
## core wait-time story, but built on the same fact table)

```dax
Total Consultation Fees =
SUM ( FactVisits[Fee] )
```

```dax
Average Fee =
AVERAGE ( FactVisits[Fee] )
```

## Validation checklist (Week 6 of the brief)

Cross-check these three, in order, before trusting the dashboard:

1. `Average Wait Time` filtered to one department in Power BI
2. …against the SQL profiling query in §6b of `sql_profiling_queries.sql` for the same `department_id`
3. …against the Python notebook's `clean.groupby('department_id')['wait_minutes'].mean()` for the same department

If any of the three disagree, the likely culprits, in order of frequency, are:
a relationship set to the wrong direction, a missed de-duplication step, or a
measure that forgot the `IsValidWait` filter.
