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
#include scripts\include\utility;

/**
 * @brief Creates a new priority queue
 *
 * @returns struct A new priority queue with capacity=10 and count=0
 */
pqNew(name)
{
    queue = spawnStruct();
    queue.name = name;      // use variable name; for debugging
    queue.data = [];
    queue.count = 0;
    queue.capacity = 10;
    queue.type = "priority_queue";
    return queue;
}

/**
 * @brief Enqueues a single item into the queue, by priority
 *
 * @param item object The item to enqueue
 * @param priority numeric the priority of the item
 *
 * Automatically expands capacity by 10 when needed.
 *
 * @returns nothing (modifies queue.data and queue.count)
 */
pqInsert(item, priority)
{
    // if (self.name == "openF") {
    //     logPrint("Inserting item.wpIdx: " + item.wpIdx + " priority: " + priority + "\n");
    // }

    // find insertion point (lowest f first)
    insertIdx = self.data.size;     // default: append
    // if (self.name == "openF") {
    //     log("dev", sprintfLog("msg|pq pre-insert||name|$2||size|$1||", self.data.size, self.name));
    // }
    for (i=0; i<self.data.size; i++) {
        // if (self.name == "openF") {
        //     log("dev", sprintfLog("msg|(i=0; i<$1; i++)", self.data.size));
        // }
        if (self.data[i].priority > priority) {   // found spot for smaller priority
            insertIdx = i;
            break;
        }
    }

    // shift everything right to make room
    for (j=self.data.size; j>insertIdx; j--) {
        self.data[j] = self.data[j-1];
    }

    self.data[insertIdx] = item;
    self.data[insertIdx].priority = priority;
    if ((self.name == "openF") || (self.name == "openB") || (self.name == "closedF") || (self.name == "closedB")) {
        // log("dev", sprintfLog("msg|pq post-insert||name|$2||size|$1||", self.data.size, self.name));
        logPrint(self.name + ": Inserted: " + priority + "\n");
        // self pqPrintPriority();
        self pqPrintWaypoints();
    }
}
pqSize()
{
    return self.data.size;
}

pqPop()
{
    if (!isDefined(self.capacity)) { self.capacity = 10; }
    if (!isDefined(self.data)) { self.data = []; }

    item = self.data[0];
    for (i=1; i<self.data.size; i++) {
        self.data[i-1] = self.data[i]; // shift anything remaining to the left
    }
    self.data[self.data.size-1] =  undefined;
    if ((self.name == "openF") || (self.name == "openB") || (self.name == "closedF") || (self.name == "closedB")) {
        // log("dev", sprintfLog("msg|pop()'d item||name|$2||size|$1||", self.data.size, self.name));
        logPrint(self.name + ": Pop'd: " + item.priority + "\n");
        // self pqPrintPriority();
        self pqPrintWaypoints();
    }

    return item;
}

// is the waypoint ID in the queue?
pqWaypointExists(wp) 
{
    for (i=0; i<self.data.size; i++) {
        if (self.data[i].wpIdx == wp) {return true;}
    }
    return false;
}

pqRemoveByWaypoint(wp) 
{
    for (i=0; i<self.data.size; i++) {
        if (self.data[i].wpIdx == wp) {
            for (j=i; j<self.data.size-1; j++) {
                self.data[j] = self.data[j+1]; // shift left
            }
            self.data[self.data.size - 1] = undefined;
            return;
        }
    }
}

pqToReversedArray()
{
    result = [];
    for (i=self.data.size-1; i>=0; i--) {
        result[result.size] = self.data[i];
    }
    return result;
}

// get the node associated with the wp ID
pqGetNodeByWaypoint(wp) 
{
    for (i=0; i<self.data.size; i++) {
        if (self.data[i].wpIdx == wp) {return self.data[i];}
    }
    return undefined;
}

pqPrintPriority()
{
    buf = self.name + ": [ ";
    for (i=0; i<self.data.size; i++) {
        buf += "" + self.data[i].priority + ", ";
    }
    buf += "]\n";
    logPrint(buf);
}

pqPrintWaypoints()
{
    buf = self.name + ": [ ";
    for (i=0; i<self.data.size; i++) {
        buf += "" + self.data[i].wpIdx + ", ";
    }
    buf += "]\n";
    logPrint(buf);
}


/**
 * @brief Ensures the stack has at least the requested capacity
 *
 * @param requestedCapacity int The minimum desired capacity
 *
 * If current capacity is less than requested, expands by adding
 * increments of 10 until capacity is sufficient.
 *
 * @returns nothing
 */
pqEnsureCapacity(requestedCapacity)
{
    if (!isDefined(self.capacity)) {
        self.capacity = 10;
    }
    if (!isDefined(requestedCapacity)) {
        self.capacity = self.capacity + 10;
        return;
    }
    self.capacity = requestedCapacity;
}
