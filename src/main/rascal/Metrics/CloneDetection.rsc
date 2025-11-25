module Metrics::CloneDetection

import IO;
import List;
import Set;
import String;
import lang::java::m3::Core;
import lang::java::m3::AST;
import Map;
import Node;
import util::Math;

import Metrics::Helpers;

// Configuration
// Configuration
int MIN_CLONE_SIZE = 3; // Lowered from 6 to catch small test methods
int MIN_MASS = 10;      // Lowered from 50 to catch small test methods

// Data structures for clone detection
alias CloneFragment = tuple[node subtree, loc location, int mass];
alias CloneClass = set[CloneFragment];

tuple[int lines, real percentage] calculateDuplication(loc projectLocation) {
    println("Starting AST-based clone detection...");
    
    // Get all ASTs for the project
    list[Declaration] asts = getASTs(projectLocation);
    
    // Extract all subtrees with their locations
    list[CloneFragment] fragments = [];
    for (ast <- asts) {
        fragments += extractFragments(ast);
    }
    
    println("Extracted <size(fragments)> fragments");
    
    // Group fragments by normalized subtree
    map[node, list[CloneFragment]] groups = ();
    for (fragment <- fragments) {
        node normalized = normalizeAST(fragment.subtree);
        if (normalized in groups) {
            groups[normalized] += fragment;
        } else {
            groups[normalized] = [fragment];
        }
    }
    
    // Find clone classes (groups with 2+ fragments)
    list[CloneClass] cloneClasses = [];
    for (normalized <- groups, size(groups[normalized]) >= 2) {
        cloneClasses += {*groups[normalized]};
    }
    
    println("Found <size(cloneClasses)> clone classes before subsumption");
    
    // Apply subsumption to remove included clones
    cloneClasses = removeSubsumedClones(cloneClasses);
    
    println("Found <size(cloneClasses)> clone classes after subsumption");
    
    // Calculate duplication statistics
    tuple[int, real] stats = calculateStats(cloneClasses, projectLocation);
    
    // Write results to file
    writeCloneResults(cloneClasses, projectLocation);
    
    return stats;
}

// Extract all meaningful subtrees from an AST
list[CloneFragment] extractFragments(Declaration ast) {
    list[CloneFragment] fragments = [];
    
    visit(ast) {
        case Statement stmt: {
            if (isCloneCandidate(stmt) && stmt has src) {
                int mass = calculateMass(stmt);
                if (mass >= MIN_MASS) {
                    fragments += <stmt, stmt.src, mass>;
                }
            }
        }
        case Declaration decl: {
            if (isCloneCandidate(decl) && decl has src) {
                int mass = calculateMass(decl);
                if (mass >= MIN_MASS) {
                    fragments += <decl, decl.src, mass>;
                }
            }
        }
    }
    
    return fragments;
}

// Check if a node is a good candidate for cloning
bool isCloneCandidate(node n) {
    return size([stmt | /Statement stmt := n]) >= MIN_CLONE_SIZE;
}

// Calculate the mass (node count) of a subtree
int calculateMass(node n) {
    int mass = 0;
    // Count every node in the tree (statements, expressions, literals, etc.)
    visit(n) {
        case node _ : mass += 1;
    }
    return mass;
}

// Normalize AST for Type I clone detection
node normalizeAST(node n) {
    return visit(n) {
        // Remove source locations
        case node x => unsetRec(x, "src")
        // Normalize identifiers (for Type II clones, uncomment these lines)
        // case \variable(str name) => \variable("VAR")
        // case \variable(str name, int extraDimensions) => \variable("VAR", extraDimensions)
        // case \simpleName(str name) => \simpleName("VAR")
    };
}

// Remove subsumed clone classes
list[CloneClass] removeSubsumedClones(list[CloneClass] cloneClasses) {
    list[CloneClass] result = [];
    
    for (cc1 <- cloneClasses) {
        bool isSubsumed = false;
        for (cc2 <- cloneClasses, cc1 != cc2) {
            if (isSubsumedBy(cc1, cc2)) {
                isSubsumed = true;
                break;
            }
        }
        if (!isSubsumed) {
            result += cc1;
        }
    }
    
    return result;
}

// Check if clone class cc1 is subsumed by cc2
bool isSubsumedBy(CloneClass cc1, CloneClass cc2) {
    for (frag1 <- cc1) {
        bool found = false;
        for (frag2 <- cc2) {
            // Check if frag1's location is fully contained within frag2's location
            if (frag1.location.scheme == frag2.location.scheme &&
                frag1.location.path == frag2.location.path &&
                frag1.location != frag2.location) {  // Must be different locations
                
                // Use offset and length for containment check
                int offset1 = frag1.location.offset;
                int length1 = frag1.location.length;
                int offset2 = frag2.location.offset;
                int length2 = frag2.location.length;
                
                // frag1 is contained in frag2 if it starts after and ends before
                if (offset1 >= offset2 && (offset1 + length1) <= (offset2 + length2)) {
                    found = true;
                    break;
                }
            }
        }
        if (!found) return false;
    }
    return true;
}

// Calculate duplication statistics
tuple[int, real] calculateStats(list[CloneClass] cloneClasses, loc project) {
    // Get total project size
    M3 model = createM3FromMavenProject(project);
    int totalLines = 0;
    for (file <- files(model.containment), isCompilationUnit(file)) {
        totalLines += countSLOC(file);
    }
    
    // Calculate duplicated lines by tracking unique (file, line) pairs
    set[tuple[str, int]] duplicatedLines = {};
    
    for (cloneClass <- cloneClasses) {
        for (fragment <- cloneClass) {
            if (fragment.location.scheme != "unknown") {
                str filePath = fragment.location.path;
                int startLine = fragment.location.begin.line;
                int endLine = fragment.location.end.line;
                
                // Add each line as a unique (file, line) tuple
                for (int line <- [startLine..endLine + 1]) {
                    duplicatedLines += <filePath, line>;
                }
            }
        }
    }
    
    int dupLines = size(duplicatedLines);
    real percentage = totalLines > 0 ? round((dupLines * 100.0) / totalLines, 0.01) : 0.0;
    
    return <dupLines, percentage>;
}

// Write clone detection results to file
void writeCloneResults(list[CloneClass] cloneClasses, loc project) {
    loc outputFile = project + "clone_results.txt";
    
    str report = "=== Clone Detection Results ===\n";
    report += "Number of clone classes: <size(cloneClasses)>\n";
    
    int totalClones = 0;
    for (cc <- cloneClasses) totalClones += size(cc);
    report += "Total number of clones: <totalClones>\n\n";
    
    // Report each clone class
    int classId = 1;
    for (cloneClass <- cloneClasses) {
        report += "Clone Class <classId>: (<size(cloneClass)> clones)\n";
        
        for (fragment <- cloneClass) {
            report += "  Location: <fragment.location>\n";
            report += "  Lines: <fragment.location.begin.line>-<fragment.location.end.line>\n";
            report += "  Mass: <fragment.mass> tokens\n";
            
            // Show a snippet of the code
            try {
                str content = readFile(fragment.location.top);
                list[str] allLines = split("\n", content);
                
                int startLine = fragment.location.begin.line - 1; // 0-indexed
                int endLine = min(fragment.location.end.line, startLine + 10); // Show max 10 lines
                
                report += "  Code snippet:\n";
                for (int i <- [startLine..min(endLine, size(allLines))]) {
                    report += "    <allLines[i]>\n";
                }
                if (endLine - startLine > 10) {
                    report += "    ... (<endLine - startLine - 10> more lines)\n";
                }
            } catch: {
                report += "  (Code snippet unavailable)\n";
            }
            report += "\n";
        }
        report += "---\n\n";
        classId += 1;
    }
    
    writeFile(outputFile, report);
    println("Clone results written to: <outputFile>");
}

str rankDuplication(real percentage) {
    if (percentage >= 0.0 && percentage < 3.0) return "++";
    if (percentage >= 3.0 && percentage < 5.0) return "+";
    if (percentage >= 5.0 && percentage < 10.0) return "o";
    if (percentage >= 10.0 && percentage < 20.0) return "-";
    return "--";
}

void reportDuplication(loc project) {
    println("=== AST-Based Clone Detection ===");
    tuple[int lines, real pct] result = calculateDuplication(project);
    str rank = rankDuplication(result.pct);
    
    println("Duplicated Lines: <result.lines>");
    println("Percentage:       <result.pct>%");
    println("SIG Rank:         <rank>");
    println();
}

// Test the implementation
void testCloneDetection() {
    loc testProject = |project://series2/SystemsForAnalysis/SmallJavaProject|;
    reportDuplication(testProject);
}