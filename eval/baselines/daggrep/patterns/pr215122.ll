define i32 @src(i32 %a, i32 %cstcm) {
  %neg = sub i32 0, %a
  %and = and i32 %neg, %cstcm
  %add = add i32 %a, %and
  ret i32 %add
}
