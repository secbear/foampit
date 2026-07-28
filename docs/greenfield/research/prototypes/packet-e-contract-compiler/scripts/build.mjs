import { realpath } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

import { removeBuildOutput } from "./safe-tree.mjs";

const packageRoot = await realpath(
  fileURLToPath(new URL("../", import.meta.url)),
);

await removeBuildOutput(packageRoot);
const result = spawnSync(
  fileURLToPath(new URL("../node_modules/.bin/tsc", import.meta.url)),
  ["--project", "tsconfig.build.json"],
  { cwd: packageRoot, stdio: "inherit" },
);
process.exit(result.status ?? 1);
