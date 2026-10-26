define i32 @src(i32 %x, i32 %cstc, i32 %cstnegc) {
  %sat = call noundef i32 @llvm.uadd.sat.i32(i32 %x, i32 %cstc)
  %add = add i32 %sat, %cstnegc
  ret i32 %add
}
