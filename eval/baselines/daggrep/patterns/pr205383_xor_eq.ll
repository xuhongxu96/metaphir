define i32 @src(i32 %x, i32 %bits, i32 %cstbm1) {
  %neg = sub i32 0, %x
  %and = and i32 %neg, %x
  %ctlz = call noundef i32 @llvm.ctlz.i32(i32 %and, i1 false)
  %r = xor i32 %ctlz, %cstbm1
  %cmp = icmp eq i32 %x, 0
  %sel = select i1 %cmp, i32 %bits, i32 %r
  ret i32 %sel
}
