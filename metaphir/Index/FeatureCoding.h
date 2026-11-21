#ifndef METAPHIR_INDEX_FEATURECODING_H
#define METAPHIR_INDEX_FEATURECODING_H

#include "metaphir/Matching/Features.h"
#include "llvm/ADT/STLFunctionalExtras.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Support/DataExtractor.h"
#include "llvm/Support/Error.h"
#include "llvm/Support/LogicalResult.h"
#include <string>

namespace llvm {
class raw_ostream;
namespace metaphir {

// How indexes store features: numbers as ULEB128, sorted keys as their
// deltas, and the detail features behind their size, so that readers can skip
// them.

void writeString(raw_ostream &OS, StringRef String);
StringRef readString(DataExtractor &Data, DataExtractor::Cursor &C);

/// Writes the instructions, edges and siblings of Features.
void writePostedFeatures(raw_ostream &OS, const FunctionFeatures &Features);
/// Reads what writePostedFeatures wrote. Fails if the keys are not valid.
LogicalResult readPostedFeatures(DataExtractor &Data, DataExtractor::Cursor &C,
                                 FunctionFeatures &Features);

/// Writes the signatures, facts and measures of Features.
void writeDetailFeatures(raw_ostream &OS, const FunctionFeatures &Features);
/// Reads what writeDetailFeatures wrote if NeedsDetail, given the posted
/// features, asks for it; otherwise skips it. Fails if the features are not
/// valid.
LogicalResult
readDetailFeatures(DataExtractor &Data, DataExtractor::Cursor &C,
                   FunctionFeatures &Features,
                   function_ref<bool(const FunctionFeatures &)> NeedsDetail);

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
