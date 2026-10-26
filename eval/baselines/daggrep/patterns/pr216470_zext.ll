define i64 @src(i32 %x, i32 %cstmask, i32 %cstshift) {
  %and = and i32 %x, %cstmask
  %cmp = icmp ne i32 %and, 0
  %ext = zext i1 %cmp to i64
  %shr = lshr i32 %x, %cstshift
  %zext = zext i32 %shr to i64
  %add = add i64 %ext, %zext
  ret i64 %add
}
