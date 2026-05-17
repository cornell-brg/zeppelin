# Microbenchmark Suite (ubmark)

Benchmarks for evaluating the Zeppelin superscalar processor.  Each program
runs a single kernel and reports **cycle count**, **instruction count**, and
**CPI** (cycles per instruction -- lower means the processor is doing more
useful work per clock tick).  All results are validated against precomputed
reference values.

Benchmarks that compare two variants of the same computation are split into
separate programs (e.g., `branchloop-branchy` and `branchloop-branchless`).

## Building and Running

```bash
source setup-brg.sh
cd build
make v11-sim -j
make app-<benchmark>
./v11-sim +elf=app/<benchmark>
```

---

## Benchmarks

### branchloop-branchy / branchloop-branchless

Classifies 128 numbers into three "bins" (low, medium, high) based on two
thresholds.

- **branchloop-branchy**: uses if/else statements to decide which bin each
  number belongs to.  Every wrong guess about which way the if/else will go
  forces the processor to throw away partially-done work and start over (a
  "pipeline squash").
- **branchloop-branchless**: uses arithmetic tricks to compute the same bin
  assignment without any if/else.  No squashes, so the pipeline stays full.

**What matters here:** branch prediction (or the lack of it).  The branchless
variant avoids the penalty entirely, showing how costly unpredictable branches
are.

---

### bsearch

Searches for 20 keys in a sorted 1000-element array using binary search.
Each step cuts the search range in half, but the direction of each cut depends
on the data, making every comparison an unpredictable branch.

**What matters here:** branch misprediction.  Binary search is inherently
branch-heavy, so this benchmark exposes the cost of frequent pipeline
squashes.

---

### crc32-bitwise / crc32-table

Computes a CRC-32 checksum -- an error-detection code commonly used in
networking and file storage -- over a 256-byte message.

- **crc32-bitwise**: processes one bit at a time.  Each bit requires a shift
  and a conditional XOR, producing 8 branches per byte (2048 total).
- **crc32-table**: uses a precomputed 256-entry lookup table to process one
  whole byte at a time.  One memory load and one XOR per byte, no branches
  at all.

**What matters here:** branch cost vs. memory access cost.  The table variant
eliminates all branches but needs a table load on every byte.  On a processor
with no branch predictor, eliminating 2048 branches easily outweighs the cost
of 256 table lookups.

---

### depchain-serial / depchain-multi

Computes a dot product (multiply each pair of corresponding elements, then
add them all up).

- **depchain-serial**: uses a single running total.  Each multiply-add must
  wait for the previous one to finish because it feeds into the same
  accumulator -- creating a long chain of dependent operations.
- **depchain-multi**: uses four separate running totals that are combined at
  the end.  The four chains are independent, so the processor can overlap
  them.

**What matters here:** instruction-level parallelism (ILP).  The multi-chain
variant gives the out-of-order engine independent work to do, while the
serial variant forces it to wait.

---

### fir-naive / fir-unrolled

Applies a 16-tap FIR filter to 256 signal samples.  This is a sliding-window
dot product: for each output sample, multiply 16 consecutive input samples by
16 fixed weights and sum the results.  FIR filters are fundamental to audio
processing, radio, and sensor data smoothing.

- **fir-naive**: one multiply-add per inner loop iteration, creating a serial
  dependency chain.
- **fir-unrolled**: four multiply-adds per iteration using four independent
  accumulators.  The processor can feed these to both multiply pipes in
  parallel.

**What matters here:** multiply pipe utilization.  The processor has two
multiply units, but the naive version can only keep one busy.  Unrolling
exposes enough parallelism to use both.

---

### ifft-naive / ifft-radix2

Transforms 32 frequency-domain values back to the time domain using a
fixed-point inverse FFT -- the same operation at the heart of audio codecs,
image compression (JPEG), and wireless communication.  All arithmetic uses
integers scaled by 1024 instead of floating point.

- **ifft-naive**: for each of the 32 output values, loops over all 32 input
  values and multiplies by the appropriate twiddle factor.  This is
  O(N^2) = 1024 multiply-adds, but each output's computation is independent
  of the others, giving the processor many parallel chains to overlap.
- **ifft-radix2**: the classic "fast" algorithm that reorganises the
  computation into 5 stages of "butterfly" operations, reducing total work
  to O(N*log N) = 160 operations.  However, each stage depends on the
  previous one, creating dependency barriers.

**What matters here:** total work vs. parallelism.  The radix-2 version does
far less work (fewer total cycles), but the naive version may achieve better
CPI because it has more independent operations to overlap.

---

### isortsearch-insertion / isortsearch-selection

Sorts 64 numbers that start in reverse order (worst case).

- **isortsearch-insertion**: repeatedly picks the next unsorted element and
  shifts everything larger one position to the right.  The inner loop has a
  data-dependent branch (stop shifting when you find a smaller element),
  a load and store on every shift, and each shift depends on the previous
  one -- all three of the processor's main weaknesses at once.
- **isortsearch-selection**: scans the unsorted portion for the minimum, then
  swaps it into place.  The inner loop only loads and compares (no stores
  until the swap), giving the out-of-order engine a chance to overlap
  operations.

**What matters here:** the combined penalty of branches, memory traffic, and
serial dependencies.  Insertion sort on reverse-sorted data hits all three
weaknesses simultaneously.

---

### matmul-naive / matmul-tiled

Multiplies two 16x16 integer matrices -- a fundamental operation in graphics,
physics simulations, and machine learning.

- **matmul-naive**: the textbook triple-nested loop.  One multiply-add per
  inner iteration, producing a single serial dependency chain.
- **matmul-tiled**: processes 2x2 blocks at a time, accumulating four
  independent partial sums in the inner loop.  The four multiply-add chains
  are independent, so both multiply pipes and the out-of-order engine can
  overlap them.

**What matters here:** multiply pipe utilization and ILP.  The tiled version
exposes four independent multiply-accumulate chains instead of one, letting
both multiply pipes stay busy.

---

### memcopy-memheavy / memcopy-compheavy

Processes 128 integers in a load-compute-store pattern.

- **memcopy-memheavy**: loads a value, adds 7, and stores the result.  Almost
  all of the work is memory operations, and the processor has only a single
  load/store unit -- so the other seven execution pipes sit idle.
- **memcopy-compheavy**: loads a value, applies a long chain of multiplies,
  shifts, and XORs, then stores the result.  The execution pipes are busy
  between each load and store.

**What matters here:** load/store unit bottleneck.  Despite having eight
execution pipes, the processor can only do one memory operation at a time.
The memory-heavy variant is bottlenecked on this single pipe, while the
compute-heavy variant keeps the other pipes busy.

---

### mulchain-single / mulchain-dual

Evaluates a degree-7 polynomial (a formula like
c0 + c1*x + c2*x^2 + ... + c7*x^7) on 64 data points using Horner's method
(a technique that reduces the computation to a chain of multiply-adds).

- **mulchain-single**: evaluates one polynomial, creating one serial multiply
  chain.  Each multiply depends on the previous result, so only one multiply
  pipe can be used.
- **mulchain-dual**: evaluates two different polynomials simultaneously in the
  same loop.  The two chains are independent, so the processor can feed them
  to both multiply pipes.

**What matters here:** dual multiply pipe utilization.  The processor has two
multiply units, but a single serial chain can only use one.  Interleaving
two independent chains lets both pipes work at the same time.

---

### ptrchase-onechain / ptrchase-twochains

Follows chains of "pointers" (each element tells you which element to visit
next), similar to traversing a linked list.

- **ptrchase-onechain**: follows a single pointer chain.  Each load depends on
  the previous load's result (to know the next address), so loads cannot
  overlap.
- **ptrchase-twochains**: follows two independent pointer chains interleaved
  in one loop.  While one load is waiting for memory, the processor can issue
  the other chain's load.

**What matters here:** out-of-order memory issue.  The processor can issue
independent loads even while a previous load is still pending, which the
two-chain variant exploits.

---

### regpress-low / regpress-high

Accumulates over 128 numbers using different numbers of independent running
totals ("accumulators").

- **regpress-low**: 4 accumulators (add, XOR, squared-sum, subtract).  These
  easily fit within the processor's 36 physical registers.
- **regpress-high**: 16 accumulators.  This may exhaust the physical register
  file, causing the processor to stall while waiting for a register to become
  free ("rename stall").

**What matters here:** register pressure.  The processor can rename up to 36
physical registers.  When the number of simultaneously live values exceeds
this limit, the processor stalls -- even though there is plenty of
independent work available.

---

### stringsearch-byte / stringsearch-firstchar

Searches for the phrase "quick brown fox" in a 518-byte text, counting
how many times it appears.  This is the basic operation behind text editors'
"Find" feature and simple pattern matching.

- **stringsearch-byte**: at every position in the text, compare character by
  character against the pattern.  Each mismatch is a branch (stop comparing
  and move to the next position).
- **stringsearch-firstchar**: first check only the first character; only if it
  matches, compare the rest of the pattern.  This skips most positions
  immediately (the first character doesn't match), reducing the total number
  of comparisons and branches.

**What matters here:** branch cost on a per-character basis.  String search
is inherently branch-heavy (every character comparison is a potential
mismatch branch).  The firstchar variant reduces how often the processor
enters the inner comparison loop.

---

### vvadd

Adds corresponding elements of two 100-element integer arrays (vector-vector
add).

Each iteration is a simple load-load-add-store with no data dependencies
between iterations, making this an ideal baseline for measuring the
processor's throughput on simple, independent operations.

**What matters here:** baseline throughput.  This is the simplest possible
loop structure, so the CPI here represents the best-case scenario for the
processor's pipeline.

---

### vvmul

Multiplies corresponding elements of two integer arrays (vector-vector
multiply).  Uses 100 elements, same data as `vvadd`.

Each iteration is a load-load-multiply-store with no data dependencies
between iterations.  Similar to `vvadd` but exercises the multiply pipe
instead of the ALU pipe.

**What matters here:** multiply throughput baseline.  Like `vvadd`, there are
no inter-iteration dependencies, so the CPI here reflects how efficiently the
processor can sustain multiply operations in a simple loop.

---

### widealu-narrow / widealu-wide

Transforms 256 integers with the formula `(value + 17) XOR 0x55`.

- **widealu-narrow**: one element per loop iteration.  Although each element
  is independent, the loop overhead (branch, increment, compare) limits how
  much work the processor can issue per cycle.
- **widealu-wide**: processes 8 elements per iteration (loop unrolling).  The
  eight operations are independent, so all four ALU pipes can stay busy while
  the loop overhead is amortised over 8x more work.

**What matters here:** ALU pipe saturation.  The processor has four ALU
(arithmetic/logic) pipes, but a one-element-per-iteration loop cannot
fill them all.  Unrolling exposes enough independent work to keep all
four busy.
