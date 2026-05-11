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

#include scripts\include\stack;
#include scripts\include\utility;

/**
 * Initializes custom bot naming system.
 *
 * NOTE: Bot names are read-only properties on CoD4 1.7 stock. While this code will
 *       generate/proccess bot names, and *try* to set them, they will be silently
 *       ignored by CoD4 1.7 stock.  Untested, but I'm told it will work on COD4X,
 *       so I've implemented this code to do that.
 */
init()
{
    if (isDefined(level.botNameStack)) {return;}

    level.botClanTagsSep = [];
    level.botClans = [];

    level.useBotClanName = getdvar("bot_use_clan_name");    // [0|1]
    if (level.useBotClanName == "") {level.useBotClanName = true;}
    else if (level.useBotClanName == 0) {level.useBotClanName = false;}
    else if (level.useBotClanName == 1) {level.useBotClanName = true;}

    // [elements|presidents|protagonists|punny], or a complete comma-separated list of bot names
    level.botNameSet = getdvar("bot_nameset");

    // [random|sequential]
    level.botNameOrder = getdvar("bot_name_order");
    if (level.botNameOrder == "") {level.botNameOrder = "random";}

    level.botNameStack = stNew();       // the final stack we will pop names from as needed

    buildClanTagSeparators();
    buildClans();
    loadNameSet();
}


/**
 * @brief Builds clans with randomized clan tag separators
 *
 * @returns nothing
 */
buildClans()
{
    data = "Braindead Bastards,BDB;Walker Stalkers,WSK;Rotting Renegades,RTR;Bite Club,BTC;Undead Uprising,UU;No Brains Left,NBL;Last Breath Legion,LBL;Infected Elite,IE;Deadhead Division,DHD";

    items = strTok(data, ";");
    for (i=0; i<items.size; i++) {
        temp = strTok(items[i], ",");
        clan = spawnstruct();
        clan.name = temp[0];
        num = randomInt(level.botClanTagsSep.size);
        clan.tag = level.botClanTagsSep[num].pre + temp[1] + level.botClanTagsSep[num].app;
        level.botClans[level.botClans.size] = clan;
    }
}


/**
 * @brief Builds clans clan tag separators, i.e. the special character used to 'quote' the clan tag
 *
 * @returns nothing
 */
buildClanTagSeparators()
{
    data = "|,|;-,-;=,=;_,_;[,];{,};";

    items = strTok(data, ";");
    for (i=0; i<items.size; i++) {
        temp = strTok(items[i], ",");
        sep = spawnstruct();
        sep.pre = temp[0];
        sep.app = temp[1];
        level.botClanTagsSep[level.botClanTagsSep.size] = sep;
    }
}


/**
 * @brief Loads the selected, or custom bot nameset
 *
 * @returns nothing
 */
loadNameSet()
{
    elements = "Hydrogen,Helium,Lithium,Beryllium,Boron,Carbon,Nitrogen,Oxygen,Fluorine,Neon,Sodium,Magnesium,Aluminum,Silicon,Phosphorus,Sulfur,Chlorine,Argon,Potassium,Calcium,Scandium,Titanium,Vanadium,Chromium,Manganese,Iron,Cobalt,Nickel,Copper,Zinc";
    presidents = "Washington,Adams,Jefferson,Madison,Monroe,Adams,Jackson,Van Buren,Harrison,Tyler,Polk,Taylor,Fillmore,Pierce,Buchanan,Lincoln,Johnson,Grant,Hayes,Garfield,Arthur,Cleveland,Harrison,McKinley,Taft,Wilson,Harding,Coolidge,Hoover,Roosevelt";
    protagonists = "Rick Grimes,Daryl Dixon,Michonne,Carol Peletier,Morgan Jones,Joel Miller,Ellie Williams,Shaun Riley,Columbus,Tallahassee,Wichita,Jim,Selena,Frank,Alice Abernathy,Leon S. Kennedy,Jill Valentine,Claire Redfield,Gerry Lane,Robert Neville,Ben,Peter,Ana Clark,Kenneth Hall,Ash Williams,Roberta Warren,Madison Clark,Clementine,Lee Everett,Bill Overbeck";
    punny = "Z0MB13K1NG,Br41nD34d,N0Br41nz,R0TT1NGR1CK,Sh4mbl3r,Cr4n1umCr4v3r,D34dH34d,B1t3M3,L1mbl0ss,Gr4v3D1gg3r,KarenTh3Z0mb13,L4gG1ngD34d,Spr1nt3rZ0mb13,B4rN3yTh3Z0mb13,M1cr0W4v3d,Tw1tchTh3D34d,H3r3Com3sTh3Br41n,D34dByD4wn,Z0mb13J0hn,Puls4rZ0mb13,1337GhouL,H34dSh0tH0rD3,B4ckFr0mTh3Gr4v3,D3c4y1ngD4n,M34tB4g,Z0mb13F00d,R3dRumR3dRum,B1gB1t3,LurchL0rd,Inf3ct3dPr1nc3";

    if (level.botNameSet == "") {level.botNameSet = "punny";}
    switch(level.botNameSet) {
        case "elements":
            buildBotNameStack(elements);
        break;
        case "presidents":
            buildBotNameStack(presidents);
        break;
        case "protagonists":
            buildBotNameStack(protagonists);
        break;
        case "punny":
            buildBotNameStack(punny);
        break;
        default:
            // user spec'd a complete comma-separated nameset
            buildBotNameStack(level.botNameSet);
        break;        
    }
}


/**
 * @brief Builds bot name stack we will use to name the bots
 *
 * @returns nothing
 */
buildBotNameStack(nameset)
{
    items = strTok(nameset, ",");
    // for (i=0; i<items.size; i++) {
    limit = 50;
    count = 0;
    while (items.size > 0) {
        if (count > limit) {break;}
        name = "";
        temp = "";
        if (level.botNameOrder == "random") {
            // randomly pop from the array
            num = randomInt(items.size);
            temp = items[num];                  // save
            items[num] = items[items.size-1];   // swap
            items[items.size-1] = undefined;    // shrink
        } else if (level.botNameOrder == "sequential") {
            // pop from end of items, so that in final stack,
            // first item of items will be at top of stack
            temp = items[items.size-1];         // save
            items[items.size-1] = undefined;    // shrink
        }
        if (level.useBotClanName) {
            // randomly pick a clan for the bot
            r = randomInt(level.botClans.size);
            tag = level.botClans[r].tag;
            name = tag + " " + temp;
        } else {
            name = temp;
        }
        logPrint("Bot name: " + name + "\n");  // can't json log(), as name may have pipes '|'
        level.botNameStack stPush(name);
        count++;
    }
}


/**
 * @brief Gets a friendly bot name. ***COD4X Only***
 *
 * Inspired by Fluffy Man from -nVts- 
 *
 * If this truly works, will:
 *   - implement several bot name-sets, and
 *   - allow custom name-sets, and
 *   - allow sequential pop'ing of names vs random pop'ing of names
 *
 * @returns string a bot name
 */
getBotName() {
    return level.botNameStack stPop();
}
