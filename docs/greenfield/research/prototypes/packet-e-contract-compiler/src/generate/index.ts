import type { ContractModel } from "../model.js";
import { validateGeneratedFiles, type GeneratedFile } from "./common.js";
import { generateCue } from "./cue.js";
import { generateGo } from "./go.js";
import { generateOpenApi } from "./openapi.js";
import { generateProtobuf } from "./protobuf.js";
import { generatePython } from "./python.js";
import { generateQuint } from "./quint.js";
import { generateRust } from "./rust.js";
import { generateTypeScript } from "./typescript.js";
import { assertValidContractModel } from "../validate.js";

export function generateAll(
  model: Readonly<ContractModel>,
): readonly GeneratedFile[] {
  assertValidContractModel(model);
  return validateGeneratedFiles([
    ...generateRust(model),
    ...generateGo(model),
    ...generateTypeScript(model),
    ...generatePython(model),
    ...generateProtobuf(model),
    ...generateOpenApi(model),
    ...generateCue(model),
    ...generateQuint(model),
  ]);
}
