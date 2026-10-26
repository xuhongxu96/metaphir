define i1 @src(i32 %x) {
  %neg = sub i32 0, %x
  %and = and i32 %neg, %x
  %icmp = icmp eq i32 %and, 0
  ret i1 %icmp
}
