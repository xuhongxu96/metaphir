define i1 @src(i32 %x, i32 %y) {
  %shr = lshr exact i32 %x, %y
  %trunc = trunc nsw i32 %shr to i1
  ret i1 %trunc
}
