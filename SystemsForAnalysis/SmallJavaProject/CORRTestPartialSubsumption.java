public class CORRTestPartialSubsumption {
    public void methodX() { // Lines 3-7
        int i = 0;
        i++; // F1 start, F2 start
        i++;
        i++; // F1 end, F2 end
    }
    public void methodY() { // Lines 8-12
        int j = 0;
        j++; // F3 start, F4 start
        j++;
        j++; // F3 end, F4 end
    }
    public void methodZ() { // Lines 13-17
        int k = 0;
        k++; // F5 start
        k++;
        k++;
        k++; // F5 end
    }
}
// Clone Class 1 (C1): {F1, F3} - 3 statements
// Clone Class 2 (C2): {F2, F4} - 3 statements
// NOTE: C1 and C2 are the same (lines 4-6 and 9-11). If they contain the variable name, they are only Type II.
// Since variable names are different (i vs j), they are NOT Type I clones unless you strip identifiers.
// ASSUMPTION for Type I Test: If using AST normalization without identity masking:
// Clone Class 1 (C1): {Lines 4-6, Lines 9-11} (Exact AST subtree match)
// Clone Class 2 (C2): {Lines 4-6, Lines 14-16} (Exact AST subtree match) 
// The actual max clone is {Lines 4-6, Lines 9-11}. The max fragment size is 3 lines.

// Expected Filtered Stats: 1 CC, 2 Clones, Biggest Fragment: 3 lines