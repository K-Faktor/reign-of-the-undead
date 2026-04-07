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
 * @brief Creates a new integer stack
 *
 * @returns struct A new int_stack with capacity=10 and count=0
 */
new()
{
    stack = spawnStruct();
    stack.data = [];
    stack.count = 0;
    stack.capacity = 10;
    stack.type = "int_stack";
    return stack;
}

/**
 * @brief Pushes a single integer onto the stack
 *
 * @param value int The value to push
 *
 * Automatically expands capacity by 10 when needed.
 *
 * @returns nothing (modifies stack.data and stack.count)
 */
push(value)
{
    if (!isDefined(self.count)) { self.count = 0; }
    if (!isDefined(self.capacity)) { self.capacity = 10; }
    if (!isDefined(self.data)) { self.data = []; }

    if (self.count >= self.capacity) {
        self.capacity += 10;
    }

    self.data[self.count] = value;
    self.count++;
}

/**
 * @brief Pushes multiple integers onto the stack from an array
 *
 * @param values int[] Array of values to push
 *
 * @returns nothing
 */
pushMany(values)
{
    for (i = 0; i < values.size; i++) {
        self push(values[i]);
    }
}

/**
 * @brief Pops and returns the top value from the stack
 *
 * @returns int The top value, or undefined if stack is empty
 */
pop()
{
    if (!isDefined(self.count) || self.count <= 0) {
        return undefined;
    }

    self.count--;
    value = self.data[self.count];
    self.data[self.count] = undefined;
    return value;
}

/**
 * @brief Returns the top value without removing it
 *
 * @returns int The top value, or undefined if stack is empty
 */
peek()
{
    if (!isDefined(self.count) || self.count <= 0) {
        return undefined;
    }

    return self.data[self.count - 1];
}

/**
 * @brief Returns the bottom value without removing it
 *
 * @returns int The bottom value, or undefined if stack is empty
 */
peekBottom()
{
    if (!isDefined(self.count) || self.count <= 0) {
        return undefined;
    }

    return self.data[0];
}

/**
 * @brief Returns the number of elements in the stack
 *
 * @returns int The number of elements
 */
size()
{
    if (!isDefined(self.count)) {
        return 0;
    }
    return self.count;
}

/**
 * @brief Returns whether the stack is empty or not
 *
 * @returns bool Is the stack empty
 */
isEmpty()
{
    if (!isDefined(self.count)) {
        return true;
    }
    if (self.count == 0) {return true;}
    return false;
}

/**
 * @brief Removes all elements from the stack
 *
 * @returns nothing
 */
empty()
{
    self.count = 0;
    self.data = [];
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
ensureCapacity(requestedCapacity)
{
    if (!isDefined(self.capacity)) {
        self.capacity = 10;
    }

    while (self.capacity < requestedCapacity) {
        self.capacity += 10;
    }
}

/**
 * @brief Prints the stack as a formatted integer list on one line
 *
 * @param prefix (optional) String to prepend to the output line
 *
 * Examples:
 *   stack print();                    → "int_stack: [1, 2, 3]"
 *   stack print("Path:");             → "Path: [1, 2, 3]"
 *   stack print("Current path:");     → "Current path: [1, 2, 3]"
 *
 * @returns nothing
 */
print(prefix)
{
    // Default prefix if none provided
    if (!isDefined(prefix) || prefix == "")
        prefix = "int_stack";

    if (!isDefined(self.count) || self.count <= 0) {
        noticePrint(prefix + ": []");
        return;
    }

    output = prefix + ": [";

    for (i = 0; i < self.count; i++) {
        if (i > 0) {
            output += ", ";
        }
        output += self.data[i];
    }

    output += "]";
    noticePrint(output);
}