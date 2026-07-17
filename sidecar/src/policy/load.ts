import fs from "node:fs";
import path from "node:path";
import { parse as parseYaml } from "yaml";
import type {
  AllowlistPolicy,
  DenylistPolicy,
  ExclusionPolicy,
  PolicyPack,
} from "./types.js";

function readYamlFile<T>(filePath: string): T {
  const raw = fs.readFileSync(filePath, "utf8");
  return parseYaml(raw) as T;
}

export function loadPolicyPack(repoRoot: string): PolicyPack {
  const policyDir = path.join(repoRoot, "knowledge-pack", "policy");
  return {
    allowlist: readYamlFile<AllowlistPolicy>(
      path.join(policyDir, "allowlist.yaml"),
    ),
    denylist: readYamlFile<DenylistPolicy>(
      path.join(policyDir, "denylist.yaml"),
    ),
    exclusion: readYamlFile<ExclusionPolicy>(
      path.join(policyDir, "exclusion.yaml"),
    ),
  };
}

export function normalizeUrl(raw: string): { host: string; pathKey: string } {
  const withScheme = raw.includes("://") ? raw : `https://${raw}`;
  const url = new URL(withScheme);
  const host = url.hostname.replace(/^www\./, "").toLowerCase();
  const pathKey = `${host}${url.pathname}`.replace(/\/+$/, "").toLowerCase();
  return { host, pathKey };
}

export function matchesHost(host: string, candidates: string[]): boolean {
  return candidates.some(
    (candidate) => host === candidate || host.endsWith(`.${candidate}`),
  );
}

export function matchesPathPrefix(
  pathKey: string,
  prefixes: string[],
): boolean {
  return prefixes.some((prefix) => {
    const normalized = prefix.toLowerCase().replace(/\/+$/, "");
    return pathKey === normalized || pathKey.startsWith(`${normalized}/`);
  });
}

export function matchesForumId(
  rawUrl: string,
  deniedForumIds: string[],
): string | null {
  for (const forumId of deniedForumIds) {
    const pattern = new RegExp(`/forum/view-forum/${forumId}(?:/|$)`, "i");
    if (pattern.test(rawUrl)) {
      return forumId;
    }
  }
  return null;
}
