public class CORRTestEmptyClone {
    public void start() {
        if (true) {} // F1 start/end
    }
    public void stop() {
        if (true) {} // F2 start/end
    }
    public void action() {} // F3 start/end (empty block)
}
// If minCloneNodeNumber > 1, the empty blocks might be considered clones (Block: {})
// Test case checks if the minimum threshold correctly excludes tiny, trivial clones.

// Expected Filtered Stats (if minCloneNodeNumber is low enough to include empty blocks):
// - 1 CC, 2 Clones {F1, F2} (if block), 1 line.