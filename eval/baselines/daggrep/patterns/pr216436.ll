define i32 @src(i32 %x, i32 %cstcm) {
  %sub = add i32 %x, -1
  %or = or i32 %sub, %cstcm
  %add = add i32 %or, 1
  ret i32 %add
}
