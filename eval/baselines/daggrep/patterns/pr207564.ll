define i64 @src(i64 %x) {
  %trunc = trunc i64 %x to i32
  %sub = sub i32 0, %trunc
  %zext = zext i32 %sub to i64
  ret i64 %zext
}
