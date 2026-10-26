define i32 @src(i32 %x) {
  %cttz = call noundef i32 @llvm.cttz.i32(i32 %x, i1 false)
  %shl = shl i32 1, %cttz
  ret i32 %shl
}
