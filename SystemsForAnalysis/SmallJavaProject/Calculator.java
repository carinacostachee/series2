public class Calculator {
    
    // Original validation method
    public boolean validateInput(int value) {
        if (value < 0) {
            System.out.println("Error: negative value");
            System.out.println("Please provide positive number");
            return false;
        }
        if (value > 1000) {
            System.out.println("Error: value too large");
            System.out.println("Maximum allowed is 1000");
            return false;
        }
        System.out.println("Value is valid");
        return true;
    }
    
    // Clone 1 - EXACT COPY of validation logic
    public boolean checkNumber(int value) {
        if (value < 0) {
            System.out.println("Error: negative value");
            System.out.println("Please provide positive number");
            return false;
        }
        if (value > 1000) {
            System.out.println("Error: value too large");
            System.out.println("Maximum allowed is 1000");
            return false;
        }
        System.out.println("Value is valid");
        return true;
    }
    
    // Clone 2 - EXACT COPY again
    public boolean verifyValue(int value) {
        if (value < 0) {
            System.out.println("Error: negative value");
            System.out.println("Please provide positive number");
            return false;
        }
        if (value > 1000) {
            System.out.println("Error: value too large");
            System.out.println("Maximum allowed is 1000");
            return false;
        }
        System.out.println("Value is valid");
        return true;
    }
}