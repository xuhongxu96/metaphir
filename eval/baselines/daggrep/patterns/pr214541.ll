define i32 @src(i32 %x, i32 %y, i32 %z) {
  %udiv1 = udiv i32 %x, %y
  %udiv = udiv i32 %udiv1, %z
  ret i32 %udiv
}
