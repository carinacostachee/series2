public class CORRDataProcessor {
    
    // Original array processing
    public void processData(int[] data) {
        int sum = 0;
        int count = 0;
        int i = 0;
        while (i < data.length) {
            if (data[i] > 0) {
                sum = sum + data[i];
                count = count + 1;
            }
            i = i + 1;
        }
        System.out.println("Total sum: " + sum);
        System.out.println("Total count: " + count);
    }
    
    // Clone - EXACT COPY
    public void analyzeData(int[] data) {
        int sum = 0;
        int count = 0;
        int i = 0;
        while (i < data.length) {
            if (data[i] > 0) {
                sum = sum + data[i];
                count = count + 1;
            }
            i = i + 1;
        }
        System.out.println("Total sum: " + sum);
        System.out.println("Total count: " + count);
    }
}