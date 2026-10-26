define i32 @src(i32 %x) {
  %call = call noundef i32 @llvm.scmp.i32.i32(i32 %x, i32 0)
  ret i32 %call
}
