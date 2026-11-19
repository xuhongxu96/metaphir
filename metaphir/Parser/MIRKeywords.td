//===- MIRKeywords.td - The lexer's other keywords ------------*- tablegen -*-===//
//
// Keywords that no other table defines. Generated into MIRToken.inc by
// metaphir-tblgen -gen-tokens.
//
//===----------------------------------------------------------------------===//

include "metaphir/Parser/LexerBase.td"

def kw_x : Keyword<"x">;
def kw_ptr : Keyword<"ptr">;
def kw_vscale : Keyword<"vscale">;
def kw_align : Keyword<"align">;
def kw_addrspace : Keyword<"addrspace">;
def kw_inrange : Keyword<"inrange">;
def kw_to : Keyword<"to">;
def kw_match : Keyword<"match">;
def kw_constraint : Keyword<"constraint">;
def kw_metaflag : Keyword<"metaflag">;
def kw_let : Keyword<"let">;
def kw_Unary : Keyword<"Unary">;
def kw_Nary : Keyword<"Nary">;
def kw_Binary : Keyword<"Binary">;
def kw_Cast : Keyword<"Cast">;
