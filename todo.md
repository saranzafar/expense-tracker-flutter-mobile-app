# Todo

| Todo | Description |
|------|-------------|
| Home page — extended date range filter | The home page currently offers fixed quick-range chips (1D / 1W / 1M / 1Y). Add a **Custom** option that opens a date-range picker so the user can select any arbitrary start and end date, matching what the Records filter sheet already supports. |
| Home page — show income & expense totals for selected date | Below the balance card (or inside it), display a summary of **total income** and **total expense** for whichever date range is currently selected (default or custom). This gives the user an at-a-glance picture of their cash flow for the period without having to open the Records page. The same summary strip should also appear on the Records page above the list, updating live as filters change. |
| Dark mode — filter chips do not invert correctly on Records page | On the Records page filter sheet the `_Chip` widget still reads wrong in some theme combinations. Audit selected/unselected chip `color` and `text color` against both light and dark `ColorScheme` values to ensure sufficient contrast in every state. |
