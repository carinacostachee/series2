module Metrics::Type1CloneDetection

import lang::java::m3::Core;
import lang::java::m3::AST;
import IO;
import List;
import Set;
import Map;
import String;
import Node;

// Add this function to your Metrics::CloneDetection module
// This exports clone detection results as JSON for visualization

import util::Math;
import lang::json::IO;

// Export clone data as JSON for visualization (manual JSON building)
public void exportClonesAsJSON(list[ClassClones] cloneClasses, loc outputFile) {
    // Build a map: file path -> list of clone info
    map[str, list[tuple[int classId, int startLine, int endLine, int lines, int cloneClassSize, str file]]] fileClones = ();
    
    // Collect all clones organized by file
    for (ClassClones cc <- cloneClasses) {
        int classId = indexOf(cloneClasses, cc);
        
        for (Clone c <- cc) {
            str filePath = c.location.path;
            int cloneLines = c.location.end.line - c.location.begin.line + 1;
            
            tuple[int classId, int startLine, int endLine, int lines, int cloneClassSize, str file] cloneInfo 
                = <classId, c.location.begin.line, c.location.end.line, cloneLines, size(cc), c.location.file>;
            
            if (filePath in fileClones) {
                fileClones[filePath] += [cloneInfo];
            } else {
                fileClones[filePath] = [cloneInfo];
            }
        }
    }
    
    // Build JSON string manually
    str json = "{\n  \"files\": [\n";
    
    list[str] filePaths = sort(toList(domain(fileClones)));
    bool firstFile = true;
    
    for (str filePath <- filePaths) {
        if (!firstFile) json += ",\n";
        firstFile = false;
        
        list[tuple[int classId, int startLine, int endLine, int lines, int cloneClassSize, str file]] clones = fileClones[filePath];
        
        int totalCloneLines = 0;
        for (c <- clones) {
            totalCloneLines += c.lines;
        }
        
        // Extract file name from path
        list[str] pathParts = split("/", filePath);
        str fileName = pathParts[-1];
        
        // Extract package/folder structure
        str folder = "";
        if (size(pathParts) > 1) {
            folder = intercalate("/", pathParts[0..-1]);
        }
        
        // Escape quotes in strings
        str escapedPath = escape(filePath, ("\"": "\\\"", "\\": "\\\\"));
        str escapedFile = escape(fileName, ("\"": "\\\"", "\\": "\\\\"));
        str escapedFolder = escape(folder, ("\"": "\\\"", "\\": "\\\\"));
        
        json += "    {\n";
        json += "      \"path\": \"<escapedPath>\",\n";
        json += "      \"file\": \"<escapedFile>\",\n";
        json += "      \"folder\": \"<escapedFolder>\",\n";
        json += "      \"cloneCount\": <size(clones)>,\n";
        json += "      \"cloneLines\": <totalCloneLines>,\n";
        json += "      \"clones\": [\n";
        
        bool firstClone = true;
        for (c <- clones) {
            if (!firstClone) json += ",\n";
            firstClone = false;
            
            str escapedCloneFile = escape(c.file, ("\"": "\\\"", "\\": "\\\\"));
            json += "        {\n";
            json += "          \"classId\": <c.classId>,\n";
            json += "          \"startLine\": <c.startLine>,\n";
            json += "          \"endLine\": <c.endLine>,\n";
            json += "          \"lines\": <c.lines>,\n";
            json += "          \"cloneClassSize\": <c.cloneClassSize>,\n";
            json += "          \"file\": \"<escapedCloneFile>\"\n";
            json += "        }";
        }
        
        json += "\n      ]\n";
        json += "    }";
    }
    
    json += "\n  ],\n";
    json += "  \"totalCloneClasses\": <size(cloneClasses)>\n";
    json += "}\n";
    
    writeFile(outputFile, json);
    println("Clone data exported as JSON to: <outputFile>");
}

// Updated test function that also exports JSON
public void testCloneDetectionWithVisualization() {
    loc testProject = |project://series2/SystemsForAnalysis/SmallJavaProject|;
    int minCloneSize = 15;
    
    tuple[list[ClassClones], map[str, int]] result = detectTypeOneClones(testProject, minCloneSize);
    list[ClassClones] cloneClasses = result<0>;
    map[str, int] stats = result<1>;
    
    printStats(stats);
    writeClonesToFile(cloneClasses, |project://series2/SystemsForAnalysis/SmallJavaProject/clone_results.txt|);
    
    // Export JSON for visualization
    exportClonesAsJSON(cloneClasses, |project://series2/SystemsForAnalysis/SmallJavaProject/clone_data.json|);
}

/*
-First step is to create data structures that define a clone and a class where we can store these clones.
-The clone is a piece of code that we are analyzing, and it is defined as a tuple that contains the location
of the code, the AST structure of the code and the nodeCount is telling us how many nodes are in the AST 
structure.
-The class ClassClones is just a list that contains the clones. 
*/
alias Clone = tuple[loc location, node subtree, int nodeCount];
alias ClassClones = list[Clone];

/*
-Second step is to create the main function that detects the Type 1 clones in a Java project.
*/
public tuple[list[ClassClones], map[str,int]] detectTypeOneClones(loc projectPath, int minCloneNodeNumber){
    println("Starting clone detection for: <projectPath>");
    //here we create M3 model from the Java project using Rascal's function that parses Java projects
    M3 model = createM3FromMavenProject(projectPath);

    //then we get the java files from the java project
    set[loc] javaFiles = files(model);
    println("There are <size(javaFiles)> files");

    //now we need a list to store all the subtrees
    list[Clone] allCandidates = [];

    //we then iterate through each file and parse it into an AST, then break the AST into subtrees, then add them
    // to the list we made.
    for(loc javaFile <- javaFiles){
        try {
            println("Currently processing: <javaFile.file>");
            Declaration ast = createAstFromFile(javaFile, true);
            list[Clone] candidates = extractSubtrees(ast, minCloneNodeNumber);
            allCandidates += candidates;

        } catch Exception e: {
            println("Error processing <javaFile>: <e> ");
        }
    }
    println("Extracted <size(allCandidates)> candidate subtree");

    // Group identical subtrees into clone classes
    list[ClassClones] cloneClasses = groupCloneClasses(allCandidates);

    // Apply subsumption (remove smaller clones contained in larger ones)
    list[ClassClones] filteredClasses = applySubsumption(cloneClasses);

    // Calculate statistics
    map[str, int] stats = calculateStats(filteredClasses, javaFiles);
    
    return <filteredClasses, stats>;
}

//this is a function that is counting the nodes in the subtree
public int countNodes(node n) {
    int count = 1;
    visit(n) {
        case node _: count += 1;
    }
    return count;
}

// Extract all subtrees of minimum size from an AST
public list[Clone] extractSubtrees(node ast, int minSize) {
    list[Clone] candidates = [];
    
    visit(ast) {
        // Collect nodes that carry source information (previously restricted to
        // Statement, Block and MethodDeclaration) — we filter by presence of src.
        case node n:
        {
            if (n has src) {
                int nodeCount = countNodes(n);
                if (nodeCount >= minSize) {
                    candidates += <n.src, n, nodeCount>;
                }
            }
        }
        // Note: The visitor implicitly handles traversing the rest of the AST
    }
    
    return candidates;
}
public list[ClassClones] groupCloneClasses(list[Clone] candidates){
    map[str, list[Clone]] groups = ();

    for(Clone c <- candidates){
        // Try to remove location annotations from the AST node
        node normalizedAST = visit(c.subtree) {
           //case node n => unset(unset(n,"src"),"typ")
           case node n => unset(unset(unset(n,"src"), "decl"),"typ")
           //case node n => unset(unset(n,"src"), "decl")
        };
        
        
        str astString = "<normalizedAST>";

        if (astString in groups){
            groups[astString] += [c];
        } else {
            groups[astString] = [c];
        }

        
    }
    
    list[ClassClones] cloneClasses = [];
    for(str astStr <- domain(groups)){
        if(size(groups[astStr]) > 1){
            cloneClasses += [groups[astStr]];
            println("Clone class found: <size(groups[astStr])> members");
        }
    }
    
    return cloneClasses;
}
// Apply subsumption
public list[ClassClones] applySubsumption(list[ClassClones] cloneClasses) {
    list[ClassClones] filtered = [];
    
    for (ClassClones cc1 <- cloneClasses) {
        bool isSubsumed = false;
        
        for (ClassClones cc2 <- cloneClasses, cc1 != cc2) {
            if (isSubsumedBy(cc1, cc2)) {
                isSubsumed = true;
                break;
            }
        }
        
        if (!isSubsumed) {
            filtered += [cc1];
        }
    }
    
    return filtered;
}

// Check if cc1 is subsumed by cc2
public bool isSubsumedBy(ClassClones cc1, ClassClones cc2) {
    for (Clone c1 <- cc1) {
        bool contained = false;
        for (Clone c2 <- cc2) {
            if (c1.location.offset >= c2.location.offset && 
                (c1.location.offset + c1.location.length) <= (c2.location.offset + c2.location.length) &&
                c1.location != c2.location) {
                contained = true;
                break;
            }
        }
        if (!contained) {
            return false;
        }
    }
    return true;
}

// Calculate statistics - fixed to avoid double-counting lines
public map[str, int] calculateStats(list[ClassClones] cloneClasses, set[loc] javaFiles) {
    int totalLines = 0;
    int numberOfClones = 0;
    int numberOfCloneClasses = size(cloneClasses);
    int biggestCloneSize = 0;
    int biggestCloneClassSize = 0;
    
    // Count total lines
    for (loc file <- javaFiles) {
        try {
            str content = readFile(file);
            totalLines += size(split("\n", content));
        } catch: {
            println("Could not read file: <file>");
        }
    }
    
    // Collect unique duplicated line ranges to avoid double-counting
    set[tuple[int,int]] duplicatedLineRanges = {};
    
    for (ClassClones cc <- cloneClasses) {
        if (size(cc) > biggestCloneClassSize) {
            biggestCloneClassSize = size(cc);
        }
        
        for (Clone c <- cc) {
            numberOfClones += 1;
            int cloneLines = c.location.end.line - c.location.begin.line + 1;
            
            // Track unique line ranges
            duplicatedLineRanges += <c.location.begin.line, c.location.end.line>;
            
            if (cloneLines > biggestCloneSize) {
                biggestCloneSize = cloneLines;
            }
        }
    }
    
    // Count unique duplicated lines
    int duplicatedLines = 0;
    for (<int startLine, int endLine> <- duplicatedLineRanges) {
        duplicatedLines += (endLine - startLine + 1);
    }
    
    int duplicatedLinesPercentage = totalLines > 0 ? (duplicatedLines * 100) / totalLines : 0;
    
    return (
        "totalFiles": size(javaFiles),
        "totalLines": totalLines,
        "duplicatedLines": duplicatedLines,
        "duplicatedLinesPercentage": duplicatedLinesPercentage,
        "numberOfClones": numberOfClones,
        "numberOfCloneClasses": numberOfCloneClasses,
        "biggestClone": biggestCloneSize,
        "biggestCloneClass": biggestCloneClassSize
    );
}

// Print statistics
public void printStats(map[str, int] stats) {
    println("=== CLONE DETECTION STATISTICS ===");
    println("Total files analyzed: <stats["totalFiles"]>");
    println("Total lines of code: <stats["totalLines"]>");
    println("Duplicated lines: <stats["duplicatedLines"]>");
    println("Percentage of duplicated lines: <stats["duplicatedLinesPercentage"]>%");
    println("Number of clones: <stats["numberOfClones"]>");
    println("Number of clone classes: <stats["numberOfCloneClasses"]>");
    println("Biggest clone: <stats["biggestClone"]> lines");
    println("Biggest clone class: <stats["biggestCloneClass"]> members");
}

// Write results to file
public void writeClonesToFile(list[ClassClones] cloneClasses, loc outputFile) {
    str output = "CLONE DETECTION RESULTS\n";
    output += "========================\n\n";
    
    int classIndex = 1;
    for (ClassClones cc <- cloneClasses) {
        output += "Clone Class <classIndex>: (<size(cc)> clones)\n";
        
        int cloneIndex = 1;
        for (Clone c <- cc) {
            int lines = c.location.end.line - c.location.begin.line + 1;
            output += "  Clone <cloneIndex>: <c.location> (<lines> lines)\n";
            cloneIndex += 1;
        }
        output += "\n";
        classIndex += 1;
    }
    
    writeFile(outputFile, output);
    println("Clone results written to: <outputFile>");
}

// Test the implementation
public void testCloneDetection() {
    loc testProject = |project://series2/SystemsForAnalysis/smallsql0.21_src|;
    int minCloneSize = 15;
    
    tuple[list[ClassClones], map[str, int]] result = detectTypeOneClones(testProject, minCloneSize);
    list[ClassClones] cloneClasses = result<0>;
    map[str, int] stats = result<1>;
    
    printStats(stats);
    writeClonesToFile(cloneClasses, |project://series2/SystemsForAnalysis/SmallJavaProject/clone_results.txt|);
}