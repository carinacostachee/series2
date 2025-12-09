public class TinyTest {
    
    // These two methods are IDENTICAL - should be 1 clone class with 2 members
  // Clone A: Two lines of code
    public void setupConfigA() {
        int timeout = 100;
        System.out.println("Init: " + timeout);
    }

    // Clone B: Identical to Clone A
    public void setupConfigB() {
        int timeout = 100;
        System.out.println("Init: " + timeout);
    }

    // Unique Method: To test against false positives
    public void runProcess() {
        System.out.println("Processing complete.");
    }
}