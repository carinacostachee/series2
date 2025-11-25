module Metrics::CloneDetection

import IO;
import List;
import Set;
import String;
import lang::java::m3::Core;
import lang::java::m3::AST;
import Map;
import Location;
import Metrics::Duplication; // Reuse your existing ranking function
import Metrics::Helpers;

// --- Configuration ---
// Minimum number of statements/nodes for a fragment to be considered a clone.
private int MIN_CLONE_SIZE = 5; 

// --- Core Data Structures ---
// A Clone Class is a set of source locations (loc) that share the same hash.
alias CloneClass = set[loc];

// --- 1. Detection: Structural Hashing (Type I) ---

map[value, CloneClass] findInitialCloneGroups(list[Declaration] allASTs) {
    map[value, CloneClass] cloneGroups = ();
    
    // Traverse the ASTs and compute the hash for every subtree
    for (ast <- allASTs) {
        visit(ast) {
            case node subtree: {
                // Ensure the subtree has a source location and meets minimum size
                if (has(subtree@\loc, "src") && size(subtree) >= MIN_CLONE_SIZE) { 
                    value hash = subtree.hash; 
                    loc location = subtree@\loc.src;

                    if (hash in cloneGroups) {
                        cloneGroups[hash] += location;
                    } else {
                        cloneGroups[hash] = {location};
                    }
                }
            }
        }
    }
    
    // Filter to keep only actual duplicates (Count > 1)
    return (hash: locations) in cloneGroups | size(locations) > 1;
}


// --- 2. Filtering: Subsumption Logic ---

// Checks if location S is completely contained within location L.
bool isContained(loc S, loc L) {
    // Check if the start offset of S is >= L's start and E's end is <= L's end.
    return L.offset <= S.offset && L.offset + L.size >= S.offset + S.size;
}

// Checks if a smaller class is fully contained within a larger class.
bool isSubsumed(CloneClass smallerClass, CloneClass largerClass) {
    // For every fragment in the smaller class...
    for (s_loc <- smallerClass) {
        // ...check if it is fully contained within ANY fragment of the larger class.
        bool foundLargerContainer = false;
        for (l_loc <- largerClass) {
            if (isContained(s_loc, l_loc)) {
                foundLargerContainer = true;
                break;
            }
        }
        // If even one fragment of the smaller class isn't contained, it's not fully subsumed.
        if (!foundLargerContainer) {
            return false;
        }
    }
    // If every fragment in the smaller class is contained in one of the larger's fragments, it's subsumed.
    return true;
}

// Filters the map of clone groups to remove subsumed (non-maximal) classes
set[CloneClass] filterSubsumedClasses(map[value, CloneClass] initialGroups) {
    set[CloneClass] initialClasses = toSet(initialGroups);
    set[CloneClass] toRemove = {};

    for (classA <- initialClasses) {
        for (classB <- initialClasses) {
            // A class cannot subsume itself
            if (classA != classB) {
                if (isSubsumed(classA, classB)) {
                    toRemove += classA;
                }
            }
        }
    }
    return initialClasses - toRemove;
}

// --- 3. Metrics Calculation and Reporting ---

tuple[int totalLines, int dupLines, real percentage, set[CloneClass]] 
    calculateFinalClonesAndMetrics(loc projectLoc) {
    
    list[Declaration] allASTs = getASTs(projectLoc);

    // Step 1: Find initial clones
    map[value, CloneClass] initialGroups = findInitialCloneGroups(allASTs);

    // Step 2: Filter subsumed clones
    set[CloneClass] finalClasses = filterSubsumedClasses(initialGroups);

    // --- Metrics Calculation ---

    // Total lines of code in the project
    int totalLines = countTotalProjectLines(projectLoc);

    // Collect all unique duplicated lines from the final maximal clone classes
    set[loc] duplicatedLineLocs = {};
    for (class <- finalClasses) {
        for (fragment <- class) {
            // Add all lines spanned by this fragment's location to the set
            duplicatedLineLocs += getLinesInLoc(fragment);
        }
    }

    int dupLines = size(duplicatedLineLocs);
    real percentage = totalLines > 0 ? (dupLines * 100.0) / totalLines : 0.0;
    
    return <totalLines, dupLines, percentage, finalClasses>;
}

// --- Helper Implementations ---

int countTotalProjectLines(loc projectLoc) {
    M3 model = createM3FromMavenProject(projectLoc);
    return (0 | it + countSLOC(file) | file <- files(model.containment), isCompilationUnit(file));
}

set[loc] getLinesInLoc(loc fragment) {
    return { |project://<fragment.uri.authority>/<fragment.uri.path>?offset=<l.offset>&length=<l.length>| 
            l <- fragment.lines, fragment.uri.scheme == "project" };
}

// --- 4. Main Reporting Function ---

void reportCloneAnalysis(loc projectLoc) {
    println("=== Clone Detection (AST Type I) Analysis ===");

    tuple[int totalLines, int dupLines, real pct, set[CloneClass] finalClasses] result 
        = calculateFinalClonesAndMetrics(projectLoc);
        
    str rank = Metrics::Duplication::rankDuplication(result.pct); // Reuse old ranking

    // Required Metrics (Item 1b)
    println("Total Lines of Code: <result.totalLines>");
    println("Duplicated Lines:    <result.dupLines>");
    println("Percentage:          <result.pct>%");
    println("SIG Rank (Duplication): <rank>");
    println("Number of Clone Classes (Maximal): <size(result.finalClasses)>");
    
    // Calculate and report Max Clone/Class
    int biggestClassSize = (0 | max(it, size(c)) | c <- result.finalClasses);
    int biggestFragmentSize = (0 | max(it, f.end.line - f.begin.line + 1) | c <- result.finalClasses, f <- c);

    println("Number of Clone Pairs (Total): <sum({size(c)*(size(c)-1)/2 | c <- result.finalClasses})>");
    println("Biggest Clone Fragment (lines): <biggestFragmentSize>");
    println("Biggest Clone Class (members):  <biggestClassSize>");

    // Print Example Clones (Item 1b, also for file output)
    println("\n--- Example Clone Class ---");
    // You'd need to convert the loc to a readable format (e.g., File:Line-Line)
    // and write ALL clone classes to a separate file for final submission.
    
    // For visualization, you'll pass result.finalClasses to your front-end code.
}
