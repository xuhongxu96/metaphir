define i32 @src(i32 %shift, i32 %a, i32 %b) {
  %and1 = and i32 %shift, %a
  %cmp1 = icmp eq i32 %and1, 0
  %and2 = and i32 %shift, %b
  %cmp2 = icmp eq i32 %and2, 0
  %cond = or i1 %cmp1, %cmp2
  %sel = select i1 %cond, i32 0, i32 %shift
  ret i32 %sel
}
