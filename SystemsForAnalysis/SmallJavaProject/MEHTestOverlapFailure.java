public class MEHTestOverlapFailure {
    public void methodP() { // Lines 3-7
        System.out.println("A");
        System.out.println("B"); // F1 start
        System.out.println("C");
        System.out.println("D"); // F1 end
    }
    public void methodQ() { // Lines 8-12
        System.out.println("A"); // F2 start
        System.out.println("B"); // F3 start
        System.out.println("C");
        System.out.println("D"); // F2 end
        System.out.println("E"); // F3 end
    }
}
// C1: {Lines 5-7} - {Lines 9-11} (B, C, D)
// C2: {Lines 4-7} - {Lines 8-11} (A, B, C, D)
// C1 is NOT subsumed by C2 because C2 does not contain the *entirety* of C1's clone set. 
// However, C1's members are contained in C2's members. Subsumption should filter this.

// Expected Filtered Stats (After subsumption correctly eliminates nested/sub-maximal classes):
// 1 CC, 2 Clones, Biggest Fragment: 4 lines (Lines 8-11).