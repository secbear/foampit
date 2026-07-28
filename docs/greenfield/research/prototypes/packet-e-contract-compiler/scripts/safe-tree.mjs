import { lstat, realpath, rm } from "node:fs/promises";
import { isAbsolute, join, relative, resolve, sep } from "node:path";

const allowMissingFinalLeaf = Object.freeze({ allowMissingLeaf: true });

export async function removeBuildOutput(root) {
  return removeTreeSafely(root, "dist", allowMissingFinalLeaf);
}

export async function removeGeneratedGolden(root) {
  return removeTreeSafely(
    root,
    join("test", "golden", "generated"),
    allowMissingFinalLeaf,
  );
}

export async function removeTreeSafely(
  root,
  relativeTarget,
  { allowMissingLeaf },
) {
  const realRoot = await realpath(root);
  const rootStatus = await lstat(realRoot);
  if (rootStatus.isSymbolicLink() || !rootStatus.isDirectory()) {
    throw new Error("contract/removal-root-invalid");
  }

  const target = resolve(realRoot, relativeTarget);
  const relativeTargetPath = relative(realRoot, target);
  if (
    relativeTargetPath.length === 0 ||
    relativeTargetPath === ".." ||
    relativeTargetPath.startsWith(`..${sep}`) ||
    isAbsolute(relativeTargetPath)
  ) {
    throw new Error("contract/removal-path-outside-root");
  }

  const components = relativeTargetPath.split(sep);
  let current = realRoot;
  for (let index = 0; index < components.length; index += 1) {
    current = join(current, components[index]);
    const final = index === components.length - 1;
    let status;
    try {
      status = await lstat(current);
    } catch (error) {
      if (error?.code !== "ENOENT") throw error;
      if (final && allowMissingLeaf) return current;
      throw new Error(
        final
          ? "contract/removal-path-missing-leaf"
          : "contract/removal-path-missing-ancestor",
      );
    }
    if (status.isSymbolicLink()) {
      throw new Error("contract/removal-path-symlink");
    }
    if (!status.isDirectory()) {
      throw new Error(
        final
          ? "contract/removal-path-nondirectory-leaf"
          : "contract/removal-path-nondirectory-ancestor",
      );
    }
  }

  await rm(current, { recursive: true, force: false });
  return current;
}
