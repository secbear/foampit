import { spawnSync } from "node:child_process";

const args = process.argv.slice(2).filter((argument) => argument !== "--");
const entrypoint = args[0];
if (entrypoint === undefined) {
  console.error("usage: pnpm emit -- <TypeSpec entrypoint> [tsp options]");
  process.exit(1);
}

const build = spawnSync("pnpm", ["build"], { stdio: "inherit" });
if (build.status !== 0) process.exit(build.status ?? 1);
const compile = spawnSync("./node_modules/.bin/tsp", ["compile", "--emit", "contract", entrypoint, ...args.slice(1)], { stdio: "inherit" });
if (compile.status !== 0) process.exit(compile.status ?? 1);
spawnSync("node", ["-e", "require('fs').rmSync('tsp-output',{recursive:true,force:true})"], { stdio: "inherit" });
