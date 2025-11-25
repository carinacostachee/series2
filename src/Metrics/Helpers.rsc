module Metrics::Helpers

import IO;
import List;
import Set;
import String;
import lang::java::m3::Core;
import lang::java::m3::AST;
import Map;

/* * Helper function to get ASTs (used by Complexity)
 */
list[Declaration] getASTs(loc projectLocation) {
    M3 model = createM3FromMavenProject(projectLocation);
    return [createAstFromFile(f, true) | f <- files(model.containment), isCompilationUnit(f)];
}

/*
 * CORE METRIC: Source Lines of Code (SLOC)
 * This single function handles comment stripping and empty line skipping
 * for Volume, Unit Size, and Complexity.
 */
int countSLOC(loc file) {
    try {
        // If the file scheme is unknown (e.g. generated code), return 0
        if (file.scheme == "unknown") return 0;
        
        str content = readFile(file);
        list[str] lines = split("\n", content);
        int count = 0;
        bool inBlockComment = false;
        
        for (line <- lines) {
            str trimmed = trim(line);
            
            // 1. Skip empty lines
            if (trimmed == "") continue;
            
            // 2. Handle block comments logic
            if (contains(trimmed, "/*")) inBlockComment = true;
            if (contains(trimmed, "*/")) {
                inBlockComment = false;
                // We assume the closing */ line is not code. 
                // If code exists after */ on same line, this logic ignores it (simplification)
                continue; 
            }
            if (inBlockComment) continue;
            
            // 3. Skip single line comments
            if (startsWith(trimmed, "//")) continue;
            
            count += 1;
        }
        return count;
    } catch: {
        return 0; // robust error handling
    }
}