
## 2026-10-22 - [Synchronous filtering in Rx chains blocks Main Thread]
**Learning:** RxDart chains combined with UI interaction (like `combineLatest` on a search input stream against a list of ~4000 items) will cause synchronous filtering operations that block the main thread and drop frames. Flutter handles UI on the main isolate. A heavy list filter per keystroke can degrade responsiveness severely.
**Action:** When filtering a large list in an Rx chain based on user input, always introduce a `debounceTime` (e.g. 300ms) to ensure we do not recalculate on every rapid keystroke.
