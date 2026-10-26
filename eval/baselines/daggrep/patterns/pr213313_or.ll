define i64 @src(i32 %x) {
  %zext = zext i32 %x to i64
  %sext = sext i32 %x to i64
  %or = or i64 %zext, %sext
  ret i64 %or
}
