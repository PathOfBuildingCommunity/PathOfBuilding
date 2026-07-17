export type PolicyAllow = { kind: "allowed" };

export type PolicyRefusal = {
  kind: "refused";
  reason: string;
  rule: string;
  path?: "apply" | "research";
  action?: "re-ask";
  contaminatedUrls?: string[];
  rejectedOps?: ApplyOp[];
};

export type PolicyOutcome = PolicyAllow | PolicyRefusal;

export type AllowlistPolicy = {
  version: number;
  hosts: string[];
  path_prefixes: string[];
};

export type DenylistPolicy = {
  version: number;
  hosts: string[];
  path_prefixes: string[];
};

export type ExclusionPolicy = {
  version: number;
  denied_forum_ids: string[];
  deny_version_patterns: string[];
};

export type PolicyPack = {
  allowlist: AllowlistPolicy;
  denylist: DenylistPolicy;
  exclusion: ExclusionPolicy;
};

export type ApplyOp = {
  surface: "skills" | "items" | "tree" | "config";
  entityId?: string;
  entityName?: string;
};

export type UrlClassification = "allow" | "deny" | "neutral";
