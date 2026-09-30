#ifndef METAPHIR_INDEX_FEATURECODING_H
#define METAPHIR_INDEX_FEATURECODING_H

#include "metaphir/Matching/Features.h"
#include "llvm/ADT/STLFunctionalExtras.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Support/DataExtractor.h"
#include "llvm/Support/Error.h"
#include <string>

namespace llvm {
class raw_ostream;
namespace metaphir {

// How indexes store features: numbers as ULEB128, sorted keys as their
// deltas, and the fine features behind their size, so that readers can skip
// them.

void writeString(raw_ostream &OS, StringRef String);
StringRef readString(DataExtractor &Data, DataExtractor::Cursor &C);

/// Writes the instructions, edges and siblings of Features.
void writeCoarseFeatures(raw_ostream &OS, const FunctionFeatures &Features);
/// Reads what writeCoarseFeatures wrote. Returns false if the keys are not
/// valid.
bool readCoarseFeatures(DataExtractor &Data, DataExtractor::Cursor &C,
                        FunctionFeatures &Features);

/// Writes the signatures, facts and measures of Features.
void writeFineFeatures(raw_ostream &OS, const FunctionFeatures &Features);
/// Reads what writeFineFeatures wrote if NeedsFine, given the coarse
/// features, asks for it; otherwise skips it. Returns false if the features
/// are not valid.
bool readFineFeatures(DataExtractor &Data, DataExtractor::Cursor &C,
                      FunctionFeatures &Features,
                      function_ref<bool(const FunctionFeatures &)> NeedsFine);

/// Writes all of a function's features, globals included, on their own.
void writeFunctionFeatures(raw_ostream &OS, const FunctionFeatures &Features);
/// Reads what writeFunctionFeatures wrote.
Expected<FunctionFeatures> readFunctionFeatures(StringRef Data);

/// What recorded features mean: the instruction matcher names in ID order,
/// the fact and measure vocabulary, the type encoding, and the LLVM
/// revision, whose value tracking the facts come from.
SmallVector<std::string, 96> getFeatureSchema();

} // namespace metaphir
} // namespace llvm

#endif
