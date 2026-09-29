add_library(metaphir-index-lib CorpusIndex.cpp CorpusIndex.h)

target_link_libraries(metaphir-index-lib PUBLIC metaphir-matching LLVMIRReader
                                                LLVMCore LLVMSupport)
