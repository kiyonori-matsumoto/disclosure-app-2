## 2023-10-27 - [Optimization Strategy]

**Learning:** When making micro-optimizations like using `SizedBox.shrink()` over `Container()` or collection `if` over ternaries, explicit inline comments detailing the optimization are required for Bolt PRs even if the optimization seems standard. Ensure no auto-generated ephemeral files (like those from iOS build folders) are accidentally committed alongside optimizations.

**Action:** Always write an inline `// ⚡ Bolt:` comment for every optimization made. Before committing, thoroughly double-check `git status` to ensure `.flutter-plugins-dependencies` or `ios/Flutter/ephemeral/` files are not unintentionally included.
