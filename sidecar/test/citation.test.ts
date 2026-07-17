import { describe, expect, it } from "vitest";
import { evaluateCitations } from "../src/policy/citation.js";
import { loadPolicyPack } from "../src/policy/load.js";
import path from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  "../..",
);

describe("mixed citation refuse (fail-closed)", () => {
  const policy = loadPolicyPack(repoRoot);

  it("allows answer with only PoE1 citations", () => {
    const result = evaluateCitations(
      [
        "https://www.poewiki.net/wiki/Spark",
        "https://www.pathofexile.com/forum/view-forum/patch-notes",
      ],
      policy,
    );
    expect(result).toEqual({ kind: "allowed" });
  });

  it("refuses when PoE1 and PoE2 links appear together", () => {
    const result = evaluateCitations(
      [
        "https://www.poewiki.net/wiki/Spark",
        "https://www.poe2wiki.net/wiki/Spark",
      ],
      policy,
    );
    expect(result).toMatchObject({
      kind: "refused",
      reason: expect.stringMatching(/mixed/i),
      action: "re-ask",
    });
  });

  it("refuses PoE2-only answer explicitly (not silent strip)", () => {
    const result = evaluateCitations(
      ["https://pathofexile2.com/news/rss"],
      policy,
    );
    expect(result.kind).toBe("refused");
    if (result.kind === "refused") {
      expect(result.reason).toBeTruthy();
      expect(result.contaminatedUrls).toContain(
        "https://pathofexile2.com/news/rss",
      );
    }
  });

  it("extracts URLs from prose and refuses mixed citations", () => {
    const text = `
      Spark works differently in PoE1 (see https://www.poewiki.net/wiki/Spark)
      vs PoE2 (see https://www.poe2wiki.net/wiki/Spark for comparison).
    `;
    const result = evaluateCitations(text, policy);
    expect(result).toMatchObject({
      kind: "refused",
      reason: expect.stringMatching(/mixed/i),
      action: "re-ask",
    });
  });

  it("does not show PoE2 link as allowed when mixed — full refuse", () => {
    const result = evaluateCitations(
      [
        "https://poe.ninja/poe1/builds",
        "https://poe.ninja/poe2/builds",
      ],
      policy,
    );
    expect(result.kind).toBe("refused");
    if (result.kind === "refused") {
      expect(result.contaminatedUrls).toEqual(
        expect.arrayContaining(["https://poe.ninja/poe2/builds"]),
      );
    }
  });
});
