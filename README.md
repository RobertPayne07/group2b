# group2b
group repo


Clinic Patient Wait Time — Dashboard & Presentation Content
All numbers below come from the actual cleaned dataset (`fact_visits.csv`,
24,950 visits with a valid wait time out of 25,000 unique visits), not
illustrative placeholders. Cross-checked in SQL, Python and (once built)
Power BI per the Week 6 validation step.
Headline finding
> After cleaning 25,100 raw records down to 25,000 unique visits, **Department 7
> has the longest average patient wait at 107.7 minutes**, only about 2 minutes
> above the clinic-wide average of 106.3 minutes and about 2 minutes above the
> shortest-waiting department (Department 8, 105.7 minutes). **The eight
> departments are much closer together than staff opinion likely assumes** — the
> more useful story is in visit type and time, not a single "worst" department.
Key numbers for KPI cards
KPI	Value
Average Wait Time (clinic-wide)	106.3 minutes
Longest-Wait Department,Department 7 (107.7 min)
Longest-Wait Visit Type	Emergency (106.9 min) — but see Unknown-type caveat below
Total Visits (cleaned, de-duplicated)	25,000
Raw records before cleaning	25,100 (label explicitly as "raw" if shown at all)
Page layout
```
┌───────────────────────────────────────────────────────────────────────┐
│                 CLINIC PATIENT WAIT TIME DASHBOARD                    │
│                                                                       │
│ [Avg Wait: 106.3 min] [Longest Dept: Dept 7] [Longest Type: Emergency]│
│ [Total Visits: 25,000]                                               │
│                                                                       │
│  Date ▾        Department ▾        Visit Type ▾                      │
├───────────────────────────────────────────────────────────────────────┤
│  AVERAGE WAIT TIME BY DEPARTMENT (sorted longest → shortest)          │
│  Dept 7  ████████████████████████████████████  107.7                 │
│  Dept 2  ███████████████████████████████████   106.8                 │
│  Dept 4  ███████████████████████████████████   106.5                 │
│  Dept 3  ██████████████████████████████████    106.1                 │
│  Dept 1  ██████████████████████████████████    106.0                 │
│  Dept 6  █████████████████████████████████     105.9                 │
│  Dept 5  █████████████████████████████████     105.9                 │
│  Dept 8  █████████████████████████████████     105.7                 │
├──────────────────────────────────┬────────────────────────────────────┤
│ AVERAGE WAIT OVER TIME (monthly)  │ AVERAGE WAIT BY VISIT TYPE         │
│  111 ┤                      ●     │ Emergency   ████████████  106.9   │
│  108 ┤     ●     ●      ●  ╱      │ Follow-up   ███████████   106.5   │
│  105 ┤●╲ ╱  ╲   ╱  ╲  ╱  ●        │ Outpatient  ███████████   105.9   │
│  102 ┤  ●    ● ╱    ●╲╱           │ Unknown*    ████████████  107.3   │
│  100 ┤       ●                    │ *type not recorded on source data │
│      Jan'24 ... Dec'25            │                                    │
├──────────────────────────────────┴────────────────────────────────────┤
│ DEPARTMENT × VISIT TYPE (drill-down table, sortable)                  │
│  Dept 2 + Follow-up:  110.3 min      Dept 3 + Emergency: 110.2 min    │
│  Dept 7 + Outpatient: 107.7 min      Dept 6 + Emergency: 108.8 min    │
├─────────────────────────────────────────────────────────────────────┤
│ KEY MESSAGE: Department differences are small (≈2 min spread);       │
│ the sharper signal is in visit type and month — see combinations     │
│ above and the December 2025 spike below.                             │
└─────────────────────────────────────────────────────────────────────┘
```
Slicers
Date (connected to `DimDate`, hierarchy Year > Quarter > Month)
Department
Visit Type
Kept to three, as recommended — Region/Insurance slicers are not available
in this source data (no patient demographic file was supplied) and should
not be added speculatively.
The three questions, answered with real numbers
1. Which departments have the longest waits?
Department 7 is longest at 107.7 minutes; Department 8 is shortest at 105.7
minutes. The full spread across all eight departments is under 2 minutes —
there is no dramatic outlier department in this data. Any presentation
slide claiming otherwise would be overstating the evidence.
2. Does the ranking change by visit type?
Yes, and this is the more actionable finding:
Department 2 + Follow-up visits average 110.3 minutes — the single
longest department/visit-type combination with a known type.
Department 3 + Emergency visits average 110.2 minutes.
Department 7's longest contributor is actually Outpatient (107.7 min),
not Emergency.
Department 6 + Emergency also runs high, at 108.8 minutes.
So "Department 7 is the problem" is too simple — the real message for an
administrator is: investigate Department 2's follow-up process and
Department 3's emergency triage specifically, rather than Department 7
across the board.
3. Is the problem changing over time?
Monthly average wait fluctuates between roughly 100.7 minutes (December 2024)
and 109.6 minutes (December 2025) — a rise of about 9 minutes at the December
peaks a year apart, but with no smooth, consistent upward trend across the
24 months in between. The pattern looks like month-to-month variability
rather than a steadily worsening system-wide problem, with December 2025
as the point worth a closer look (holiday staffing? seasonal demand?).
Data-quality caveats to state on record (Week 8 "confidence" section)
100 duplicate rows were removed before any of the above was calculated.
51 visits (0.2%) had a negative — and therefore excluded — wait time.
1,508 visits (6.0%) have no reliable visit type on record (shown as "Unknown,"
not folded into Outpatient/Follow-up/Emergency).
62 visits reference a patient ID outside the documented 1–900 range and are
flagged as likely walk-in/unregistered patients pending confirmation.
No department-name, doctor-name or patient-demographic master file was
supplied with this dataset — department and doctor labels on the dashboard
are the numeric IDs from the source data, not real names.
Ten-minute presentation outline
The problem — staff disagreed on which department has the worst waits.
The evidence — 25,100 raw visit records; after removing 100 duplicates
and flagging 51 invalid wait times, 1,508 unknown visit types and 62
unregistered-patient visits, 25,000 unique visits (24,950 with a usable
wait time) were analysed.
The finding — department wait times are close together (105.7–107.7
minutes); Department 7 is the nominal longest, but only by ~2 minutes.
The explanation — visit type reshuffles the ranking: Department 2's
follow-ups and Department 3's emergencies are the real high points.
The trend — waits fluctuate month to month; December 2025 is the
current high point at 109.6 minutes.
The implication — investigate the Department 2 follow-up workflow and
Department 3 emergency triage specifically, and keep an eye on December
seasonality, rather than treating "Department 7" as a blanket target.
The confidence — every number above traces back to a documented
cleaning decision (`data_quality_notes.md`) and was cross-checked in SQL,
Python and Power BI.









Data Quality Notes — Clinic Visits Dataset
Source file: `Clinic_Visits.xlsx` (single sheet, 25,100 rows, 9 columns)
Business question: Which departments have the longest patient wait times, and how does that vary by visit type and over time?
Principle followed throughout: issues are documented and flagged, not silently fixed or guessed at. Nothing is imputed; rows are only excluded from a specific measure when a value is genuinely impossible for that measure.
0. Raw column inventory
Column	Type observed	Notes
`#`	int	Sequential spreadsheet row number, 1–25,100. Not a business key — dropped from the model.
`visit_id`	int	Intended primary key of a visit. Not unique in the raw file (see §1).
`visit_date`	mixed	Stored as Excel datetime for most rows, as `DD/MM/YYYY` text for others (see §2).
`patient_id`	int	Expected range 1–900 per project scope; 62 rows fall outside it (see §4).
`doctor_id`	int	Range 1–40, fully populated, no blanks.
`department_id`	int	Range 1–8, fully populated, no blanks.
`visit_type`	string	Free-text category with case, whitespace and missing-value inconsistency (see §3).
`wait_minutes`	int	Includes physically impossible negative values (see §5).
`consultation_fee`	int	Values ∈ {0, 20, 35, 50, 80, 120}. No blanks; fee = 0 occurs at a similar ~35% rate in every department and every visit type, so it looks like a legitimate fee tier (e.g. a covered/waived visit) rather than a missing-value placeholder — flagged as an assumption to confirm with the business, not treated as an error.
No dimension/master files (patient roster, doctor roster, department names) were supplied with this dataset — only the fact-level extract. Everywhere the assignment brief calls for orphan-key checks against `DimPatient`/`DimDoctor`/`DimDepartment`, this notebook substitutes a range/plausibility check against the extract itself and states that explicitly as a limitation, rather than reporting a false "0 orphans found."
1. Duplicate visits
100 rows (50 pairs) share a `visit_id` with another row, and in every one of those 50 pairs all other columns are identical too — same patient, doctor, department, date, visit type, wait time and fee. This is consistent with a row being loaded twice, not with two genuinely different visits colliding on an ID.
Treatment: kept the first occurrence of each `visit_id`, dropped the repeat. 25,100 raw rows → 25,000 unique visits. The 100 dropped rows are logged in `audit_duplicate_visit_id.csv` for auditability.
Not investigated further: duplicate patients or duplicate doctors — there is no patient/doctor master table in this extract to check against, so this check could not be performed as scoped.
2. Visit date format
24,137 rows store `visit_date` as a proper Excel datetime.
963 rows store it as a `DD/MM/YYYY` text string (e.g. `"29/07/2024"`) instead.
Both forms parse cleanly once the text form is read with an explicit `%d/%m/%Y` format — 0 rows failed to parse, and there are no impossible dates (no Feb-30, no future-dated visits, etc.).
Range after parsing: 1 Jan 2024 → 30 Dec 2025 (used to size `DimDate`).
Treatment: both formats coerced to a single `datetime64` column before anything else runs. This must happen before de-duplication/joins, because a text date and a datetime date for the same real date are not naturally equal without parsing.
3. Inconsistent / missing `visit_type`
Thirteen distinct raw spellings collapse to three real categories plus a genuine "unknown":
Raw values	Standardised to
`Outpatient`, `OUTPATIENT`, `outpatient`, ` Outpatient`	Outpatient
`Follow-up`, `FOLLOW-UP`, `follow-up`, ` Follow-up`	Follow-up
`Emergency`, `EMERGENCY`, `emergency`, ` Emergency`	Emergency
`[NULL]` (literal text, 1,508 rows / 6.0%)	Unknown
Treatment: case-fold + trim, then map to the three canonical labels. The `[NULL]` rows are not guessed into one of the three real categories — they become their own `Unknown` member of `DimVisitType`. This keeps the 1,508 visits visible and countable (Total Visits still reconciles to 25,000) while making clear in every visit-type breakdown that ~6% of visits have no reliable type on record, rather than quietly inflating whichever category they were assigned to.
4. Patient IDs outside the expected range
The project scope describes 900 patients. 24,938 rows have `patient_id` in the expected 1–900 range.
62 rows have `patient_id` between 90,000 and 90,061 — a distinct, contiguous, clearly-deliberate block, not noise (e.g. not 901, 1500, 2 million). This pattern is typical of a walk-in / unregistered-patient placeholder range rather than a data-entry error.
Treatment: flagged with `IsRegisteredPatient = FALSE` rather than deleted or remapped into the 1–900 range. This is an assumption pending confirmation from whoever owns the patient master data — it should be validated once/if a real patient dimension file is available, and the notes here should not be read as certainty.
5. Negative wait times
51 rows (0.2%) have `wait_minutes < 0`, ranging from ‑3 to ‑209 minutes. A wait time cannot be negative.
The magnitudes mirror the plausible positive range (0–209), consistent with a sign flip during entry/export rather than a different kind of error.
Treatment: flagged with `IsValidWait = FALSE` and excluded only from wait-time measures (average/median/max wait). The visits themselves are not deleted from the fact table — they still count toward Total Visits, fee totals, etc. Deleting the whole row would understate visit volume for a problem that only affects one column.
6. Fields with no data-quality issues found
`department_id`, `doctor_id`: fully populated, entirely within their expected ranges (1–8 and 1–40), no blanks, no out-of-range values.
`consultation_fee`: no blanks, all values fall into one of six discrete tiers.
7. Cleaned analytical population
Population	Row count	Used for
Raw rows in source file	25,100	Reference only — should never be shown on the dashboard as "records analysed"
Unique visits (after de-dup)	25,000	`Total Visits`
Unique visits with a valid (non-negative) wait time	24,950	`Average Wait Time`, department ranking, trend
…of which, visit type is known (not `Unknown`)	23,450	Visit-type breakdown and Department × Visit Type views
The dashboard's headline Total Visits card should read 25,000, not 25,100 — and should be labelled clearly enough that a duplicate-inflated raw count is never quoted as the analysed population.
8. Summary of treatments (for the audit trail)
Issue	Rows affected	Treatment	Deleted?
Duplicate `visit_id`	100 (50 pairs)	Kept first occurrence	Yes, the repeat only
Text-format dates	963	Parsed to datetime	No
Inconsistent `visit_type` spelling	~11,000+	Standardised to 3 labels	No
Missing `visit_type` (`[NULL]`)	1,508	Mapped to explicit `Unknown` member	No
Negative `wait_minutes`	51	Flagged `IsValidWait = FALSE`, excluded from wait measures only	No
`patient_id` outside 1–900	62	Flagged `IsRegisteredPatient = FALSE`	No
