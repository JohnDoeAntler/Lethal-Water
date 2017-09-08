#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "hoursplayed.net"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>

new Handle:wd_Damage = INVALID_HANDLE;
new Handle:wd_Time = INVALID_HANDLE;
new Handle:wd_Class = INVALID_HANDLE;

new bool:Array[MAXPLAYERS + 1];

public Plugin:myinfo = 
{
	name = "Lethal Water",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = "http://hoursplayed.net"
};

public void OnPluginStart()
{
	wd_Damage = CreateConVar("sm_wd", "15", "The damage amount of touching water.");
	wd_Time = CreateConVar("sm_wdt", "1.0", "The interval between each damage.");
	wd_Class = CreateConVar("sm_wdc", "sniper", "The only class will be damaged by touching water.");
}

public OnMapStart()
{
	CreateTimer(1.0, OnTimerStart, _, TIMER_REPEAT);
}

public Action:OnTimerStart(Handle timer)
{
	for (new i = 1; i < MaxClients; i++)
	{
		if(i != 0 && IsClientInGame(i))
		{
			new String:sClass[32];
			GetConVarString(wd_Class, sClass, sizeof(sClass));
			
			if(TF2_GetClass(sClass) == TF2_GetPlayerClass(i))
			{
				new iType;
				iType = GetEntProp(i, Prop_Data, "m_nWaterLevel"); 
				if(iType > 1)
				{
					if(Array[i])
						return Plugin_Handled;
					if(!IsPlayerAlive(i))
						return Plugin_Handled;
						
					CreateTimer(0.1, OnDetectedPlayer, i);
					Array[i] = true;
				}
			}
		}
	}	
	return Plugin_Continue;
}

public Action:OnDetectedPlayer(Handle timer, int client)
{
	new String:sClass[32];
	GetConVarString(wd_Class, sClass, sizeof(sClass));
	
	if(TF2_GetClass(sClass) != TF2_GetPlayerClass(client))
	{
		Array[client] = false;
		return Plugin_Continue;
	}
	
	new health, String:sDamage[32], iDamage;
	health = GetClientHealth(client);
	
	GetConVarString(wd_Damage, sDamage, sizeof(sDamage));
	
	iDamage = StringToInt(sDamage);
	health = health - iDamage;
	
	SetEntityHealth(client, health);
	
	if(health <= 0)
	{
		ForcePlayerSuicide(client);
	}
	
	PrintToChatAll("%s", sDamage);
	
	
	if(!IsPlayerAlive(client))
	{
		Array[client] = false;
		return Plugin_Continue;
	}
	
	new iType;
	iType = GetEntProp(client, Prop_Data, "m_nWaterLevel"); 
	if(iType > 1)
	{
		new float:fTime;
		fTime = GetConVarFloat(wd_Time);
		CreateTimer(fTime, OnDetectedPlayer, client);
	}else if(iType <= 1)
	{
		Array[client] = false;
	}
	return Plugin_Continue;
}