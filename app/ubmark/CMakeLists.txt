# ========================================================================
# CMakeLists.txt
# ========================================================================
# Specifying the files to build the microbenchmarks

set(APP_FILES
  branchloop-branchy.cpp
  branchloop-branchless.cpp
  bsearch.cpp
  crc32-bitwise.cpp
  crc32-table.cpp
  depchain-serial.cpp
  depchain-multi.cpp
  fir-naive.cpp
  fir-unrolled.cpp
  ifft-naive.cpp
  ifft-radix2.cpp
  isortsearch-insertion.cpp
  isortsearch-selection.cpp
  matmul-naive.cpp
  matmul-tiled.cpp
  memcopy-memheavy.cpp
  memcopy-compheavy.cpp
  mulchain-single.cpp
  mulchain-dual.cpp
  oooiq-demo.cpp
  ptrchase-onechain.cpp
  ptrchase-twochains.cpp
  regpress-low.cpp
  regpress-high.cpp
  stringsearch-byte.cpp
  stringsearch-firstchar.cpp
  vvadd.cpp
  vvmul.cpp
  widealu-narrow.cpp
  widealu-wide.cpp
  PARENT_SCOPE
)

set(SRC_FILES
  ubmark_stats.cpp
  PARENT_SCOPE
)
