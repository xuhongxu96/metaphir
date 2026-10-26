define i1 @src(i32 %x, i32 %cstd, i32 %cstc) {
  %rem = urem i32 %x, %cstd
  %aligned = sub i32 %x, %rem
  %icmp = icmp ugt i32 %aligned, %cstc
  ret i1 %icmp
}
