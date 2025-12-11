public class CORRTestComplexExpressions {
    public void calculate1(int x) { // F1 start
        int res = (x * 3 + 5) / 2;
        System.out.println(res);
    } // F1 end

    public void calculate2(int y) { // F2 start
        int result = (y * 3 + 5) / 2;
        System.out.println(result);
    } // F2 end
}
// NOTE: The identifiers 'result' vs 'res' and 'x' vs 'y' should prevent these from being Type I clones.

// Expected Filtered Stats: 0 Clones, 0 Clone Classes.