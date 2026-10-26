define i64 @src(i64 %x) {
  %trunc = trunc nsw i64 %x to i32
  %ext = sext i32 %trunc to i64
  ret i64 %ext
}
