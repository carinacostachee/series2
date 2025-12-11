public class CORRLogger {
    
    // Original logging method
    public void logMessage(String msg) {
        System.out.println("===================");
        System.out.println("LOG: " + msg);
        System.out.println("Timestamp: " + System.currentTimeMillis());
        System.out.println("===================");
    }
    
    // Clone - EXACT COPY
    public void writeLog(String msg) {
        System.out.println("===================");
        System.out.println("LOG: " + msg);
        System.out.println("Timestamp: " + System.currentTimeMillis());
        System.out.println("===================");
    }
    
    // Unique method - not a clone
    public void clearLog() {
        System.out.println("Log cleared");
    }
}
