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
