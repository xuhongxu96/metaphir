# What reading features, postings and packed functions needs, for the web
# build too.
add_library(metaphir-index-core FeatureCoding.cpp FeatureCoding.h
                                FunctionPack.cpp FunctionPack.h Postings.cpp
                                Postings.h)

target_link_libraries(metaphir-index-core PUBLIC metaphir-matching LLVMBitReader
                                                 LLVMCore LLVMSupport)

add_library(metaphir-index-lib CorpusIndex.cpp CorpusIndex.h FunctionPacker.cpp
                               FunctionPacker.h)

target_link_libraries(
  metaphir-index-lib PUBLIC metaphir-index-core LLVMBitWriter LLVMIRReader
                            LLVMTransformUtils LLVMCore LLVMSupport)
