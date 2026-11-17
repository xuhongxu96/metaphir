# The build-time generator for the language's tables (metaphir/**/*.td).
add_executable(metaphir-tblgen
  main.cpp
  CoercionEmitter.cpp
  ConstantClassEmitter.cpp
  ConstraintEmitter.cpp
  FactEmitter.cpp
  InstructionEmitter.cpp
  KeywordConstantEmitter.cpp
  MetaFlagEmitter.cpp
  PatternSettingEmitter.cpp
  PrimitiveTypeEmitter.cpp
  SortEmitter.cpp
  TokenEmitter.cpp
  WebKeywordEmitter.cpp
)
target_link_libraries(metaphir-tblgen PRIVATE LLVMTableGen LLVMSupport)
