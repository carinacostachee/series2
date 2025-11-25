module Metrics::Duplication

import IO;
import List;
import Set;
import String;
import lang::java::m3::Core;
import lang::java::m3::AST;
import Map;

import Metrics::Helpers;

tuple[int lines, real percentage] calculateDuplication(loc projectLocation) {
    M3 model = createM3FromMavenProject(projectLocation);
    
    // We can't strictly use countSLOC here because duplication relies on 
    // a specific block processing logic, but we can still clean up the loop.
    
    map[str, int] blockCounts = ();
    map[str, set[tuple[loc, int]]] blockLocations = ();
    int totalLines = 0;
    
    // First pass: Identify Blocks
    for (file <- files(model.containment), isCompilationUnit(file)) { 
        // We read raw lines here to preserve structure for block matching
        list[str] lines = split("\n", readFile(file));
        totalLines += size(lines); // Total raw lines
        
        if (size(lines) < 6) continue;

        for (int i <- [0..size(lines) - 5]) {
            list[str] block = lines[i..i+6];
            // Normalize: Trim lines and join
            str normalized = intercalate("\n", [trim(line) | line <- block]);
            
            blockCounts[normalized] = (normalized in blockCounts) ? blockCounts[normalized] + 1 : 1;
            
            if (normalized notin blockLocations) blockLocations[normalized] = {};
            blockLocations[normalized] += <file, i>;
        }
    }
    
    // Second pass: Count Duplicates
    set[tuple[loc, int]] duplicateIndices = {};
    
    for (block <- blockCounts, blockCounts[block] > 1) {
        for (<file, startLine> <- blockLocations[block]) {
            for (int offset <- [0..6]) {
                duplicateIndices += <file, startLine + offset>;
            }
        }
    }
    
    int dupLines = size(duplicateIndices);
    real percentage = totalLines > 0 ? (dupLines * 100.0) / totalLines : 0.0;
    
    return <dupLines, percentage>;
}

str rankDuplication(real percentage) {
    if (percentage >= 0.0 && percentage < 3.0) return "++";
    if (percentage >= 3.0 && percentage < 5.0) return "+";
    if (percentage >= 5.0 && percentage < 10.0) return "o";
    if (percentage >= 10.0 && percentage < 20.0) return "-";
    return "--";
}

void reportDuplication(loc project) {
    println("=== 4. Duplication Analysis ===");
    tuple[int lines, real pct] result = calculateDuplication(project);
    str rank = rankDuplication(result.pct);
    
    println("Duplicated Lines: <result.lines>");
    println("Percentage:       <result.pct>%");
    println("SIG Rank:         <rank>");
    println();
}
