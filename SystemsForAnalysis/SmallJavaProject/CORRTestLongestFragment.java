public class CORRTestLongestFragment {
    public void longMethod1() { // F1 start
        // 10 lines of unique code (e.g., A, B, C...)
        System.out.println("Clone Line 1"); // F2 start (maximal clone)
        System.out.println("Clone Line 2");
        System.out.println("Clone Line 3"); // F2 end
        // 5 lines of unique code (e.g., X, Y, Z...)
    }
    public void longMethod2() { // F3 start
        // 10 lines of unique code (e.g., A, B, C...)
        System.out.println("Clone Line 1"); // F4 start (maximal clone)
        System.out.println("Clone Line 2");
        System.out.println("Clone Line 3"); // F4 end
        // 5 lines of unique code (e.g., X, Y, Z...)
    }
}

// Expected Filtered Stats: 1 CC, 2 Clones (F2, F4), Biggest Fragment: 3 lines.
// This ensures the tool picks the *maximal repeating fragment*, not the entire method.