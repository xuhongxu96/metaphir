//===- Emit.h - Writing self-contained headers ---------------------------===//
//
// What the backends share: each output is a header that can be #included at
// file scope and used as is, so it carries its own guard, #includes and
// namespaces.
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_TOOLS_TBLGEN_EMIT_H
#define METAPHIR_TOOLS_TBLGEN_EMIT_H

#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/STLFunctionalExtras.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/TableGen/Error.h"
#include "llvm/TableGen/Record.h"
#include "llvm/TableGen/TableGenBackend.h"

namespace metaphir_tblgen {

/// Opens a header: the banner, the guard, Includes, and the namespaces
/// llvm::metaphir::<Namespaces...>.
inline void beginHeader(llvm::raw_ostream &OS,
                        const llvm::RecordKeeper &Records,
                        llvm::StringRef Description, llvm::StringRef Guard,
                        llvm::ArrayRef<llvm::StringRef> Includes,
                        llvm::ArrayRef<llvm::StringRef> Namespaces = {}) {
  llvm::emitSourceFileHeader(Description, OS, Records);
  OS << "#ifndef " << Guard << "\n#define " << Guard << "\n\n";
  for (llvm::StringRef Include : Includes)
    OS << "#include \"" << Include << "\"\n";
  OS << "\nnamespace llvm {\nnamespace metaphir {\n";
  for (llvm::StringRef Namespace : Namespaces)
    OS << "namespace " << Namespace << " {\n";
  OS << "\n";
}

inline void endHeader(llvm::raw_ostream &OS, llvm::StringRef Guard,
                      llvm::ArrayRef<llvm::StringRef> Namespaces = {}) {
  for (llvm::StringRef Namespace : llvm::reverse(Namespaces))
    OS << "} // namespace " << Namespace << "\n";
  OS << "} // namespace metaphir\n} // namespace llvm\n\n#endif // " << Guard
     << "\n";
}

/// Writes `inline constexpr <Declaration> = { ... };`, an element per item,
/// written by Format. The generated files hold data like this; the code that
/// reads it is hand-written.
template <class Range, class Item = typename Range::value_type>
void emitArray(
    llvm::raw_ostream &OS, llvm::StringRef Declaration, const Range &Items,
    llvm::function_ref<void(llvm::raw_ostream &, const Item &)> Format) {
  OS << "inline constexpr " << Declaration << " = {\n";
  for (const Item &I : Items) {
    OS << "    ";
    Format(OS, I);
    OS << ",\n";
  }
  OS << "};\n\n";
}

} // namespace metaphir_tblgen

#endif
