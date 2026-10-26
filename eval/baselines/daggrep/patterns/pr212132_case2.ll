define i32 @src(i32 %shift, i32 %a, i32 %b) {
  %and1 = and i32 %shift, %a
  %cmp1 = icmp ne i32 %and1, 0
  %and2 = and i32 %shift, %b
  %cmp2 = icmp ne i32 %and2, 0
  %cond = and i1 %cmp1, %cmp2
  %sel = select i1 %cond, i32 %shift, i32 0
  ret i32 %sel
}
