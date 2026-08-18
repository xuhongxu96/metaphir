import os

import lit.formats

config.name = "MetaphIR"
config.test_format = lit.formats.ShTest()
config.suffixes = [".ll"]
config.test_source_root = os.path.dirname(__file__)
config.substitutions.append(("%metaphir-lex", lit_config.params["metaphir_lex"]))
config.substitutions.append(("%metaphir-parse", lit_config.params["metaphir_parse"]))
config.substitutions.append(
    ("%metaphir-match", lit_config.params.get("metaphir_match", "metaphir-match"))
)
config.environment["PATH"] = os.path.pathsep.join(
    [config.llvm_tools_dir, config.environment.get("PATH", "")]
)
