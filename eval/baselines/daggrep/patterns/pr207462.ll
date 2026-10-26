define i32 @src(i32 noundef %x) {
  %rem = and i32 %x, 1
  %div = lshr i32 %x, 1
  %add = add i32 %rem, %div
  ret i32 %add
}
