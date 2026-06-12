# Todo

| Status | Todo | Description |
|--------|------|-------------|
| ✅ Done | Home page — extended date range filter | Added a **Custom** chip to the Overview chart card that opens Flutter's built-in `showDateRangePicker`. Custom ranges drive a new `customChartDataProvider` which auto-selects daily vs monthly buckets based on range length (≤90 days = daily, >90 = monthly). |
| ✅ Done | Home page — show income & expense totals for selected date | The `_ChartCard` now shows an animated totals row (Income / Expense / Net) computed from the active chart data — updates live as the period chip or custom range changes. The Records page shows a `_TotalsStrip` card at the top of the list driven by `filteredTotalsProvider` (no row limit, accurate across all records). |
| ✅ Done | Dark mode — filter chips do not invert correctly on Records page | `_Chip` unselected text changed from `context.inkSubtle` (38% opacity) to `context.ink` (full theme-aware color) in both `records_list_page.dart` and `projects_page.dart`. Selected: ink background + surface text. Unselected: transparent + ink text. High contrast in both themes. |
