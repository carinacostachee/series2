module Metrics::Duplication

import IO;
import List;
import Set;
import String;
import lang::java::m3::Core;
import lang::java::m3::AST;
import Map;
import Node;

import Metrics::Helpers;

// Configuration
int MIN_CLONE_SIZE = 6; // minimum number of statements
int MIN_MASS = 50; // minimum token count

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
            if (isCloneCandidate(stmt)) {
                int mass = calculateMass(stmt);
                if (mass >= MIN_MASS) {
                    fragments += <stmt, stmt@src, mass>;
                }
            }
        }
        case Declaration decl: {
            if (isCloneCandidate(decl) && decl has src) {
                int mass = calculateMass(decl);
                if (mass >= MIN_MASS) {
                    fragments += <decl, decl@src, mass>;
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

// Calculate the mass (token count) of a subtree
int calculateMass(node n) {
    int mass = 0;
    visit(n) {
        case str _: mass += 1;
        case int _: mass += 1;
        case real _: mass += 1;
    }
    return mass;
}

// Normalize AST for Type I clone detection
node normalizeAST(node n) {
    return visit(n) {
        // Remove source locations
        case node x => unsetRec(x, "src")
        // Normalize identifiers (for Type II, comment out for Type I)
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
            if (frag1.location ⊆ frag2.location) {
                found = true;
                break;
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
    
    // Calculate duplicated lines
    set[loc] duplicatedLines = {};
    for (cloneClass <- cloneClasses) {
        for (fragment <- cloneClass) {
            // Add all lines in the fragment's location
            if (fragment.location.scheme != "unknown") {
                for (int line <- [fragment.location.begin.line..fragment.location.end.line + 1]) {
                    duplicatedLines += fragment.location.top[begin=<line,0>][end=<line+1,0>];
                }
            }
        }
    }
    
    int dupLines = size(duplicatedLines);
    real percentage = totalLines > 0 ? (dupLines * 100.0) / totalLines : 0.0;
    
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
            report += "  Mass: <fragment.mass> tokens\n";
            
            // Show a snippet of the code
            try {
                list[str] lines = readFileLines(fragment.location);
                int startLine = fragment.location.begin.line;
                int endLine = min(startLine + 5, fragment.location.end.line);
                
                report += "  Code snippet:\n";
                for (int i <- [0..min(5, size(lines))]) {
                    report += "    <lines[i]>\n";
                }
                if (size(lines) > 5) {
                    report += "    ...\n";
                }
            } catch: {
                report += "  (Code snippet unavailable)\n";
            }
            report += "\n";
        }
        report += "---\n";
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
    loc testProject = |file:///path/to/your/test/project|;
    reportDuplication(testProject);
}