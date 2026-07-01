# Design — Chart legend toggle + summary boards & filters for Loans and Projects

Date: 2026-07-02
Status: Approved (pending spec review)

## Goal

Three related UI enhancements, all reusing patterns that already exist on the Records screen:

1. **Home chart** — make the Income/Expense legend chips tap-to-toggle. Tapping a chip hides
   that line and rescales the Y-axis to the remaining line. Totals and chips stay visible.
2. **Loans screen** — add a Records-style summary board (**Lent out · Borrowed · Net**) and a
   rich filter sheet (**type · category · date range**), replacing the current plain date bar.
3. **Projects screen** — add a summary board (**Budget · Received · Remaining**) that reacts to
   the already-existing category + date-range filter.

Non-goals: no new record types, no backend/schema changes, no changes to how data is stored.
Everything is derived from data already in the DB.

---

## 1. Home chart legend toggle

### Current state
- `_ChartCardState` (`home_page.dart`, a `ConsumerStatefulWidget`) owns the period selection and
  renders `_LineChart`.
- `_LineChart` builds two series: `LineChartBarData` index **0 = Income** (green), index
  **1 = Expense** (red). It computes `maxY = maxVal * 1.25` from the larger of income/expense per
  point; `minY = 0`.
- A legend `Row` (~line 756) holds two static `_Legend` widgets.

### Change
- Add visibility state to `_ChartCardState`:
  ```dart
  bool _showIncome = true;
  bool _showExpense = true;
  ```
- Make each legend chip tappable (wrap `_Legend` in an `InkWell`/`GestureDetector`). Tapping
  toggles the matching bool via `setState`.
  - **Guard:** never allow both to be off. If turning one off would hide the last visible line,
    ignore the tap (the chip stays on). This keeps the chart from going blank.
- `_Legend` gains an `enabled` (bool) param: when `false`, render the swatch + label at reduced
  opacity (~0.4) so the "off" state reads clearly. Total numbers at the top are untouched
  (Option A — line only).
- `_LineChart` gains `showIncome` / `showExpense` params:
  - Only add a series' `LineChartBarData` when its flag is true.
  - **Recompute `maxY` from visible series only**: iterate points and take the max of just the
    visible line(s). This is what makes the remaining line "expand" to fill the card. Keep the
    `* 1.25` headroom and the `maxVal == 0 ? 100.0` fallback.
  - Tooltip logic keys off `barIndex`; with one series hidden, guard the `isIncome` check so it
    still maps the visible bar to the right colour/label (compute from the series actually added,
    not a hardcoded index).

### Data flow
No provider changes. `chartDataProvider` / `customChartDataProvider` still return full
`List<ChartPoint>` (income + expense). Visibility is pure view state in `_ChartCardState`.

---

## 2. Loans screen — board + rich filter

### Current state
- `_LoansPageState`: `TabController(length: 2)` (Outstanding / Returned), a single
  `DateRangeFilter _range`, and a `date_range_bar.dart` control.
- Data via `outstandingLoansProvider(_range)` / `returnedLoansProvider(_range)` — both return the
  already-filtered `List<RecordRow>` for loan types.
- Loans are `records` with type `loanGiven` / `loanTaken` and a nullable `categoryId`.
- No summary board, no category/type filter.

### Change

**Filter sheet** (`_LoansFilterSheet`, modeled on Records' `_FilterSheet`):
- **Type:** All / Lent (loanGiven) / Borrowed (loanTaken)
- **Category:** the shared category chips (same source Records uses)
- **Date range:** quick chips (Week / Month / Year) + custom range
- Replace the always-visible date bar with a **tune icon** in the AppBar (with the active-filter
  dot indicator, same as Records/Projects). Keep the Outstanding / Returned **tabs** as-is.
- Page state grows: `RecordsFilter`-style type set (or a small `LoanTypeFilter` enum),
  `String? _categoryId`, `DateRangeFilter _range`.

**Applying the filter:** the existing providers already filter by date + returned flag. Apply the
new **type** and **category** constraints client-side in the page (mirrors Projects' `_applyFilters`),
OR extend the providers to accept `categoryId` + a type subset. Preference: extend the two
providers to take an optional `categoryId` and `typesIn` so filtering stays in SQL and the board
totals match exactly what's listed. (They already accept a types set internally.)

**Summary board** (`_LoansTotalsStrip`, styled like Records' `_TotalsStrip`):
- Computed **client-side from the currently-displayed list** (the active tab's filtered rows) —
  no new provider required:
  - `Lent out`  = Σ amountMinor where type == loanGiven
  - `Borrowed`  = Σ amountMinor where type == loanTaken
  - `Net`       = Lent − Borrowed (green when ≥ 0, red when < 0, matching Records' Net colour rule)
- Sits above the list, inside the active tab, so it reflects Outstanding vs Returned + the filter.

---

## 3. Projects screen — board

### Current state
- `_ProjectsPageState` already has the tune icon, `_ProjectFilterSheet` (category + date range),
  and `_applyFilters(List<ProjectRow>)`.
- Each `_ProjectCard` computes its own `paid` from `projectPaymentsProvider(project.id)`.
- Projects have `totalAmountMinor` (budget). No aggregate board.

### Change

**Received totals provider** (new): a single query is cheaper than N per-card streams for the
board. Add to `AppDatabase` a grouped sum of payments per project and expose a provider:
```dart
// database.dart
Stream<Map<String, int>> watchReceivedByProject(); // projectId -> Σ amountMinor
// providers.dart
final receivedByProjectProvider = StreamProvider<Map<String, int>>(...);
```

**Summary board** (`_ProjectsTotalsStrip`, styled like Records' `_TotalsStrip`):
- Computed over the **filtered** project list (`_applyFilters` output) joined with the received map:
  - `Budget`    = Σ totalAmountMinor over filtered projects
  - `Received`  = Σ received[projectId] over filtered projects (0 when absent)
  - `Remaining` = Budget − Received (clamped display; show as neutral/green, red only if negative)
- Sits above the projects list; updates live as the filter changes.

---

## Shared / reuse notes

- **`_TotalsStrip` reuse:** Records' `_TotalsStrip` is currently private to `records_list_page.dart`.
  Extract a small shared widget (e.g. `lib/features/shared/totals_strip.dart`) taking three labeled
  amounts + colours, and have all three screens use it. This avoids three near-identical copies.
  If extraction proves noisy, fall back to per-screen copies — but prefer the shared widget.
- **Colour rules:** reuse `AppColors.green` (income/positive) and `AppColors.danger` (expense/
  negative), and the existing Net colour logic from Records.
- **Money formatting:** reuse `formatMoney(minor, currency)` and the `currencyProvider`, as Records does.

## Error / empty handling
- Chart: with data present but a series toggled off, the remaining line renders normally. The
  "no data" empty state (both totals zero) is unchanged and shows before any toggle is relevant.
- Loans/Projects boards: when the filtered list is empty, the board shows zeros (not hidden), so
  the user sees the filter genuinely matched nothing rather than a missing widget.

## Testing / verification
- `flutter analyze` clean (no new warnings beyond the pre-existing info lints).
- Manual: toggle each chart legend (incl. the "can't hide both" guard), confirm Y-axis rescale.
- Manual: Loans filter by type/category/range on each tab; confirm board math equals the listed
  rows. Projects: change category/range; confirm Budget/Received/Remaining update and match cards.

## Files touched (anticipated)
- `lib/features/home/ui/home_page.dart` — legend toggle state, `_Legend` enabled param, `_LineChart` visibility + rescale.
- `lib/features/loans/ui/loans_page.dart` — filter sheet, tune icon, board.
- `lib/features/projects/ui/projects_page.dart` — board.
- `lib/data/database.dart` — `watchReceivedByProject()`; possibly extend loan providers with category/type.
- `lib/data/providers.dart` — `receivedByProjectProvider`; possibly loan filter params.
- `lib/features/shared/totals_strip.dart` — new shared board widget (if extracted).
