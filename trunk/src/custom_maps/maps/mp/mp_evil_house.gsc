/******************************************************************************
 *    Extracted from mp_evil_house.ff.  Minimal changes to fix their precache()
 *    bugs. You *MUST* precacheModel(), etc, before any calls to 'wait'.
 ******************************************************************************/
#include maps\mp\_zombiescript;

main()
{
    level._effect[ "rain_heavy_mist" ] = loadfx( "weather/rain_mp_farm" );
    maps\mp\_fx::loopfx("rain_heavy_mist", (0.0, -944.0, 1250), 3);
    level._effect[ "lightning" ]   = loadfx( "weather/lightning_mp_farm" );   
    maps\mp\_fx::loopfx("lightning", (500.0, -1600.0, 1360), 10);

    maps\mp\_load::main();
    maps\mp\_explosive_barrels::main();
    // ambientPlay("ambient_backlot_ext");

    // game["allies"] = "sas";
    // game["axis"] = "opfor";
    // game["attackers"] = "axis";
    // game["defenders"] = "allies";
    // game["allies_soldiertype"] = "woodland";
    // game["axis_soldiertype"] = "woodland";

    // setdvar( "r_specularcolorscale", "1" );
    setdvar("r_glowbloomintensity0",".25");
    setdvar("r_glowbloomintensity1",".25");
    setdvar("r_glowskybleedintensity0",".3");
    // setdvar("compassmaxrange","1800");

    ambientPlay("amb_chech_nightscream2v3_lr");

    // maps\mp\_load::main();
    maps\mp\_compass::setupMiniMap("compass_map_mp_evil_house");

    game["allies"] = "marines";
    game["axis"] = "opfor";
    game["attackers"] = "allies";
    game["defenders"] = "axis";
    game["allies_soldiertype"] = "desert";
    game["axis_soldiertype"] = "desert";

    setdvar( "r_specularcolorscale", "1" );
    setdvar("compassmaxrange","2000");

    precache(); // Call precache *before* any 'wait' calls

    waittillStart();
    buildAmmoStock("ammostock");
    buildWeaponUpgrade("weaponupgrade");
    buildSurvSpawn("spawngroup1", 1);
    buildSurvSpawn("spawngroup2", 1);
    buildSurvSpawn("spawngroup3", 1);
    buildSurvSpawn("spawngroup4", 1);

    startSurvWaves();

    level.barricadefx = LoadFX("dust/dust_trail_IR");
    buildBarricade("staticbarricade", 4, 400, level.barricadefx, level.barricadefx);

    // precache(); // Call the precache function

    venders = getentarray("heal","targetname");// Get all the entitys that have "heal" for their "targetname"
    for(i=0;i<venders.size;i++)
        venders[i] thread vender();
}

precache()
{
    if(getDvar(getDvar("mp_evil_house") + "_allow_vender") == "")
        setDvar(getDvar("mp_evil_house") + "_allow_vender", 1);// This creates the dvar to enable the vending machines

    if(getDvar(getDvar("mp_evil_house") + "_health_wait") == "")
        setDvar(getDvar("mp_evil_house") + "_health_wait", 120);// This creates the dvar to set the time between being able to get health again

    level.allow_vender = int(getDvar(getDvar("mp_evil_house") + "_allow_vender"));
    level.vender_wait = int(getDvar(getDvar("mp_evil_house") + "_health_wait"));

    for(i=1;i<5;i++)
        precacheModel("com_bottle" + i);// Precache (load) the com_bottle1, com_bottle2, com_bottle3 and com_bottle4 models

    level.venderbottles = [];
    level.venderbottlescurrent = 0;
    level.venderbottlesmax = 24;// Max bottles in the map at one time, try not to have this too high as it can cause lag and somtimes crash the server
}

vender()
{
    self.targetname = undefined;
    dir = getent(self.target,"targetname");
    if(isDefined(dir))
    {
        temp = spawnStruct();
        temp.origin = dir.origin;
        temp.angles = dir.angles;// Spawn a struct which doesnt count as an entity, record the script_origin's origin and angles then delete the script_origin
        dir delete();
        dir = temp;
    }
    self.target = undefined;

    self playLoopSound("vender");// Make the trigger play a loop sound

    while(1)
    {
        self waittill("trigger", player);// Wait until its triggered
        if(player.sessionstate != "playing")// Make sure the player is playing
            continue;

       

        if(!level.allow_vender)// If vending machines are not allowed then say a message
        {
            player iPrintlnBold("^2Sorry, fat rats are not allowed on this server");
            continue;
        }

        if(isDefined(dir))// If the script_origin is placed correctly in the map, then make a bottle pop out
        {
            self playSound("vender_drop");// Play the bottle drop sound

            if(isDefined(level.venderbottles[level.venderbottlescurrent]))
                level.venderbottles[level.venderbottlescurrent] delete();// If we have gone over the limit for max bottle in the map, delete the oldest one

            level.venderbottles[level.venderbottlescurrent] = spawn("script_model",self.origin);// Spawn the bottle
            level.venderbottles[level.venderbottlescurrent].angles = dir.angles; // Set the angles of the bottle
            level.venderbottles[level.venderbottlescurrent] setModel("com_bottle" + (randomInt(4) + 1));    // Set random bottle model
            point = dir.origin;
            origin = level.venderbottles[level.venderbottlescurrent].origin + maps\mp\_utility::vector_Scale(anglestoup(level.venderbottles[level.venderbottlescurrent].angles),4 + randomFloat(1));
            velocity = VectorNormalize(origin - point);// Calculate velocity and direction of the impact
            velocity = maps\mp\_utility::vector_Scale(velocity,10000 + randomInt(5000));
            level.venderbottles[level.venderbottlescurrent] physicsLaunch(point, velocity);            // Make the bottle fly!

            level.venderbottlescurrent++;

            if(level.venderbottlescurrent >= level.venderbottlesmax)
                level.venderbottlescurrent = 0;
        }

        if(isDefined(player.healthwait))// If the player has already used the vending machine then...
        {
            num = randomInt(100);
            if(num < 20)
                player iPrintlnBold("^2When was the last time you saw a fat rat?");
            else if(num >= 20 && num < 40)
                player iPrintlnBold("^1Careful! You'll break it!");// Say one of these random messages
            else if(num >= 40 && num < 60)
                player iPrintlnBold("^3Oh no! There's none left!");
            else if(num >= 60 && num < 80)
                player iPrintlnBold("^4You're hungry ain't ya?");
            else
                player iPrintlnBold("^5Woof");
            continue;
        }

        player.healthwait = true;
        if(player.health < player.maxhealth)// If the players health is not at the max
        {
            player.health = player.maxhealth;// Set the players health to the max
            player iPrintlnBold("^2mmm... ^1y^2u^3m^4m^5y^6!");// Say these messages if the player was healed
            player iPrintlnBold("^1Health Restored!");
            player notify("damage");
        }
        else
            player iPrintlnBold("^2You already have full health, but ^1y^2u^3m^4m^5y^6! ^2anyway!");// If the player already has full health then say this message
        player thread healthwait();
    }
}

healthwait()
{
    self endon("disconnect");    // Kill the thread if the player disconnects
    wait level.vender_wait;        // Wait how long level.vender_wait is
    self.healthwait = undefined;    // Make self.healthwait undefined
    
} 
