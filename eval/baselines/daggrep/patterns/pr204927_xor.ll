define i64 @src(i64 %x, i32 %y) {
  %trunc = trunc nuw i64 %x to i32
  %logic = xor i32 %trunc, %y
  %zext = zext i32 %logic to i64
  ret i64 %zext
}
