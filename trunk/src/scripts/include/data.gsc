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
 * @brief Converts a string representation of a float to a numeric float
 *
 * @param value string The string to convert
 *
 * @returns float the converted value
 */
atof(value)
{
    log("trace", "msg|in data::atof()||");

    setdvar("2float", value);
    return getdvarfloat("2float");
}


/**
 * @brief Converts a string representation of an integer to a numeric integer
 *
 * @param value string The string to convert
 *
 * @returns integer the converted value
 */
atoi(value)
{
    log("trace", "msg|in data::atoi()||");

    setdvar("2int", value);
    return getdvarint("2int");
}


/**
 * @brief Removes an item from an array without changing the order
 *
 * @param list array The array to remove the item from
 * @param item variable The data item to remove
 *
 * @returns array The array with the item removed
 */
removeFromArray(list, item)
{
    log("trace", "msg|in data::removeFromArray()||");

    for (i=0; i<list.size; i++) {
        if (list[i] == item) {
            for (; i<list.size - 1; i++) {
                list[i] = list[i+1];
            }
            list[list.size-1] = undefined;
            return list;
        }
    }
    return list;
}


/**
 * @brief Splits a string on whitespace, greedily collapsing whitespace
 *
 * @param value string The string to tokenize
 *
 * @returns array The array of parsed tokens
 */
dissect(value)
{
    log("trace", "msg|in data::dissect()||");

    ret = [];
    index = -1;
    skip = 1;
    for (i=0; i<value.size; i++) {
        if (value[i] == " ") {
            skip = 1;
            continue;
        } else {
            if (skip) {
                index++;
                skip = 0;
                ret[index] = "";
            }
            ret[index] += value[i];
        }
    }
    return ret;
}
