define i32 @src(i32 noundef %x, i32 %cst0, i32 %cstk) {
  %div = udiv i32 %x, %cst0
  %divshl = shl i32 %div, %cstk
  %rem = urem i32 %x, %cst0
  %add = add i32 %rem, %divshl
  ret i32 %add
}
