export type StopGateDecisionKind = "stop_or_mark_blocked" | "completion_audit" | "continue_or_repair";

export type StopGateCommandResult = {
  exitCode: number | null;
  stdout?: string;
  stderr?: string;
  signal?: string | null;
};

export type StopGateDecision = {
  kind: StopGateDecisionKind;
  reason: string;
  gateStatus?: string;
  nextActionOwner?: string;
};

type ParsedGateResult = Record<string, unknown>;

const EXTERNAL_OWNERS = new Set(["human", "user", "operator", "external"]);

export function classifyStopGateCommandResult(result: StopGateCommandResult): StopGateDecision {
  const combinedOutput = [result.stdout, result.stderr].filter(Boolean).join("\n");
  const parsed = parseGateJson(combinedOutput);
  const gateStatus = normalizeToken(parsed?.status);
  const nextActionOwner = normalizeToken(
    parsed?.next_action_owner ?? parsed?.nextActionOwner ?? parsed?.owner ?? parsed?.next_owner,
  );
  const parsedText = parsed === undefined ? "" : JSON.stringify(parsed);
  const evidenceText = [combinedOutput, parsedText].join("\n");

  if (gateStatus === "blocked" && isExternalOwner(nextActionOwner)) {
    return {
      kind: "stop_or_mark_blocked",
      reason: "gate reports an external-input blocker",
      gateStatus,
      nextActionOwner,
    };
  }

  if (gateStatus === "blocked" && mentionsExternalInput(evidenceText)) {
    return {
      kind: "stop_or_mark_blocked",
      reason: "blocked gate output names external evidence",
      gateStatus,
      nextActionOwner,
    };
  }

  if ((result.exitCode ?? 1) !== 0 && mentionsBlockedExternalInput(evidenceText)) {
    return {
      kind: "stop_or_mark_blocked",
      reason: "failed gate output names a blocked external dependency",
      gateStatus,
      nextActionOwner,
    };
  }

  if ((result.exitCode ?? 1) === 0 && (parsed?.ok === true || gateStatus === "complete")) {
    return {
      kind: "completion_audit",
      reason: "gate passed; audit the original objective before completing",
      gateStatus,
      nextActionOwner,
    };
  }

  return {
    kind: "continue_or_repair",
    reason: "gate did not prove completion or an external-input blocker",
    gateStatus,
    nextActionOwner,
  };
}

function parseGateJson(text: string): ParsedGateResult | undefined {
  for (const candidate of jsonCandidates(text)) {
    try {
      const parsed = JSON.parse(candidate);
      if (isRecord(parsed)) return parsed;
    } catch {
      // Continue scanning: many command outputs include logs before/after JSON.
    }
  }
  return undefined;
}

function jsonCandidates(text: string): string[] {
  const trimmed = text.trim();
  const candidates: string[] = [];
  if (trimmed.startsWith("{") && trimmed.endsWith("}")) candidates.push(trimmed);

  for (const line of text.split(/\r?\n/)) {
    const lineText = line.trim();
    if (lineText.startsWith("{") && lineText.endsWith("}")) candidates.push(lineText);
  }

  const firstBrace = text.indexOf("{");
  const lastBrace = text.lastIndexOf("}");
  if (firstBrace >= 0 && lastBrace > firstBrace) candidates.push(text.slice(firstBrace, lastBrace + 1));

  return [...new Set(candidates)];
}

function isRecord(value: unknown): value is ParsedGateResult {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function normalizeToken(value: unknown): string | undefined {
  if (typeof value !== "string") return undefined;
  const normalized = value.trim().toLowerCase().replace(/[-\s]+/g, "_");
  return normalized.length > 0 ? normalized : undefined;
}

function isExternalOwner(owner: string | undefined): boolean {
  return owner !== undefined && EXTERNAL_OWNERS.has(owner);
}

function mentionsBlockedExternalInput(text: string): boolean {
  return /\bblocked\b/i.test(text) && mentionsExternalInput(text);
}

function mentionsExternalInput(text: string): boolean {
  return [
    /\bhuman\b/i,
    /\boperator\b/i,
    /\bexternal\b/i,
    /\buser\b.*\b(input|decision|approval|record|records|evidence|test|testing|review)\b/i,
    /\b(input|decision|approval|record|records|evidence|test|testing|review)\b.*\buser\b/i,
    /\bapi key\b/i,
    /\bcredentials?\b/i,
    /\bhardware\b/i,
    /\breal[- ]device\b/i,
    /\bprivate data\b/i,
    /\baccount approval\b/i,
    /\bpaid service\b/i,
  ].some((pattern) => pattern.test(text));
}
