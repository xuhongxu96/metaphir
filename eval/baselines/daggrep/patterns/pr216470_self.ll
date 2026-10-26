define i32 @src(i32 %x, i32 %cstmask, i32 %cstshift) {
  %and = and i32 %x, %cstmask
  %cmp = icmp ne i32 %and, 0
  %ext = zext i1 %cmp to i32
  %shr = lshr i32 %x, %cstshift
  %add = add i32 %ext, %shr
  ret i32 %add
}
