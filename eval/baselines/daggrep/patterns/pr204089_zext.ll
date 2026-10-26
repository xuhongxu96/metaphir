define i64 @src(i64 %x) {
  %trunc = trunc nuw i64 %x to i32
  %ext = zext i32 %trunc to i64
  ret i64 %ext
}
