define i32 @src(i32 %x, i32 %cstc) {
  %mul = mul i32 %x, %cstc
  %call = call noundef i32 @llvm.cttz.i32(i32 %mul, i1 false)
  ret i32 %call
}
