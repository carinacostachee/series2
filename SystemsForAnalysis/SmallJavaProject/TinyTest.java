public class TinyTest {
    
   // Pattern 1: Two IDENTICAL if-statements (should be 1 clone class with 2 members)
    public void checkA(int x) {
        if (x > 0) {
            System.out.println("positive");
        }
    }
    
    public void checkB(int y) {
        if (y > 0) {
            System.out.println("positive");
        }
    }
    
    // Pattern 2: One UNIQUE method (should NOT be a clone)
    public void different() {
        System.out.println("unique message");
    }
}