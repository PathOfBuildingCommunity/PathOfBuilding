import { describe, expect, it } from "vitest";
import { evaluateApplyOps } from "../src/policy/apply.js";
import type { ApplyOp } from "../src/policy/types.js";

const knownPoe1Ids = new Set(["Metadata/Items/Gems/GemDexterity3"]);
const knownBuildNames = new Set(["Spark", "Arc"]);

describe("same-name Apply refuse (fail-closed)", () => {
  it("allows ops referencing entities present in PoB by id and name", () => {
    const ops: ApplyOp[] = [
      {
        surface: "skills",
        entityId: "Metadata/Items/Gems/GemDexterity3",
        entityName: "Spark",
      },
    ];
    const result = evaluateApplyOps(ops, knownPoe1Ids, knownBuildNames);
    expect(result).toEqual({ kind: "allowed" });
  });

  it("hard-refuses unknown entity id (possible PoE2 smuggle)", () => {
    const ops: ApplyOp[] = [
      {
        surface: "skills",
        entityId: "Metadata/Items/Gems/PoE2OnlyGem",
        entityName: "Spark",
      },
    ];
    const result = evaluateApplyOps(ops, knownPoe1Ids, knownBuildNames);
    expect(result).toMatchObject({
      kind: "refused",
      reason: expect.stringMatching(/unknown|PoE2|id/i),
      path: "apply",
    });
  });

  it("hard-refuses same-named skill absent from build (Spark collision)", () => {
    const ops: ApplyOp[] = [
      { surface: "skills", entityName: "Lightning Strike" },
    ];
    const result = evaluateApplyOps(ops, knownPoe1Ids, knownBuildNames);
    expect(result).toMatchObject({
      kind: "refused",
      reason: expect.stringMatching(/same-name|Lightning Strike|PoE2/i),
      path: "apply",
    });
  });

  it("does not partially apply — entire proposal refused", () => {
    const ops: ApplyOp[] = [
      { surface: "skills", entityId: "Metadata/Items/Gems/GemDexterity3", entityName: "Spark" },
      { surface: "skills", entityName: "Ball Lightning" },
    ];
    const result = evaluateApplyOps(ops, knownPoe1Ids, knownBuildNames);
    expect(result.kind).toBe("refused");
    if (result.kind === "refused" && result.rejectedOps) {
      expect(result.rejectedOps).toHaveLength(1);
      expect(result.rejectedOps[0]?.entityName).toBe("Ball Lightning");
    }
  });

  it("refusal is explicit — no silent stripping of bad ops", () => {
    const ops: ApplyOp[] = [{ surface: "items", entityName: "Tabula Rasa" }];
    const result = evaluateApplyOps(ops, knownPoe1Ids, knownBuildNames);
    expect(result.kind).toBe("refused");
    if (result.kind === "refused") {
      expect(result.reason.length).toBeGreaterThan(0);
      expect(result.rejectedOps?.length).toBeGreaterThan(0);
    }
  });
});
