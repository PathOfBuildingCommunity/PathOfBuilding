import type { ApplyOp, PolicyOutcome } from "./types.js";

export function evaluateApplyOps(
  ops: ApplyOp[],
  knownPoe1Ids: ReadonlySet<string>,
  knownBuildNames: ReadonlySet<string>,
): PolicyOutcome {
  const rejectedOps: ApplyOp[] = [];

  for (const op of ops) {
    if (op.entityId && !knownPoe1Ids.has(op.entityId)) {
      rejectedOps.push(op);
      continue;
    }

    if (!op.entityId && op.entityName && !knownBuildNames.has(op.entityName)) {
      rejectedOps.push(op);
    }
  }

  if (rejectedOps.length === 0) {
    return { kind: "allowed" };
  }

  const first = rejectedOps[0]!;
  const name = first.entityName ?? first.entityId ?? "unknown entity";

  if (first.entityId && !knownPoe1Ids.has(first.entityId)) {
    return {
      kind: "refused",
      reason: `Apply refused: unknown PoE1 entity id "${first.entityId}" (possible PoE2 smuggle)`,
      rule: "apply.unknown_id",
      path: "apply",
      rejectedOps,
    };
  }

  return {
    kind: "refused",
    reason: `Apply refused: same-named entity "${name}" is not present in the loaded build or PoE1 id set (PoE2 collision risk)`,
    rule: "apply.same_name",
    path: "apply",
    rejectedOps,
  };
}
