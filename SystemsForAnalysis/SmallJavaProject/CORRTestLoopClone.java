public class CORRTestLoopClone {
    public void processData(int count) { // F1 start
        for (int i = 0; i < count; i++) {
            System.out.println(i);
        }
        System.out.println("Done");
    } // F1 end

    public void iterateData(int max) { // F2 start
        for (int j = 0; j < max; j++) {
            System.out.println(j);
        }
        System.out.println("Done");
    } // F2 end
}
// If your location stripping/normalization is correct, the change from 'i' to 'j' and 'count' to 'max'
// inside the *MethodDeclaration* node will cause a difference. 
// BUT, since Type I is purely structural/lexical:
// * The loop body block {System.out.println(i);} is NOT identical due to 'i'/'j' if not normalized.
// * The overall Method body AST structure IS identical IF identifiers are masked or replaced, which is Type II.
// ASSUMPTION for Type I: If Type I is strictly applied (no variable renaming allowed):
// The loop initialization (e.g., int i = 0;) and the method calls are identical.

// Expected Filtered Stats (Assuming Type I means *exact* AST/lexical match): 
// 1 CC, 2 Clones (F1, F2 method bodies), Biggest Fragment: 4 lines. (This tests the AST structure of the ForStatement and its body)