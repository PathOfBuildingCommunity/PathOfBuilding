import { describe, expect, it } from "vitest";
import { evaluateVersionString } from "../src/policy/url.js";
import { loadPolicyPack } from "../src/policy/load.js";
import path from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  "../..",
);

describe("version pattern exclusion", () => {
  const policy = loadPolicyPack(repoRoot);

  it("refuses PoE2 Early Access 0.x version strings", () => {
    const result = evaluateVersionString("0.5.4c", policy);
    expect(result).toMatchObject({
      kind: "refused",
      reason: expect.stringMatching(/0\.5\.4c|PoE2/i),
      rule: "exclusion.version_pattern",
    });
  });

  it("allows PoE1 3.x version strings", () => {
    const result = evaluateVersionString("3.29.0", policy);
    expect(result).toEqual({ kind: "allowed" });
  });
});
