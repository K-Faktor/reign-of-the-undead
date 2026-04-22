/******************************************************************************
    Reign of the Undead, v2.x

    Copyright (c) 2010-2026 Reign of the Undead Team.
    See AUTHORS.txt for a listing.

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to
    deal in the Software without restriction, including without limitation the
    rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
    sell copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.

    The contents of the end-game credits must be kept, and no modification of its
    appearance may have the effect of failing to give credit to the Reign of the
    Undead creators.

    Some assets in this mod are owned by Activision/Infinity Ward, so any use of
    Reign of the Undead must also comply with Activision/Infinity Ward's modtools
    EULA.
******************************************************************************/

// WAYPOINTS AND PATHFINDING
#include scripts\include\data;
#include scripts\include\utility;
#include scripts\include\realtime;
#include scripts\include\stack;

/**
 * @brief Initializes waypoints
 *
 * @returns nothing
 */
initializeWaypoints()
{
    debugPrint("in waypoints::initializeWaypoints()", "fn", level.nonVerbose);

    initStatic(); // initialize my hack to enable static member variables

    level.useKdWaypointTree = false;
    level.kdTreeNodeVisitCount = 0;

    if (!isDefined(level.Wp)) {
        // load internal waypoints
        maps\mp\_umi::loadWaypoints();
    }

    if (!level.waypointsInvalid) {
        initKdWaypointTree();
    } else {
        // We try loading external waypoints first, then internal waypoints.  If
        // there aren't any internal waypoints either, don't try to test waypoints
        // that don't exist
        return;
    }

    if (!isDefined(level.astarCalls)) {level.astarCalls = 0;}
    if (!isDefined(level.astarDistanceCalls)) {level.astarDistanceCalls = 0;}
    if (!isDefined(level.savedAStarCalls)) {level.savedAStarCalls = 0;}

    // level thread printAStarData();
    thread nearestWaypointsTest(100, true);
}

/**
 * @brief Creates pseudo-static members, since QuakeC doens't include them
 *
 * Tsk, tsk, Mr. Carmack.
 *
 * @returns nothing
 */
initStatic()
{
    debugPrint("in waypoints::initStatic()", "fn", level.nonVerbose);

    // an array and stack of variables so we can fake static member variables.  Needed
    // for kdWaypointNearestNeighbor()
    size = int(getDvarInt("bot_count") * 2);
    level.static = [];
    level.staticStack = [];

    // init the variables and push them onto the stack
    for (i=0; i<size; i++) {
        level.static[i] = "";
        level.staticStack[level.staticStack.size] = i;
    }
}

/**
 * @brief Get the index of an available static variable
 *
 * @returns integer the index of an available variable in level.static
 */
availableStatic()
{
    // 10th most-called function (2% of all function calls).
    // Do *not* put a function entrance debugPrint statement here!

    // ensure our stack is big enough
    if (level.staticStack.size < 3) {
        for (i=level.static.size; i<level.static.size + 10; i++) {
            level.static[i] = "";
            level.staticStack[level.staticStack.size] = i;
        }
    }

    // pop an index off the stack and return it
    index = level.staticStack[level.staticStack.size - 1];
    level.staticStack[level.staticStack.size - 1] = undefined;
    return index;
}

/**
 * @brief Initializes a k-dimensional waypoint tree so we can efficiently find the nearest neighbor
 *
 * @returns nothing
 */
initKdWaypointTree()
{
    debugPrint("in waypoints::initKdWaypointTree()", "fn", level.nonVerbose);

    level.right = 0;
    level.wrong = 0;
    level.treeCalls = 0;
    level.sortCalls = 0;
    level.kdTreeDistanceCount = 0;

    if (level.Wp.size >= 10) {
        // In order for a kd-tree to be efficient, n >> 2^k.  In our case,
        // n = level.Wp.size, and k is 3 as our waypoints are in R^3.  So
        // to use the kd-tree, we prefer the number of waypoints to be much larger
        // than 8.  Even in high-dimensionality, the kd-tree should be slightly
        // faster than a linear search of all the waypoints.
        level.useKdWaypointTree = true;
        findWaypointExtents();
        waypointList = kdWaypointList();
        level.nodes = 0;
        level.visitedNodes = 0;
        level.kdWpTree = kdWaypointTree(waypointList, 0);

        if (false) {
            // perform tests
            nearestWaypointsTest(100000, true);
            nearestWaypointsTest(100000, false);

            // print kd-tree
            level.kdText = [];
            for (i=0; i<11; i++) {
                level.kdText[i] = "";
            }
            kdPrintNode(level.kdWpTree, 0);
            for (i=0; i<9; i++) {
                noticePrint("depth: " + i + "  " + level.kdText[i]);
            }

            // validate tree
            level.maxDepth = 0;
            kdValidateNode(level.kdWpTree, 0);
            noticePrint("maxDepth: " + level.maxDepth);
        }
    }
}

/**
 * @brief Creates a trimmed down copy of the level.Wp array for use in building the kd-tree
 *
 * The trimmed structs only contain the waypoint id and origin.  We don't just use
 * the real level.Wp, as we don't want heapsort to change it in the process of
 * building the kd-tree.
 *
 * @returns array of trimmed down waypoint structs
 */
kdWaypointList()
{
    debugPrint("in waypoints::kdWaypointList()", "fn", level.nonVerbose);

    waypointList = [];

    for (i=0; i<level.Wp.size; i++) {
        wp = spawnStruct();
        wp.id = level.Wp[i].ID;
        wp.origin = level.Wp[i].origin;
        waypointList[waypointList.size] = wp;
    }

    return waypointList;
}

/**
 * @brief Absolute value
 *
 * @param a numeric The number to find the absolute value of
 *
 * @returns numeric the absolute value of \c a
 */
abs(a)
{
    debugPrint("in waypoints::abs()", "fn", level.nonVerbose);

    if (a < 0) {return a * -1;}
    return a;
}

/**
 * @brief Builds the k-dimensional waypoint tree
 *
 * ***Recursive***
 *
 * @param waypointList array waypoint structs to build the tree with
 * @param depth integer the current depth of the tree
 *
 * @returns node the root node of the tree
 */
kdWaypointTree(waypointList, depth)
{
    debugPrint("in waypoints::kdWaypointTree()", "fn", level.nonVerbose);

    level.treeCalls++;
    if (!isDefined(depth)) {depth = 0;}

    k = 3;              // our waypoints are in R^3
    axis = depth % k;   // cycle the posssible axis each recursion

    waypointList = kdWaypointHeapsort(waypointList, waypointList.size, axis);

    median = int(waypointList.size / 2);   // find the middle element in the sorted waypointList

    // ensure the element just before median is smaller than median, so that the
    // right subarray will be composed of all elements greater than or equal to median.origin[axis]
    splittingValue = waypointList[median].origin[axis];
    while ((isDefined(waypointList[median + 1])) &&
        (waypointList[median + 1].origin[axis] == splittingValue))
    {
        median++;
    }

    // grab all the elements less than the median element
    leftPointList = [];
    for (i=0; i<median; i++) {
        leftPointList[i] = waypointList[i];
    }
    // grab all the elements greater than the median element
    rightPointList = [];
    for (i=median + 1; i<waypointList.size; i++) {
        rightPointList[rightPointList.size] = waypointList[i];
    }

    node = spawnStruct();
    level.nodes++;

    node.id = waypointList[median].id;
    if (leftPointList.size == 0) {
        node.leftChild = undefined;
    } else {
        node.leftChild = kdWaypointTree(leftPointList, depth+1);
    }
    if (rightPointList.size == 0) {
        node.rightChild = undefined;
    } else {
        node.rightChild = kdWaypointTree(rightPointList, depth+1);
    }

    return node;
}

/**
 * @brief Sorts an array of waypoint structs by axis using heapsort
 *
 * @param array the array to sort
 * @param count integer the size of the array
 * @param axis integer the index of the dimension in the origin to sort by.  For 3D, [0|1|2]
 *
 * @returns array the sorted array
 */
kdWaypointHeapsort(array, count, axis)
{
    debugPrint("in waypoints::kdWaypointHeapsort()", "fn", level.medVerbosity);

    // first place a in max-heap order
    array = kdWaypointHeapify(array, count, axis);

    end = count - 1; // in languages with zero-based arrays the children are 2*i+1 and 2*i+2
    while (end > 0) {
        // swap the root(maximum value) of the heap with the last element of the heap
        temp = array[end];
        array[end] = array[0];
        array[0] = temp;

        // decrease the size of the heap by one so that the previous max value will
        // stay in its proper placement
        end--;
        // put the heap back in max-heap order
        array = kdWaypointSiftDown(array, 0, end, axis);
    }
    return array;
}

/**
 * @brief Heapify an arry of waypoint structs by axis
 *
 * @param array the array to heapify
 * @param count integer the size of the array
 * @param axis integer the index of the dimension in the origin to heapify by.  For 3D, [0|1|2]
 *
 * @returns array the sorted array as a heap
 */
kdWaypointHeapify(array, count, axis)
{
    debugPrint("in waypoints::kdWaypointHeapify()", "fn", level.medVerbosity);

    // start is assigned the index in array of the last parent node
    start = int((count - 2) / 2);

    while (start >= 0) {
        // sift down the node at index start to the proper place such that all
        // nodes below the start index are in heap order
        array = kdWaypointSiftDown(array, start, count - 1, axis);
        start--;
        // after sifting down the root all nodes/elements are in heap order
    }
    return array;
}

/**
 * @brief Move an element down to its correct position in the heap
 *
 * A helper function for kdWaypointHeapsort() and kdWaypointHeapify()
 *
 * @param array the array as a heap to reorder
 * @param start integer the starting position in the array
 * @param end integer the end position in the array
 * @param axis integer the index of the dimension in the origin to reorder by.  For 3D, [0|1|2]
 *
 * @returns array the sorted array as a heap
 */
kdWaypointSiftDown(array, start, end, axis)
{
    debugPrint("in waypoints::kdWaypointSiftDown()", "fn", level.highVerbosity);

    // end represents the limit of how far down the heap to sift.
    root = start;

    while (root * 2 + 1 <= end) {       // while the root has at least one child
        child = root * 2 + 1;           // root*2 + 1 points to the left child
        swap = root;                    // keeps track of child to swap with

        // check if root is smaller than left child
        if (array[swap].origin[axis] < array[child].origin[axis]) {
            swap = child;
        }
        // check if right child exists, and if it's bigger than what we're currently swapping with
        if ((child + 1 <= end) && (array[swap].origin[axis] < array[child + 1].origin[axis])) {
            swap = child + 1;
        }
        // check if we need to swap at all
        if (swap != root) {
            temp = array[root];
            array[root] = array[swap];
            array[swap] = temp;
            root = swap;                // repeat to continue sifting the child down
        } else {
            return array;
        }
    }
    return array;
}

/// just for verifying that heapsort works properly
printArray(array, axis, pivotIndex)
{
    debugPrint("in waypoints::printArray()", "fn", level.nonVerbose);

    data = "";
    if (!isDefined(pivotIndex)) {pivotIndex = 0;}

    if (axis == 0) {data = "[x-axis]";}
    else if (axis == 1) {data = "[y-axis]";}
    else if (axis == 2) {data = "[z-axis]";}

    for (i=0; i<array.size; i++) {
        if (i == pivotIndex) {
            data = data + " **[" + array[i].origin[axis] + "]**";
        } else {
            data = data + " [" + array[i].origin[axis] + "]";
        }
    }
    return data;
}

printTrace(trace, from, to, ignoreEntity)
{
    fraction = trace["fraction"];
    position = trace["position"];
    entity = trace["entity"];
    surface = trace["surfacetype"];
    switch (surface) {
        case "wood":       // fall through
        case "metal":      // fall through
        case "brick":      // fall through
        case "plaster":      // fall through
        case "plastic":      // fall through
        case "asphalt":      // fall through
        case "dirt":      // fall through
        case "rubber":      // fall through
        case "concrete":
//             return;
    }
    normal = trace["normal"];
    name = "";
    if (!isDefined(entity)) {entity = "undefined";}
    else {
        if ((isDefined(trace["entity"].isBot)) && (trace["entity"].isBot)) {entity = "bot";}
        else if (isPlayer(trace["entity"])) {entity = "player";}
        else if ((isDefined(trace["entity"].isCorpse)) && (trace["entity"].isCorpse)) {entity = "corpse";}
        else {
            entity = "defined";
//             number = trace["entity"] getEntityNumber();
//             ignoreNumber = ignoreEntity getEntityNumber();
//             if (number == ignoreNumber) {
//                 noticePrint("hit entity is the ignore entity.  number: " + number);
//             }
        }
        if (isDefined(trace["entity"].name)) {name = trace["entity"].name;}
    }
    if (trace["fraction"] == 0) {
    }

    noticePrint("trace(from, to, fraction, position, entity, name, surface, normal): (" + from + ", " + to + ", " + fraction + ", " + position + ", " + entity + ", " + name + ", " + surface + ", " + normal + ")");
}

isPathClear(from, to, ignoreEntity)
{
    origin = from;
    originalEntity = ignoreEntity;
    originalTo = to;
    from = from + (0,0,40);
    to = to + (0,0,40);
    count = 0;

    // this is the case when crawlers and hell zombies first spawn.
    if (from == to) {return 1;}

    trace = undefined;
    direction = vectorNormalize(to - from);

    while ((from != to) && (count < 10)) {
        count++;
        trace = bullettrace(from, to, false, ignoreEntity);
        if (trace["fraction"] == 1) {
            return 1;
        } else {
            // We did not complete our trace
            if (!isDefined(trace["entity"])) {
                // we hit something other than an entity
                return -1;
            }
            // We hit an entity

            // bail if we hit our own corpse!
            if ((isDefined(trace["entity"].isCorpse)) && (trace["entity"].isCorpse)) {
                if (trace["entity"].origin == origin) {return -2;}
            }

            if (((isDefined(trace["entity"].isCorpse)) && (trace["entity"].isCorpse)) ||    // ignore corpses other than ours
                ((isDefined(trace["entity"].isBot)) && (trace["entity"].isBot)) ||          // ignore other bots
                ((isDefined(trace["entity"].isBarrel)) && (trace["entity"].isBarrel)) ||    // ignore barrels
                ((isDefined(trace["entity"].isBarricade)) && (trace["entity"].isBarricade)) || // ignore barricades
                ((isDefined(trace["entity"].isTurret)) && (trace["entity"].isTurret)) ||    // ignore defense turrets
                ((isDefined(trace["entity"].isTeleporter)) && (trace["entity"].isTeleporter))) // ignore teleporters
            {
                if (trace["fraction"] < 0.01) {
                    distance = distanceSquared(trace["position"], to);
                    if (distance < 9) {
                        // close enough!
                        return 1;
                    } else if (distance > 225) {
                        // if we are more than 15 units from 'to', add 15 units to try and get past this corpse
                        ignoreEntity = trace["entity"];
                        from = trace["position"] + (15 * direction);
                    } else if (distance > 81) {
                        ignoreEntity = trace["entity"];
                        from = trace["position"] + (9 * direction);
                    } else {
                        ignoreEntity = trace["entity"];
                        from = trace["position"] + (3 * direction);
                    }
                } else {
                    ignoreEntity = trace["entity"];
                    from = trace["position"];
                }
            } else {
                // we hit something solid that should stop us, like a wall, ceiling, etc.
                return -1;
            }
            // at this point, we have either returned, or we have changed ignoreEntity
            // and from to prepare for the next trace
        } // ends trace["fraction"] < 1
    } // end while

    if (count >= 10) {
        errorPrint("could not complete a trace within 10 tries, debugging");
        iPrintLnBold("Limit Error");
        debugIsPathClear(origin, originalTo, originalEntity);
        clearDistance = distance(origin + (0,0,40), trace["position"]);
        return clearDistance;
    } else {
        errorPrint("reached end of function without returning, debugging. count: " + count);
        iPrintLnBold("Return Error");
        debugIsPathClear(origin, originalTo, originalEntity);
    }

    // this represents a bug!
    return -3;
}

debugIsPathClear(from, to, ignoreEntity)
{
    origin = from;
    originalEntity = ignoreEntity;
    from = from + (0,0,40);
    to = to + (0,0,40);
    count = 0;

    trace = undefined;
    direction = vectorNormalize(to - from);

    while ((from != to) && (count < 10)) {
        count++;
        trace = bullettrace(from, to, false, ignoreEntity);
        printTrace(trace, from, to, ignoreEntity);
        if (trace["fraction"] == 1) {
            return 1;
        } else {
            // We did not complete our trace
            if (!isDefined(trace["entity"])) {
                // we hit something other than an entity
                return -1;
            }
            // We hit an entity

            // bail if we hit our own corpse!
            if ((isDefined(trace["entity"].isCorpse)) && (trace["entity"].isCorpse)) {
                if (trace["entity"].origin == origin) {return -2;}
            }

            if ((isDefined(trace["entity"].isCorpse)) && (trace["entity"].isCorpse)) {
                noticePrint("hit a corpse");
            } else if ((isDefined(trace["entity"].isBot)) && (trace["entity"].isBot)) {
                noticePrint("hit another bot");
            } else if ((isDefined(trace["entity"].isBarrel)) && (trace["entity"].isBarrel)) {
                noticePrint("hit a barrel");
            } else if ((isDefined(trace["entity"].isBarricade)) && (trace["entity"].isBarricade)) {
                noticePrint("hit a barricade");
            } else if ((isDefined(trace["entity"].isTurret)) && (trace["entity"].isTurret)) {
                noticePrint("hit a turret");
            } else if ((isDefined(trace["entity"].isTeleporter)) && (trace["entity"].isTeleporter)) {
                noticePrint("hit a teleporter");
            } else {
                // we hit something solid that should stop us, like a wall, ceiling, etc.
                noticePrint("hit entity is defined, but it isn't one we should ignore");
            }

            if (((isDefined(trace["entity"].isCorpse)) && (trace["entity"].isCorpse)) ||    // ignore corpses other than ours
                ((isDefined(trace["entity"].isBot)) && (trace["entity"].isBot)) ||          // ignore other bots
                ((isDefined(trace["entity"].isBarrel)) && (trace["entity"].isBarrel)) ||    // ignore barrels
                ((isDefined(trace["entity"].isBarricade)) && (trace["entity"].isBarricade)) || // ignore barricades
                ((isDefined(trace["entity"].isTurret)) && (trace["entity"].isTurret)) ||    // ignore defense turrets
                ((isDefined(trace["entity"].isTeleporter)) && (trace["entity"].isTeleporter))) // ignore teleporters
            {
                if (trace["fraction"] < 0.01) {
                    distance = distanceSquared(trace["position"], to);
                    if (distance < 9) {
                        // close enough!
                        return 1;
                    } else if (distance > 225) {
                        // if we are more than 15 units from 'to', add 15 units to try and get past this corpse
                        ignoreEntity = trace["entity"];
                        from = trace["position"] + (15 * direction);
                    } else if (distance > 81) {
                        ignoreEntity = trace["entity"];
                        from = trace["position"] + (9 * direction);
                    } else {
                        ignoreEntity = trace["entity"];
                        from = trace["position"] + (3 * direction);
                    }
                } else {
                    ignoreEntity = trace["entity"];
                    from = trace["position"];
                }
            } else {
                // we hit something solid that should stop us, like a wall, ceiling, etc.
                return -1;
            }
            // at this point, we have either returned, or we have changed ignoreEntity
            // and from to prepare for the next trace
        } // ends trace["fraction"] < 1
    } // end while
}


/**
 * @brief Performs a Nearest Neighbor search on the k-dimensional waypoint tree
 *
 * ***Recursive***
 *
 * @param root node The node to begin the search at
 * @param origin the point we want to find the closest waypoint to
 * @param staticIndex integer the index in level.static that will hold the bestDistance
 * @param parent node the parent of the current node
 * @param depth integer the current depth of the tree
 *
 * The number of nearest neighbors found is determined by the size of the
 * level.static[staticIndex] array
 *
 * @returns nothing
 */
kdWaypointNearestNeighbors(root, origin, staticIndex, parent, depth)
{
    // 10th most-called function (2% of all function calls).
    // Do *not* put a function entrance debugPrint statement here!

    if (!isDefined(root)) {
        return;
    }

    if (!isDefined(depth)) {depth = 0;}

    k = level.static[staticIndex].size; // find k closest waypoints
    r = 3;                              // our waypoints are in R^3
    axis = depth % r;                   // cycle the axis each recursion

    // instrumentation
    dim = "";
    if (axis == 0) {dim = "x";}
    else if (axis == 1) {dim = "y";}
    else if (axis == 2) {dim = "z";}
    originDim = origin[axis];
    nodeDim = level.Wp[root.id].origin[axis];
    dimDelta = nodeDim - originDim;

    // original
    // distance from current node to the search point
    distance = distanceSquared(level.Wp[root.id].origin, origin);
    level.kdTreeNodeVisitCount++;

    // level.static[staticIndex] holds best distances and best nodes

    // Starting at the right end of the array, shift elements larger than
    // newValue to the right until we are where newValue belongs, then put newValue
    // there.
    j = k - 1;
    if (distance < level.static[staticIndex][j].distanceSquared) {
        // we have a new closer distance, sort it into the array
        while ((j > 0) && (distance < level.static[staticIndex][j-1].distanceSquared)) {
            level.static[staticIndex][j].distanceSquared = level.static[staticIndex][j-1].distanceSquared;
            level.static[staticIndex][j].node = level.static[staticIndex][j-1].node;
            j--;
        }
        level.static[staticIndex][j].distanceSquared = distance;
        level.static[staticIndex][j].node = root;
        level.static[staticIndex][k] = undefined;
    }

    // walk the tree until we get to the correct leaf node. If the dimensional coordinate
    // of the search point is less than the dimensional coordinate of the current node,
    // corresponding to a positive dimDelta, then we proceed to the left child,
    // otherwise we proceed to the right child.
    if (dimDelta > 0) {
        kdWaypointNearestNeighbors(root.leftChild, origin, staticIndex, root, depth+1);
    } else {
        kdWaypointNearestNeighbors(root.rightChild, origin, staticIndex, root, depth+1);
    }
    // At this point, we have the closest waypoint to the search point that we found
    // in our walk to the leaf node

    // Make sure dimDistance is positive, as distances must be, but preserve sign
    // of dimDelta so we can decide which child to visit if the hypersphere intersects
    // the hyperplane.
    if (dimDelta < 0) {dimDistance = dimDelta * -1;}
    else {dimDistance = dimDelta;}
    dimDistance = dimDistance * dimDistance;    // squared, as we compare with a distanceSquared()

    // As we unwind the recursion back to the root node, we need to examine each node
    // to see if the actual closest waypoint may be in the current node's other branch,
    // i.e. does the hypersphere of bestDistance radius cross the node's splitting plane?
    // If it doesn't cross it, then we can rule out this node's other child as potentially
    // containing a closer waypoint--otherwise we need to check the other branch
    checkOtherBranch = false;
    for (j=0; j<level.static[staticIndex].size; j++) {
        if (level.static[staticIndex][j].distanceSquared > dimDistance) {
            checkOtherBranch = true;
            break;
        }
    }
    if (checkOtherBranch) {
        // hypersphere crosses hyperplane, so recurse into other branch to search for
        // a potentially closer node
        if (dimDelta > 0) {
            kdWaypointNearestNeighbors(root.rightChild, origin, staticIndex, root, depth+1);
        } else {
            kdWaypointNearestNeighbors(root.leftChild, origin, staticIndex, root, depth+1);
        }
    } else {
        // hypersphere doesn't intersect hyperplane, so we can rule out this node's
        // other branch as potentially containing a closer waypoint
        return;
    }
    return;
}


/**
 * @brief Performs a Nearest Neighbor search on the k-dimensional waypoint tree
 *
 * ***Iterative***
 *
 * @param root node The node to begin the search at
 * @param origin the point we want to find the closest waypoint to
 * @param staticIndex integer the index in level.static that will hold the bestDistance
 *
 * This is an interative implementation of the same recursive function, just
 * faster because it avoids the function packing & unpacking overhead used
 * in recursion.
 *
 * The number of nearest neighbors found is determined by the size of the
 * level.static[staticIndex] array
 *
 * @returns nothing
 */
kdWaypointNearestNeighborsIterative(root, origin, staticIndex)
{
    // 10th most-called function (2% of all function calls).
    // Do *not* put a function entrance debugPrint statement here!

    // Iterative version of kdWaypointNearestNeighbors (exact same logic, same node visit order,
    // same pruning decisions, same k-best updates). Use this to compare performance / correctness
    // against the recursive version.

    if (!isDefined(root)) {
        return;
    }

    k = level.static[staticIndex].size; // number of neighbors we are searching for
    r = 3;                              // waypoints are in R^3

    // Stack that simulates the recursion "call frames" for backtracking.
    // Each frame holds the node we have already visited and the information needed
    // to decide whether its "other" child needs to be explored later.
    pathStack = scripts\include\stack::new();

    current = root;
    currentDepth = 0;

    limit = 500;
    count = 0;
    while (true) {
        if (count > limit) {return;} // safety
        count++;
        /**
         * Go DOWN the preferred path (exactly like the first
         * recursive call in the original function).
         * We update the k-best list at every node we touch.
         */
        while (isDefined(current)) {
            // Copy of the original "update best" block
            distance = distanceSquared(level.Wp[current.id].origin, origin);
            level.kdTreeNodeVisitCount++;

            j = k - 1;
            if (distance < level.static[staticIndex][j].distanceSquared) {
                // we have a new closer distance, sort it into the array
                // potential infinite loop at 55k calls/frame, cod4 kills thread
                while ((j > 0) && (distance < level.static[staticIndex][j-1].distanceSquared)) {
                    level.static[staticIndex][j].distanceSquared = level.static[staticIndex][j-1].distanceSquared;
                    level.static[staticIndex][j].node = level.static[staticIndex][j-1].node;
                    j--;
                }
                level.static[staticIndex][j].distanceSquared = distance;
                level.static[staticIndex][j].node = current;
                level.static[staticIndex][k] = undefined;
            }

            // Compute axis and dimDelta (same math as the recursive version)
            axis = currentDepth % r;
            originDim = origin[axis];
            nodeDim = level.Wp[current.id].origin[axis];
            dimDelta = nodeDim - originDim;

            // Push a frame so we can backtrack later and decide about the "other" child
            frame = spawnStruct();
            frame.node = current;
            frame.depth = currentDepth;
            frame.dimDelta = dimDelta;
            pathStack push(frame);

            // Move to the preferred child (exactly as recursive version)
            if (dimDelta > 0) {
                current = current.leftChild;
            } else {
                current = current.rightChild;
            }
            currentDepth++;
        }

        /**
         * Backtrack up the path and check the "other" branch
         * for each node (exactly the unwind logic from the
         * original recursive function).
         */
        while (pathStack size() > 0) {
            // Pop the top frame (this is the node we are now considering for its other child)
            frame = pathStack pop();

            dimDelta = frame.dimDelta;
            nodeForCheck = frame.node;

            // Copy of the original dimDistance and checkOtherBranch logic from recirsive
            if (dimDelta < 0) {
                dimDistance = dimDelta * -1;
            } else {
                dimDistance = dimDelta;
            }
            dimDistance = dimDistance * dimDistance;    // squared

            checkOtherBranch = false;
            for (j = 0; j < level.static[staticIndex].size; j++) {
                if (level.static[staticIndex][j].distanceSquared > dimDistance) {
                    checkOtherBranch = true;
                    break;
                }
            }

            if (checkOtherBranch) {
                otherChild = undefined;
                // Hypersphere crosses the splitting plane, so recurse into other branch to search for
                // a potentially closer node
                if (dimDelta > 0) {
                    otherChild = nodeForCheck.rightChild;
                } else {
                    otherChild = nodeForCheck.leftChild;
                }

                if (isDefined(otherChild)) {
                    // Instead of recursing, we jump back to the "down" phase with this new subtree
                    current = otherChild;
                    currentDepth = frame.depth + 1;
                    break;   // exit the backtrack loop and let the outer while restart the down phase
                }
            }
            // hypersphere doesn't intersect hyperplane, so we can rule out this node's
            // other branch as potentially containing a closer waypoint
        }

        // If stack is empty, we are done
        if (pathStack size() == 0 && !isDefined(current)) {
            break;
        }
    }
}


/**
 * @brief Prints the k-dimensional tree to the server log
 *
 * ***Recursive***
 * Due to severe string limitations, we can't print 'large' trees, nor even include
 * anything other that the waypoint id in the printout.
 *
 * @param node the node to print
 * @param depth integer the depth of \c node in the tree
 *
 * @returns nothing
 */
kdPrintNode(node, depth)
{
    debugPrint("in waypoints::kdPrintNode()", "fn", level.medVerbosity);

    // pre-order traversal
    if(!isDefined(node)) {return;}

    k = 3;              // our waypoints are in R^3
    axis = depth % k;   // cycle the posssible axis each recursion
    dim = 0;
    if (axis == 0) {dim = "x";}
    else if (axis == 1) {dim = "y";}
    else if (axis == 2) {dim = "z";}

    padding = "  ";
    level.kdText[depth] += padding + node.id;

    kdPrintNode(node.leftChild, depth+1);
    kdPrintNode(node.rightChild, depth+1);
}

/**
 * @brief Validates the structure of the k-dimensional tree
 *
 * ***Recursive***
 *
 * @param node the node to validate
 * @param depth integer the depth of \c node in the tree
 *
 * @returns nothing
 */
kdValidateNode(node, depth)
{
    debugPrint("in waypoints::kdValidateNode()", "fn", level.medVerbosity);

    // pre-order traversal
    if(!isDefined(node)) {return;}

    k = 3;              // our waypoints are in R^3
    axis = depth % k;   // cycle the possible axis each recursion
    dim = "";
    if (axis == 0) {dim = "x";}
    else if (axis == 1) {dim = "y";}
    else if (axis == 2) {dim = "z";}

    if (depth > level.maxDepth) {level.maxDepth = depth;}

    // for each node, inspect the current axis dimension and compare it to the same
    // axis of its children. The leftChild's axis dimension must be smaller than or equal to the
    // parent's, and the rightChild's axis dimension must be greater than the parent's.
    if (isDefined(node.leftChild)) {
        if (level.Wp[node.leftChild.id].origin[axis] > level.Wp[node.id].origin[axis]) {
            noticePrint("Node " + node.id + "'s .leftChild " + dim + "-axis is > the node's " + dim + "-axis, but it should be smaller or equal!");
        }
    }
    if (isDefined(node.rightChild)) {
        if (level.Wp[node.rightChild.id].origin[axis] <= level.Wp[node.id].origin[axis]) {
            noticePrint("Node " + node.id + "'s .rightChild " + dim + "-axis is <= the node's " + dim + "-axis, but it should be larger!");
        }
    }
    kdValidateNode(node.leftChild, depth+1);
    kdValidateNode(node.rightChild, depth+1);
}

/**
 * @brief Generates a pseudo-random 3D point
 *
 * @param useMapExtents boolean limit points to points *within* the 3D volume subtended by the waypoints?
 *
 * @returns tuple representing a random 3D point
 */
random3dPoint(useMapExtents)
{
    debugPrint("in waypoints::random3dPoint()", "fn", level.fullVerbosity);

    if (!isDefined(useMapExtents)) {useMapExtents = false;}

    if (useMapExtents) {
        x = randomFloatRange(level.waypointMinX, level.waypointMaxX);
        y = randomFloatRange(level.waypointMinY, level.waypointMaxY);
        z = randomFloatRange(level.waypointMinZ, level.waypointMaxZ);
    } else {
        factor = 1.50;
        x = randomFloatRange(level.waypointMinX * factor, level.waypointMaxX * factor);
        y = randomFloatRange(level.waypointMinY * factor, level.waypointMaxY * factor);
        z = randomFloatRange(level.waypointMinZ * factor, level.waypointMaxZ * factor);
    }

    return (x, y, z);
}

/**
 * @brief Finds the extents of the waypoints in the map
 *
 * @returns nothing
 */
findWaypointExtents()
{
    debugPrint("in waypoints::findWaypointExtents()", "fn", level.nonVerbose);

    level.waypointMinX = 0;
    level.waypointMaxX = 0;
    level.waypointMinY = 0;
    level.waypointMaxY = 0;
    level.waypointMinZ = 0;
    level.waypointMaxZ = 0;

    for (i=0; i<level.WpCount; i++) {
        if (level.Wp[i].origin[0] < level.waypointMinX) {level.waypointMinX = level.Wp[i].origin[0];}
        if (level.Wp[i].origin[0] > level.waypointMaxX) {level.waypointMaxX = level.Wp[i].origin[0];}
        if (level.Wp[i].origin[1] < level.waypointMinY) {level.waypointMinY = level.Wp[i].origin[1];}
        if (level.Wp[i].origin[1] > level.waypointMaxY) {level.waypointMaxY = level.Wp[i].origin[1];}
        if (level.Wp[i].origin[2] < level.waypointMinZ) {level.waypointMinZ = level.Wp[i].origin[2];}
        if (level.Wp[i].origin[2] > level.waypointMaxZ) {level.waypointMaxZ = level.Wp[i].origin[2];}
    }
}


/*
 * @brief Gets the nearest N waypoint to a given position
 *
 * @param origin vector representing the 3D point to find the nearest waypoint to
 * @param n integer Return n nearest waypoints to the \c origin
 *
 * @returns array of integers representing the indices of the nearest waypoint(s)
 */
nearestWaypoints(origin, n, hintWp) {
    // KD Tree (Iterative) is always good, but on modern hardware, direct iteration is
    // better on small waypoint maps.  They break even at about 250 waypoints.

    // Use KD Tree on large maps, else direct iteration
    // TODO: only build the KD Tree at map load if we are going to use it
    if (level.Wp.size > 250) {
        level.useKdWaypointTree = true;
        return nearestWaypointsKDIterative(origin, n);
    } else {
        return nearestWaypointsIteration(origin, n);
    }
}


/** @private Call nearestWaypoints() from code
 * @brief Finds the nearest waypoint(s) to an arbitrary point
 *
 *        Uses the k-dimensional waypoint tree.
 *
 * @param origin vector representing the 3D point to find the nearest waypoint to
 * @param n integer Return n nearest waypoints to the \c origin
 *
 * @returns array of integers representing the indices of the nearest waypoint(s)
 */
nearestWaypointsKD(origin, n)
{
    // 10th most-called function (2% of all function calls).
    // Do *not* put a function entrance debugPrint statement here!

    if (!isDefined(n)) {n = 3;}

    // get an available static member
    index = availableStatic();
    level.static[index] = [];

    // original
    for (i=0; i<n; i++) {
        best = spawnStruct();
        best.node = 0;
        best.distanceSquared = (-1 * (n - i)) + level.MAX_INT;   // 2147483647, 32-bit ints
        level.static[index][level.static[index].size] = best;
    }
    count = level.kdTreeNodeVisitCount;
    kdWaypointNearestNeighbors(level.kdWpTree, origin, index);
    nodesThisCall = level.kdTreeNodeVisitCount - count;

    // prepare results
    results = [];
    for (i=0; i<n; i++) {
        results[i] = level.static[index][i].node.id;
    }

    // recycle the static member
    level.static[index] = 0;
    level.staticStack[level.staticStack.size] = index;

    return results;
}


/** @private Call nearestWaypoints() from code
 * @brief Finds the nearest waypoint(s) to an arbitrary point
 *
 *        Uses the k-dimensional waypoint tree.
 *
 * @param origin vector representing the 3D point to find the nearest waypoint to
 * @param n integer Return n nearest waypoints to the \c origin
 *
 * @returns array of integers representing the indices of the nearest waypoint(s)
 */
nearestWaypointsKDIterative(origin, n)
{
    // 10th most-called function (2% of all function calls).
    // Do *not* put a function entrance debugPrint statement here!

    if (!isDefined(n)) {n = 3;}

    // get an available static member
    index = availableStatic();
    level.static[index] = [];

    // original
    for (i=0; i<n; i++) {
        best = spawnStruct();
        best.node = 0;
        best.distanceSquared = (-1 * (n - i)) + level.MAX_INT;   // 2147483647, 32-bit ints
        level.static[index][level.static[index].size] = best;
    }
    count = level.kdTreeNodeVisitCount;
    // new (iterative):
    kdWaypointNearestNeighborsIterative(level.kdWpTree, origin, index);
    nodesThisCall = level.kdTreeNodeVisitCount - count;

    // prepare results
    results = [];
    for (i=0; i<n; i++) {
        results[i] = level.static[index][i].node.id;
    }

    // recycle the static member
    level.static[index] = 0;
    level.staticStack[level.staticStack.size] = index;

    return results;
}


/** @private Call nearestWaypoints() from code
 * @brief Finds the nearest waypoint(s) to an arbitrary point
 *
 *        Uses direct iteration.
 *
 * @param origin vector representing the 3D point to find the nearest waypoint to
 * @param n integer Return n nearest waypoints to the \c origin
 *
 * @returns array of integers representing the indices of the nearest waypoint(s)
 */
nearestWaypointsIteration(origin, n)
{
    closest = [];
    // ensure the initial array is sorted
    for (i=0; i<n; i++) {
        waypoint = spawnStruct();
        waypoint.id = -1;
        waypoint.distanceSquared = (-1 * (n - i)) + level.MAX_INT;   // 2147483647, 32-bit ints
        closest[closest.size] = waypoint;
    }

    // brute-force method
    for (i=0; i<level.WpCount; i++) {
        distance = distanceSquared(origin, level.Wp[i].origin);
        if (distance >= closest[n-1].distanceSquared) {continue;}

        j = n - 1;
        // If we have new closest wwaypoint, insert it into closeest[], in order
        // Starting at the right end of the array, shift elements larger than
        // newValue to the right until we are where newValue belongs, then put newValue
        // there.
        while ((j > 0) && (distance < closest[j-1].distanceSquared)) {
            closest[j].distanceSquared = closest[j-1].distanceSquared;
            closest[j].id = closest[j-1].id;
            j--;
        }
        closest[j].distanceSquared = distance;
        closest[j].id = i;
        closest[n] = undefined;
    }
    results = [];
    for (i=0; i<n; i++) {
        results[i] = closest[i].id;
    }
    return results;
}


/** @private Call nearestWaypoints() from code
 * @brief Finds the nearest waypoint(s) to an arbitrary point
 *
 *        Uses BFS (Breadth First Search.  It is a dog, don't use it.
 *
 * @param origin vector representing the 3D point to find the nearest waypoint to
 * @param n integer Return n nearest waypoints to the \c origin
 * @param hintWp integer The index in level.Wp[] of the last known nearest waypiont
 *
 * @returns array of integers representing the indices of the nearest waypoint(s)
 */
nearestWaypointsBFS(origin, n, hintWp)
{
    if (!isDefined(n)) {
        n = 3;
    }

    if (!isDefined(hintWp)) {
        log("dev", "msg|hintWp is undefined, falling back to K-D Tree||");
        return nearestWaypointsKD(origin, n);   // fallback to K-D Tree
    }
    dist = distanceSquared(origin, level.Wp[hintWp].origin);
    if (dist > 2000000) { // 1000 units squared
        log("dev", "msg|hintWp is too far away, falling back to K-D Tree||");
        return nearestWaypointsKD(origin, n);   // fallback to K-D Tree
    }

    // log("dev", "msg|Attempting BFS graph search||");
    index = availableStatic();
    level.static[index] = [];

    // Pre-fill with worst possible scores (same style you already use)
    for (i=0; i<n; i++) {
        best = spawnStruct();
        best.node = 0;
        best.distanceSquared = (-1 * (n - i)) + level.MAX_INT;
        level.static[index][level.static[index].size] = best;
    }

    // Seed with hintWp + its direct neighbors
    insertCandidate(index, hintWp, origin);

    if (isDefined(level.Wp[hintWp].linked)) {
        for (i=0; i<level.Wp[hintWp].linked.size; i++) {
            childWp = level.Wp[hintWp].linked[i].ID;
            if (childWp != hintWp)
                insertCandidate(index, childWp, origin);
        }
    }

    // BFS using index pointer instead of popping from front
    queue = [];
    visited = [];
    queue[0] = hintWp;
    visited[0] = hintWp;
    head = 0;                    // pointer to front of queue
    tail = 1;                    // next free slot in queue
    maxDepth = 3;                // 2 or 3 is usually plenty
    currentDepth = 0;
    nodesThisLevel = 1;

    limit = 50;
    count = 0;
    while ((head < tail) && (currentDepth < maxDepth)) {
        count++;
        sizeThisLevel = nodesThisLevel;
        nodesThisLevel = 0;

        for (i=0; i<sizeThisLevel; i++) {
            currentWp = queue[head];
            head++;

            if (!isDefined(level.Wp[currentWp].linked))
                continue;

            for (j=0; j<level.Wp[currentWp].linked.size; j++) {
                childWp = level.Wp[currentWp].linked[j].ID;

                // check if already visited
                alreadyVisited = false;
                for (k=0; k<visited.size; k++) {
                    if (visited[k] == childWp) {
                        alreadyVisited = true;
                        break;
                    }
                }

                if (alreadyVisited) {
                    continue;
                }

                visited[visited.size] = childWp;
                insertCandidate(index, childWp, origin);

                queue[tail] = childWp;
                tail++;
                nodesThisLevel++;
            }
        }
        currentDepth++;
        if (count > limit) {
            log("dev", "msg|Bailing on while() in nearestWaypoints_local()||");
            break;
        }        
    }

    // Extract the top N results
    results = [];
    for (i=0; i<n; i++) {
        if (isDefined(level.static[index][i])) {
            results[i] = level.static[index][i].node.id;
        } else {
            break;
        }
    }

    // Recycle static slot
    level.static[index] = 0;
    level.staticStack[level.staticStack.size] = index;

    // log("dev", sprintfLog("msg|BFS results||size|$1||closetWP|$2||", results.size, results[0]));

    return results;
}


/** @private
 * @brief Helper for nearesWaypointsBFS()
 *
 * @returns nothing
 */
insertCandidate(staticIndex, wpId, origin)
{
    if (!isDefined(level.Wp[wpId])) {
        return;
    }

    dist = distanceSquared(origin, level.Wp[wpId].origin);
    arr = level.static[staticIndex];
    k = arr.size;

    j = k - 1;
    if (dist >= arr[j].distanceSquared) {
        return;   // not good enough
    }

    // shift larger elements right
    limit = 50;
    count = 0;
    while ((j > 0) && (dist < arr[j-1].distanceSquared)) {
        count++;
        arr[j].distanceSquared = arr[j-1].distanceSquared;
        arr[j].node = arr[j-1].node;
        j--;
        if (count > limit) {
            break;
            log("dev", "msg|Bailing on while() in insertCandidate()||");
        }
    }

    arr[j].distanceSquared = dist;
    arr[j].node = level.Wp[wpId];
}


/**
 * @brief Tests the validity and compares the results from NN search and brute-force
 *
 * @param n integer the number of random 3D points fo find the nearest waypoint for
 * @param useMapExtents boolean limit search points to points *within* the 3D volume subtended by the waypoints?
 *
 * @returns nothing
 */
nearestWaypointsTest(n, useMapExtents)
{
    log("dev", "msg|Starting nearestWaypointsTest||");
    right = 0;
    wrong = 0;
    percentageRight = 0;
    treeSize = level.nodes;

    for (i=0; i<n; i++) {
        origin = random3dPoint(useMapExtents);   // if true, generate points within 3D volume covered by waypoints
        k = 3;

        // brute-force
        level.useKdWaypointTree = false;
        waypoints = nearestWaypoints(origin, k);

        // kd-tree method
        level.useKdWaypointTree = true;
        kdWaypoints = nearestWaypointsKDIterative(origin, k);

        right++;
        for (j=0; j<k; j++) {
            if (waypoints[j] != kdWaypoints[j]) {
                wrong++;
                right--;
                break;
            }
        }
    }

    // results
    percentageRight = (right / n) * 100;

    noticePrint("-------------------------------------------------------------------------------");
    noticePrint("Waypoint Count: " + level.Wp.size + " Tree Size: " + treeSize);
    if (useMapExtents) {
        noticePrint("Tested " + n + " random 3D points within the map extents.");
    } else {
        noticePrint("Tested " + n + " random 3D points.");
    }
    noticePrint("Accuracy (right, wrong): (" + right + ", " + wrong + ") " + percentageRight + " percent correct.");
    noticePrint("Total node visitations (kdtree): (" + level.kdTreeNodeVisitCount + ")");
    noticePrint("Average node visitations (kdtree): (" + level.kdTreeNodeVisitCount / n + ")");
    noticePrint("-------------------------------------------------------------------------------");
}


/*
 * @brief Tests how many iterations of nearestNeighbors() waypoint search can
 *        be perfomed in a single frame (0.05ms).
 *
 *        'Success' for a given algorithm & n is two log messages in server_mp.log,
 *        Search for 'Timed', should be 2 instances.  Failure is just one instance. 
 *
 * @returns nothing
 */
nearestWaypointsTimedTest()
{
    log("dev", "msg|Starting nearestWaypointsTimedTest||");

    n = 50000;
    // On map with 129 waypoints (mp_surv_gold_rush), in <50ms:
    // KD Tree (Iterative): 42,500 worked, 45,000 didn't
    // KD Tree (Recursive): 52,500 worked, 55,000 didn't
    // Iteration: 62,500 worked, 65,000 didn't
    // BFS: 10,000 worked, 12,500 didn't

    // On map with 286 waypoints (mp_bsf_backlot), in <50ms:
    // KD Tree (Iterative): 30,000 worked, 32,500 didn't
    // KD Tree (Recursive): 35,000 worked, 37,500 did once
    // Iteration: 30,000 worked, 35,000 didn't
    // BFS: 40,000 worked, 50,000 didn't

    // On map with 573 waypoints (mp_surv_isle), in <50ms:
    // KD Tree (Iterative): 22,500 worked, 25,000 didn't
    // KD Tree (Recursive): 15,500 worked, 16,500 didn't
    // Iteration: 16,500 worked, 17,500 didn't
    // BFS: 6,000 worked, 7,500 didn't

    // On map with 1076 waypoints (mp_fart_house_v2), in <50ms:
    // KD Tree (Iterative): 22,500 worked, 25,000 didn't
    // KD Tree (Recursive): 15,000 worked, 15,500 only worked once
    // Iteration: 8,500 worked, 9,500 didn't
    // BFS: 7,500 worked, 8,500 didn't
    useMapExtents = true;
    testBFS = false;
    testKD = false;
    testKD_Iteration = false;
    testIteration = false;

    start = getTime();  //ms
    wait 0.05;
    k = 3;
    for (i=0; i<n; i++) {
        if (testBFS) {
            a = 1;
            b = 1;
            if (i % 2 == 0) {a = -1;}
            if (i % 4 == 0) {b = -1;}
            hintWp = randomInt(level.Wp.size);
            offset = (a * randomInt(800), b * randomInt(800), 0);
            wporigin = level.Wp[hintWp].origin;
            origin = wporigin + offset;
            nearestWaypointsBFS(origin, k, hintWp);
        } else if (testIteration) {
            origin = random3dPoint(useMapExtents);   // if true, generate points within 3D volume covered by waypoints
            origin = origin * (1,1,0); // zero out y-axis
            waypoints = nearestWaypointsIteration(origin, k);
        } else if (testKD) {
            origin = random3dPoint(useMapExtents);   // if true, generate points within 3D volume covered by waypoints
            origin = origin * (1,1,0); // zero out y-axis
            level.useKdWaypointTree = true;
            kdWaypoints = nearestWaypointsKD(origin, k);
        } else if (testKD_Iteration) {
            origin = random3dPoint(useMapExtents);   // if true, generate points within 3D volume covered by waypoints
            origin = origin * (1,1,0); // zero out y-axis
            level.useKdWaypointTree = true;
            kdWaypoints = nearestWaypointsKDIterative(origin, k);
        }
    }
    end = getTime(); //ms
    elapsed = end - start;
    if (testBFS) {
        log("dev", sprintfLog("msg|Timed Test: BFS||count|$1:n||elapsed|$2:n", n, elapsed));
    } else if (testIteration) {
        log("dev", sprintfLog("msg|Timed Test: Iteration||count|$1:n||elapsed|$2:n", n, elapsed));
    } else if (testKD) {
        log("dev", sprintfLog("msg|Timed Test: K-D Tree (Recursive)||count|$1:n||elapsed|$2:n", n, elapsed));
    } else if (testKD_Iteration) {
        log("dev", sprintfLog("msg|Timed Test: K-D Tree (Iterative)||count|$1:n||elapsed|$2:n", n, elapsed));
    }
}


/**
 * @brief Writes some data to the server log about A* performance
 *
 * @returns nothing
 */
printAStarData()
{
    while (1) {
        wait 120;
        noticePrint("A* (calls, saved calls, distance() calls): (" + level.astarCalls + ", " + level.savedAStarCalls + ", " + level.astarDistanceCalls + ")");
    }
}

/**
 * @brief Perfoms testing comparing the old A* algorithm and the new A* alorithm
 *
 * @param n integer The number of tests to run
 *
 * @returns nothing
 */
validateAStar(n)
{
    right = 0;
    wrong = 0;

    for (i=0; i<n; i++) {
        waypoints = randomWaypointPairIndices();
        startWp = waypoints.start;
        goalWp = waypoints.goal;

        oldAStar = AStarOriginal(startWp, goalWp);
        newAStarNodes = AStarNew(startWp, goalWp);
        newAStar = newAStarNodes[newAStarNodes.size - 1];

        if (oldAStar == newAStar) {right++;}
        else {
            wrong++;
            noticePrint("old: " + oldAStar + " new: " + newAStar);
        }
    }

    noticePrint("A* validity (right, wrong): (" + right + ", " + wrong + ")");
}

/**
 * @brief Generate a random pair of waypoints
 *
 * @returns struct containing .start and .goal integer members
 */
randomWaypointPairIndices()
{
    start = 0;
    goal = 0;
    while (start == goal) {
        start = randomInt(level.Wp.size);
        goal = randomInt(level.Wp.size);
    }
    pair = spawnStruct();
    pair.start = start;
    pair.goal = goal;
    return pair;
}


// @todo: test bidriectional A*
/**
 * @brief Finds the best path between two waypoints
 *
 * @param startWp integer The index of the waypoint to begin the path at
 * @param goalWp integer The index of the waypoint to where the path ends
 * @param validateWaypoints boolean If true, validate the map's waypoints instead of finding a path
 *
 * @returns An integer stack of up to the first five waypoints in the path
 */
AStarNew(startWp, goalWp, validateWaypoints)
{
    // 20th most-called function (0.4% of all function calls).
    // Do *not* put a function entrance debugPrint statement here!
    level.astarCalls++;
    if (!isDefined(validateWaypoints)) {validateWaypoints = false;}

    pathNodes = [];

    pQOpen = [];
    pQSize = 0;
    closedList = [];
    listSize = 0;
    s = spawnstruct();
    s.g = 0; //start node
    s.h = distance(level.Wp[startWp].origin, level.Wp[goalWp].origin);
    level.astarDistanceCalls++;
    s.f = s.g + s.h;
    s.wpIdx = startWp;
    s.parent = spawnstruct();
    s.parent.wpIdx = -1;

    // push s on Open
    pQOpen[pQSize] = spawnstruct();
    pQOpen[pQSize] = s; //push s on Open
    pQSize++;

    // while Open is not empty
    while (pQSize > 0) {
        //pop node n from Open  // n has the lowest f
        n = pQOpen[0];
        highestPriority = level.MAX_INT; // 2147483647, 32-bit ints
        bestNode = -1;
        for (i=0; i<pQSize; i++) {
            if (pQOpen[i].f < highestPriority) {
                bestNode = i;
                highestPriority = pQOpen[i].f;
            }
        }

        if (bestNode != -1) {
            n = pQOpen[bestNode];
            //remove node from queue
            for (i=bestNode; i<pQSize-1; i++) {
                pQOpen[i] = pQOpen[i+1];
            }
            pQSize--;
        } else {
            errorPrint("AStarNew(" + startWp + ", " + goalWp + ") on map " + getdvar("mapname") + " failed to find a path.");
            return -1;
        }

        //if n is a goal node; construct path, return success
        if (n.wpIdx == goalWp) {
            x = n;
            path = "";
            while (x.parent.wpIdx != -1) {
                path = path + x.wpIdx + " ";
                pathNodes[pathNodes.size] = x.wpIdx; 
                // process the next node
                x = x.parent;
            }
            if (pathNodes.size == 0) { 
                // Can't happen, unless perhaps a map-maker screws up the waypoints
                // and creates unreachable nodes
                errorPrint("AStarNew(" + startWp + ", " + goalWp + ") on map " + getdvar("mapname") + " failed to find a path.");
                if (validateWaypoints) {return undefined;}
                return -1;
            }

            // grab up to 8 nodes to return as a stack
            pathStack = [];
            start = pathNodes.size - 8;     // return up to five nodes
            if (start < 0) {start = 0;}     // don't fall off the front of the array
            index = 0;
            for (i=start; i<pathNodes.size; i++) {
                pathStack[index] = pathNodes[i];
                index++;
            }

            if (validateWaypoints) {return closedList;}
            return pathStack;
        }

        //for each successor nc of n
        for (i=0; i<level.Wp[n.wpIdx].linkedCount; i++) {
            //newg = n.g + cost(n,nc)
            if (!isDefined(level.Wp[n.wpIdx].distance)) {
                // don't crash if the waypoints are bad so we didn't pre-compute distances
                newg = n.g + distance(level.Wp[n.wpIdx].origin, level.Wp[n.wpIdx].linked[i].origin);
            } else {
                newg = n.g + level.Wp[n.wpIdx].distance[i];
            }
            // if nc is in Open or Closed, and nc.g <= newg then skip this iteration
            ncFound = false;
            // if nc is in open list, grab a copy of it
            nc = spawnstruct();
            for (p=0; p<pQSize; p++) {
                if (pQOpen[p].wpIdx == level.Wp[n.wpIdx].linked[i].ID) {
                    nc = pQOpen[p];
                    ncFound = true;
                    break;
                }
            }
            if ((ncFound) && (nc.g <= newg)) {continue;}
            if (!ncFound) { // nc wasn't in the open list
                // if nc is in closed list, grab a copy of it
                ncFound = false;
                nc = spawnstruct();
                for (p=0; p<listSize; p++) {
                    if (closedList[p].wpIdx == level.Wp[n.wpIdx].linked[i].ID) {
                        nc = closedList[p];
                        ncFound = true;
                        break;
                    }
                }
                if ((ncFound) && (nc.g <= newg)) {continue;}
            }
//             nc.parent = n
//             nc.g = newg
//             nc.h = GoalDistEstimate( nc )
//             nc.f = nc.g + nc.h

            nc = spawnstruct();
            nc.parent = spawnstruct();
            nc.parent = n;
            nc.g = newg;
            nc.h = distance(level.Wp[level.Wp[n.wpIdx].linked[i].ID].origin, level.Wp[goalWp].origin);
            level.astarDistanceCalls++;
            nc.f = nc.g + nc.h;
            nc.wpIdx = level.Wp[n.wpIdx].linked[i].ID;

            // if nc is in Closed, remove it without changing the order of elements in Closed
            for (p=0; p<listSize; p++) {
                if (closedList[p].wpIdx == nc.wpIdx) {
                    // we found nc, so remove it without changing the order of closed
                    for (j=p; j<listSize - 1; j++) {
                        // shift elements greater than nc to the left
                        closedList[j] = closedList[j+1];
                    }
                    listSize--;
                    break;
                }
            }

            //if nc is not yet in Open,
            if (!PQExists(pQOpen, nc.wpIdx, pQSize)) {
                //push nc on Open
                pQOpen[pQSize] = spawnstruct();
                pQOpen[pQSize] = nc;
                pQSize++;
            }
        }

        //Done with children, push n onto Closed
        if (!ListExists(closedList, n.wpIdx, listSize)) {
            closedList[listSize] = spawnstruct();
            closedList[listSize] = n;
            listSize++;
        }
    }
    // we failed!
    if (validateWaypoints) {return undefined;}
}

/**
 * @brief Determines if an array is empty
 * @deprecated This is only used by the deprecated AStarOriginal(), which is only used for testing
 *
 * @param Q the array to inspect
 * @param QSize the size of the array
 *
 * @returns boolean indicating whether the array is empty or not
 */
PQIsEmpty(Q, QSize)
{
    /// Why are we passing in Q if we aren't using it?
    // 5th most-called function (5% of all function calls).
    // Do *not* put a function entrance debugPrint statement here!

    if (QSize <= 0) {return true;}

    return false;
}

/**
 * @brief Determines if an element is in an array
 *
 * @param Q the array to inspect
 * @param n the element to search for
 * @param QSize the size of the array
 *
 * @returns boolean indicating whether the element is in the array or not
 */
PQExists(Q, n, QSize)
{
    // 2nd most-called function (22% of all function calls).
    // Do *not* put a function entrance debugPrint statement here!

    for (i=0; i<QSize; i++) {
        if(Q[i].wpIdx == n) {return true;}
    }

    return false;
}

/**
 * @brief Determines if an element is in an array
 * N.B. This function is identical to PQExists(Q, n, QSize), but I'm leaving
 * it here for the AStarOriginal() function.
 *
 * @param list the array to inspect
 * @param n the element to search for
 * @param listSize the size of the array
 *
 * @returns boolean indicating whether the element is in the array or not
 */
ListExists(list, n, listSize)
{
    // 1st most-called function (26% of all function calls).
    // Do *not* put a function entrance debugPrint statement here!

    for (i=0; i<listSize; i++) {
        if (list[i].wpIdx == n) {return true;}
    }

    return false;
}

/**
 * @brief Finds the best path between two waypoints
 * @deprecated
 *
 * This was the original A* algorithm from Bipo/Pezbots.  It was terribly inefficient
 * and a complete waste of resources, so it was deprecated, and now, removed. Now it
 * forwards to AStarNew(), which is itself now on the chopping block.
 *
 * @param startWp integer The index of the waypoint to begin the path at
 * @param goalWp integer The index of the waypoint to where the path ends
 *
 * @returns integer The first waypoint in the path
 */
AStarOriginal(startWp, goalWp)
{
    pathStack = AStarNew(startWp, goalWp, false);
    return pathStack pop();
}
