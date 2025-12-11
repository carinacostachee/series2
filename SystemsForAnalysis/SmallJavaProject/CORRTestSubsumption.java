public class CORRTestSubsumption {
    public void methodA() { // Lines 3-8
        int a = 1;
        System.out.println("Start"); // F2 start
        if (a > 0) {            // F1 start (maximal clone)
            a++;                // F1, F2 content
        }
        System.out.println("End"); // F2 end
    }
    public void methodB() { // Lines 9-14
        int b = 1;
        System.out.println("Start"); // F4 start
        if (b > 0) {            // F3 start (maximal clone)
            b++;                // F3, F4 content
        }
        System.out.println("End"); // F4 end
    }
}
// Clone 1 (C1): Block of lines 5-7 (if statement)
// Clone 2 (C2): Block of lines 4-8 (println + if + println)

// Expected Result:
// - RAW: C1 {Lines 5-7, Lines 11-13} AND C2 {Lines 4-8, Lines 10-14}
// - FILTERED: Only C2 remains. C1 is subsumed by C2.
// - Filtered Stats: 1 CC, 2 Clones, Biggest Fragment: 5 lines (Node count will be ~15-20)