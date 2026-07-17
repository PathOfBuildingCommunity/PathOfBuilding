import type { PolicyOutcome, PolicyPack, UrlClassification } from "./types.js";
import {
  matchesForumId,
  matchesHost,
  matchesPathPrefix,
  normalizeUrl,
} from "./load.js";

export function classifyUrl(
  rawUrl: string,
  policy: PolicyPack,
): UrlClassification {
  const { host, pathKey } = normalizeUrl(rawUrl);

  if (matchesForumId(rawUrl, policy.exclusion.denied_forum_ids)) {
    return "deny";
  }

  if (
    matchesHost(host, policy.denylist.hosts) ||
    matchesPathPrefix(pathKey, policy.denylist.path_prefixes)
  ) {
    return "deny";
  }

  if (
    matchesHost(host, policy.allowlist.hosts) ||
    matchesPathPrefix(pathKey, policy.allowlist.path_prefixes)
  ) {
    return "allow";
  }

  return "neutral";
}

export function evaluateUrl(rawUrl: string, policy: PolicyPack): PolicyOutcome {
  const classification = classifyUrl(rawUrl, policy);

  if (classification === "deny") {
    const forumId = matchesForumId(rawUrl, policy.exclusion.denied_forum_ids);
    if (forumId) {
      return {
        kind: "refused",
        reason: `PoE2 Early Access forum ${forumId} is denylisted for PoE1 agent`,
        rule: `exclusion.forum.${forumId}`,
      };
    }

    const { host, pathKey } = normalizeUrl(rawUrl);
    return {
      kind: "refused",
      reason: `URL is on the PoE2/denylist: ${host}${pathKey.slice(host.length) || "/"}`,
      rule: "denylist.url",
    };
  }

  if (classification === "neutral") {
    const { host } = normalizeUrl(rawUrl);
    return {
      kind: "refused",
      reason: `URL host is not on the PoE1 allowlist: ${host}`,
      rule: "allowlist.missing",
    };
  }

  return { kind: "allowed" };
}

export function evaluateUrls(
  urls: string[],
  policy: PolicyPack,
): PolicyOutcome {
  for (const url of urls) {
    const result = evaluateUrl(url, policy);
    if (result.kind === "refused") {
      return result;
    }
  }
  return { kind: "allowed" };
}

export function evaluateVersionString(
  version: string,
  policy: PolicyPack,
): PolicyOutcome {
  for (const pattern of policy.exclusion.deny_version_patterns) {
    const regex = new RegExp(pattern);
    if (regex.test(version)) {
      return {
        kind: "refused",
        reason: `Version "${version}" matches PoE2 Early Access pattern (${pattern})`,
        rule: "exclusion.version_pattern",
      };
    }
  }
  return { kind: "allowed" };
}
