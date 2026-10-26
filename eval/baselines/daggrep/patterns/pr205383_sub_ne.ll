define i32 @src(i32 %x, i32 %bits, i32 %cstbm1) {
  %neg = sub i32 0, %x
  %and = and i32 %neg, %x
  %ctlz = call noundef i32 @llvm.ctlz.i32(i32 %and, i1 false)
  %r = sub i32 %cstbm1, %ctlz
  %cmp = icmp ne i32 %x, 0
  %sel = select i1 %cmp, i32 %r, i32 %bits
  ret i32 %sel
}
