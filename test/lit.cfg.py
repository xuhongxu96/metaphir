import os

import lit.formats

config.name = "MetaphIR"
config.test_format = lit.formats.ShTest()
config.suffixes = [".ll"]
config.test_source_root = os.path.dirname(__file__)
config.test_exec_root = os.path.join(config.metaphir_obj_root, "lit")

for tool in ("metaphir-lex", "metaphir-parse", "metaphir-match", "metaphir-index"):
    param = tool.replace("-", "_")
    path = lit_config.params.get(param)
    if path is None:
        lit_config.fatal(f"missing lit parameter: -D {param}=<path to {tool}>")
    config.substitutions.append((f"%{tool}", path))

config.environment["PATH"] = os.path.pathsep.join(
    [config.llvm_tools_dir, config.environment.get("PATH", "")]
)
