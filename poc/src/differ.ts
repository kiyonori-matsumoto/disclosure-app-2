import * as Diff from "diff";

export interface DiffResult {
  sectionKey: string;
  sectionLabel: string;
  addedLines: string[];
  removedLines: string[];
  diffSummaryText: string;
  hasChanges: boolean;
}

/**
 * 前期と当期のテキストを比較し、差分を抽出する
 */
export function computeDiff(
  sectionKey: string,
  sectionLabel: string,
  priorText: string,
  currentText: string
): DiffResult {
  const changes = Diff.diffLines(priorText, currentText, { ignoreWhitespace: true });

  const addedLines: string[] = [];
  const removedLines: string[] = [];
  const summaryParts: string[] = [];

  for (const part of changes) {
    const lines = part.value
      .split("\n")
      .map((l) => l.trim())
      .filter((l) => l.length > 0);

    if (part.added) {
      addedLines.push(...lines);
      lines.forEach((l) => summaryParts.push(`+ ${l}`));
    } else if (part.removed) {
      removedLines.push(...lines);
      lines.forEach((l) => summaryParts.push(`- ${l}`));
    }
  }

  const hasChanges = addedLines.length > 0 || removedLines.length > 0;

  return {
    sectionKey,
    sectionLabel,
    addedLines,
    removedLines,
    diffSummaryText: summaryParts.join("\n"),
    hasChanges,
  };
}
