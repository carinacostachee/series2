public class CORRTestSingleLineClone {
    // F1 start, F2 start
    public void checkA() { int i = 0; i++; System.out.println("done"); } 
    // F1 end, F2 end
    // F3 start, F4 start
    public void checkB() { int j = 0; j++; System.out.println("done"); } 
    // F3 end, F4 end
}
// This checks that if multiple statements are crammed onto one physical line, 
// the AST node comparison still finds the method bodies to be identical subtrees,
// and the line count correctly reports 1 line/fragment.

// Expected Filtered Stats: 1 CC, 2 Clones, Biggest Fragment: 1 line.