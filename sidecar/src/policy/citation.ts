import type { PolicyOutcome, PolicyPack } from "./types.js";
import { classifyUrl } from "./url.js";

const URL_PATTERN =
  /https?:\/\/[^\s<>"')\]]+/gi;

export function extractUrls(input: string | string[]): string[] {
  if (Array.isArray(input)) {
    return input;
  }
  const matches = input.match(URL_PATTERN) ?? [];
  return [...new Set(matches)];
}

export function evaluateCitations(
  input: string | string[],
  policy: PolicyPack,
): PolicyOutcome {
  const urls = extractUrls(input);
  if (urls.length === 0) {
    return { kind: "allowed" };
  }

  const classifications = urls.map((url) => ({
    url,
    classification: classifyUrl(url, policy),
  }));

  const denied = classifications.filter((entry) => entry.classification === "deny");
  const allowed = classifications.filter((entry) => entry.classification === "allow");
  const neutral = classifications.filter((entry) => entry.classification === "neutral");

  if (denied.length === 0 && neutral.length === 0) {
    return { kind: "allowed" };
  }

  const contaminatedUrls = [
    ...denied.map((entry) => entry.url),
    ...neutral.map((entry) => entry.url),
  ];

  if (allowed.length > 0 && denied.length > 0) {
    return {
      kind: "refused",
      reason:
        "Mixed PoE1 and PoE2 citations detected — refuse answer and re-ask on allowlisted PoE1 sources only",
      rule: "citation.mixed",
      path: "research",
      action: "re-ask",
      contaminatedUrls: denied.map((entry) => entry.url),
    };
  }

  if (denied.length > 0) {
    return {
      kind: "refused",
      reason: "Answer cites denylisted PoE2 or lookalike sources",
      rule: "citation.denylisted",
      path: "research",
      action: "re-ask",
      contaminatedUrls: denied.map((entry) => entry.url),
    };
  }

  return {
    kind: "refused",
    reason: "Answer cites sources outside the PoE1 allowlist",
    rule: "citation.not_allowlisted",
    path: "research",
    action: "re-ask",
    contaminatedUrls: neutral.map((entry) => entry.url),
  };
}
