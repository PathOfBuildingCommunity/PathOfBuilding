import { describe, expect, it } from "vitest";
import { evaluateUrl } from "../src/policy/url.js";
import { loadPolicyPack } from "../src/policy/load.js";
import path from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  "../..",
);

describe("URL/domain deny (fail-closed)", () => {
  const policy = loadPolicyPack(repoRoot);

  it("allows PoE1 patch notes forum", () => {
    const result = evaluateUrl(
      "https://www.pathofexile.com/forum/view-forum/patch-notes",
      policy,
    );
    expect(result).toEqual({ kind: "allowed" });
  });

  it("allows poewiki.net", () => {
    const result = evaluateUrl("https://www.poewiki.net/wiki/Spark", policy);
    expect(result).toEqual({ kind: "allowed" });
  });

  it("allows poe.ninja/poe1 paths", () => {
    const result = evaluateUrl(
      "https://poe.ninja/poe1/api/data/index-state",
      policy,
    );
    expect(result).toEqual({ kind: "allowed" });
  });

  it("refuses pathofexile2.com explicitly", () => {
    const result = evaluateUrl("https://pathofexile2.com/news/rss", policy);
    expect(result.kind).toBe("refused");
    if (result.kind === "refused") {
      expect(result.reason).toMatch(/PoE2|denylist/i);
      expect(result.rule).toBeTruthy();
    }
  });

  it("refuses poe2wiki.net explicitly", () => {
    const result = evaluateUrl("https://www.poe2wiki.net/wiki/Spark", policy);
    expect(result).toMatchObject({
      kind: "refused",
      reason: expect.stringMatching(/PoE2|denylist/i),
    });
  });

  it("refuses poe.ninja/poe2 paths", () => {
    const result = evaluateUrl("https://poe.ninja/poe2/builds", policy);
    expect(result.kind).toBe("refused");
  });

  it("refuses GGG forum 2212 (PoE2 Early Access patch notes)", () => {
    const result = evaluateUrl(
      "https://www.pathofexile.com/forum/view-forum/2212",
      policy,
    );
    expect(result).toMatchObject({
      kind: "refused",
      reason: expect.stringMatching(/2212|PoE2|denylist/i),
    });
  });

  it("refuses maxroll.gg/poe2/", () => {
    const result = evaluateUrl("https://maxroll.gg/poe2/builds", policy);
    expect(result.kind).toBe("refused");
  });

  it("refuses non-allowlisted hosts explicitly", () => {
    const result = evaluateUrl("https://www.youtube.com/watch?v=example", policy);
    expect(result).toMatchObject({
      kind: "refused",
      rule: "allowlist.missing",
    });
  });

  it("does not silently strip — denial carries rule id and reason", () => {
    const result = evaluateUrl("https://poe2db.tw/us/Lightning_Strike", policy);
    expect(result.kind).toBe("refused");
    if (result.kind === "refused") {
      expect(result.rule).toBeTruthy();
      expect(result.reason.length).toBeGreaterThan(0);
    }
  });
});
