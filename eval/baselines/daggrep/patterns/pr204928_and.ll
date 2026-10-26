define i64 @src(i64 %x, i32 %y) {
  %trunc = trunc nsw i64 %x to i32
  %logic = and i32 %trunc, %y
  %sext = sext i32 %logic to i64
  ret i64 %sext
}
