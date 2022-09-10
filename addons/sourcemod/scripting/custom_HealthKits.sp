// List of Includes
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

// The code formatting rules we wish to follow
#pragma semicolon 1;
#pragma newdecls required;


// The retrievable information about the plugin itself 
public Plugin myinfo =
{
	name		= "[CS:GO] Health Kits",
	author		= "Manifest @Road To Glory",
	description	= "Players have a chance to drop a health kit upon their death.",
	version		= "V. 1.0.0 [Beta]",
	url			= ""
};


//////////////////////////
// - Global Variables - //
//////////////////////////

ConVar Cvar_DropChance;
ConVar Cvar_HealthMinimum;
ConVar Cvar_HealthMaximum;
ConVar Cvar_HealthCap;


//////////////////////////
// - Forwards & Hooks - //
//////////////////////////


// This happens when the plugin is loaded
public void OnPluginStart()
{
	// Hooks the events which we intend to use
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);

	// Creates the convars which we intend for the server owner to be able to configure
	Cvar_DropChance = 					CreateConVar("HealthKit_DropChance", 		"100", 		"What is the chance in percentages for a dead player to drop a health kit? - [Default = 100]");
	Cvar_HealthMinimum = 				CreateConVar("HealthKit_HealthMinimum", 	"25", 		"How much health should the player as a minimum receive from picking up a health kit? - [Default = 25]");
	Cvar_HealthMaximum = 				CreateConVar("HealthKit_HealthMaximum", 	"50", 		"How much health should the player as a maximum receive from picking up a health kit? - [Default = 50]");
	Cvar_HealthCap = 					CreateConVar("HealthKit_Weapon_Shield", 	"100", 		"How much health should the player have before being unable to pick up a health kit? - [Default = 100]");


	// Adds files to the download list, and precaches them
	DownloadAndPrecacheFiles();
}


// This happens when a new map is loaded
public void OnMapStart()
{
	// Adds files to the download list, and precaches them
	DownloadAndPrecacheFiles();
}


// This happens when a player first touches a dropped health kit prop
public void Hook_OnStartTouch(int entity, int other)
{
	// If the entity does not meet our validation criteria then execute this section
	if(!IsValidEntity(entity))
	{
		return;
	}

	// If the client does not meet our validation criteria then execute this section
	if(!IsValidClient(other))
	{
		return;
	}

	// If the client is a bot then execute this section
	if(IsFakeClient(other))
	{
		return;
	}

	// Creates a variable which we will store our message within called message_string
	char message_string[1024];

	// Obtains the player's health and store it within the PlayerHealth variable
	int PlayerHealth = GetClientHealth(other);

	// Obtains the convar's value and store it within our variable
	int HealthMinimum = GetConVarInt(Cvar_HealthMinimum);
	int HealthMaximum = GetConVarInt(Cvar_HealthMaximum);
	int HealthCap = GetConVarInt(Cvar_HealthCap);

	// Picks a random number between 25 to 50 (Default)
	int RandomHealth = GetRandomInt(HealthMinimum, HealthMaximum);

	// If the player's health is below HealthCap then execute this section
	if(PlayerHealth < HealthCap)
	{
		// If the player's health plus RandomHealth is higher than HealthCap then execute this section
		if(PlayerHealth + RandomHealth > HealthCap)
		{
			// Changes the clients health to HealthCap
			SetEntityHealth(other, HealthCap);
		}

		// If the player's health plus RandomHealth is higher than HealthCap then execute this section
		else
		{
			// Changes the client's health to the player's current health plus the RandomHealth value
			SetEntityHealth(other, PlayerHealth + RandomHealth);
		}

		// Formats the message that we wish to send to the player and store it within our message_string variable
		Format(message_string, 1024, "%s\n<font color='#ff8000'>Medic Kit:</font>", message_string);
		Format(message_string, 1024, "%s\n<font color='#FFFFFF'>You received %i health.</font>", message_string, RandomHealth);

		// Sends the message_string message to the client
		PrintHintText(other, message_string);

		// Plays a sound only the specified client can hear
		PlaySoundForClient(other, "items/healthshot_success_01.wav");

		// Kills the entity and thereby removing it from the game
		AcceptEntityInput(entity, "Kill");
	}
}



////////////////
// - Events - //
////////////////


// This happens when a player dies
public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	// Obtains the client's userid and converts it to an index and store it within our client variable
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	// If the client does not meet our validation criteria then execute this section
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	// Obtains the client's userid and converts it to an index and store it within our client variable
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	// If the client does not meet our validation criteria then execute this section
	if(!IsValidClient(attacker))
	{
		return Plugin_Continue;
	}

	// If the attacker is also the same person as the client then execute this section
	if(attacker == client)
	{
		return Plugin_Continue;
	}

	// Obtains the convar's value and store it within our variable
	int DropChance = GetConVarInt(Cvar_DropChance);

	// If the MedKitChance is larger than chosen random number then execute this section
	if(GetRandomInt(0, 100) <= DropChance)
	{
		// Spawns a medic kit on the ground
		SpawnHealthKit(client);
	}

	return Plugin_Continue;
}



///////////////////////////
// - Regular Functions - //
///////////////////////////


public Action SpawnHealthKit(int client)
{
	// Creates a prop and assigns it to an entity index stored within entity
	int entity = CreateEntityByName("prop_physics_multiplayer");

	// If the entity does not meet our validation criteria then execute this section
	if(!IsValidEntity(entity))
	{
		return Plugin_Continue;
	}

	// Creates a variable called PlayerLocation which we will use to store data within
	float PlayerLocation[3];

	// Obtains the player's current location and store it within our PlayerLocation variable
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", PlayerLocation);

	// Check if the model we intend to use is already precached, if not then execute this section
	if(!IsModelPrecached("models/items/healthkit.mdl"))
	{
		// Precache the model we intend to use
		PrecacheModel("models/items/healthkit.mdl");
	}

	// Changes the model of the prop
	SetEntityModel(entity, "models/items/healthkit.mdl");

	// Disables the receiving shadows for the prop
	DispatchKeyValue(entity, "disablereceiveshadows", "1");

	// Disables the shadows which the model would make
	DispatchKeyValue(entity, "disableshadows", "1");

	// Changes the physics mode used to be a server-side physics entity making it perceived as a non-solid entity
	DispatchKeyValue(entity, "physicsmode", "2");

	// Renders the prop unsolid
	DispatchKeyValue(entity, "solid", "0");

	// Spawns the prop in to the world
	DispatchSpawn(entity);

	// Changes the props collisiongroup
	SetEntProp(entity, Prop_Send, "m_CollisionGroup", 11);

	// Sets the props solid flags
	SetEntProp(entity, Prop_Send, "m_usSolidFlags", 8); 

	// Teleports the prop to the location where the player died
	TeleportEntity(entity, PlayerLocation, NULL_VECTOR, NULL_VECTOR);

	// Adds a hook to detect when someone first touches the spawned prop
	SDKHook(entity, SDKHook_StartTouchPost, Hook_OnStartTouch);

	// After 12 seconds remove the prop
	CreateTimer(12.0, Timer_RemoveHealthKit, entity, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}


// This happens when a knife king is killed
public void PlaySoundForClient(int client, const char[] SoundName)
{
	// If the sound is not already precached then execute this section
	if(!IsSoundPrecached(SoundName))
	{	
		// Precaches the sound file
		PrecacheSound(SoundName, true);
	}

	// Creates a variable called FullSoundName which we will use to store the sound's full name path within
	char FullSoundName[256];

	// Formats a message which we intend to use as a client command
 	Format(FullSoundName, sizeof(FullSoundName), "play */%s", SoundName);

	// Performs a clientcommand to play a sound only the clint can hear
	ClientCommand(client, FullSoundName);
}


// This happen when the plugin is loaded and when a new map starts
public void DownloadAndPrecacheFiles()
{
	// Adds the model related files to the download table
	AddFileToDownloadsTable("models/items/healthkit.dx80.vtx");
	AddFileToDownloadsTable("models/items/healthkit.dx90.vtx");
	AddFileToDownloadsTable("models/items/healthkit.mdl");
	AddFileToDownloadsTable("models/items/healthkit.phy");
	AddFileToDownloadsTable("models/items/healthkit.sw.vtx");
	AddFileToDownloadsTable("models/items/healthkit.vvd");
	AddFileToDownloadsTable("materials/models/items/healthkit01.vtf");
	AddFileToDownloadsTable("materials/models/items/healthkit01.vmt");
	AddFileToDownloadsTable("materials/models/items/healthkit01_mask.vtf");

	// Precaches the model which we intend to use
	PrecacheModel("models/items/healthkit.mdl", true);

	// Precaches the sound which we intend to use
	PrecacheSound("items/healthshot_success_01.wav", true);
}



///////////////////////////////
// - Timer Based Functions - //
///////////////////////////////


// This happens 12 after a health kit has been spawned
public Action Timer_RemoveHealthKit(Handle Timer, int entity)
{
	// If the entity does not meet our validation criteria then execute this section
	if(!IsValidEntity(entity))
	{
		return Plugin_Continue;
	}

	// Kills the entity and thereby removing it from the game
	AcceptEntityInput(entity, "Kill");

	return Plugin_Continue;
}



////////////////////////////////
// - Return Based Functions - //
////////////////////////////////


// Returns true if the client meets the validation criteria. elsewise returns false
public bool IsValidClient(int client)
{
	if (!(1 <= client <= MaxClients) || !IsClientConnected(client) || !IsClientInGame(client) || IsClientSourceTV(client) || IsClientReplay(client))
	{
		return false;
	}

	return true;
}
