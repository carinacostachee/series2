public class CORRTestFieldAccessClone {
    private final int MAX = 10;
    
    public void checkBounds(int value) {
        if (value > MAX) { // F1 start
            System.out.println("Error");
        }
        System.out.println("Checked");
    } // F1 end
    
    public void checkLimit(int val) {
        if (val > MAX) { // F2 start
            System.out.println("Error");
        }
        System.out.println("Checked");
    } // F2 end
}
// NOTE: Type I must match 'value' vs 'val' in the condition.

// Expected Filtered Stats (assuming 'value' vs 'val' means they are NOT clones):
// 0 Clones, 0 Clone Classes. (This ensures strict Type I comparison works).