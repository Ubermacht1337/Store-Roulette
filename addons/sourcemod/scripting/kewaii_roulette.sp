#pragma semicolon 1
#include <csgocolors>
#include <store>
#pragma newdecls required

int ScrollTimes[MAXPLAYERS + 1];
int WinNumber[MAXPLAYERS + 1];
int betAmount[MAXPLAYERS + 1];
bool isSpinning[MAXPLAYERS + 1] = false;


ConVar g_Cvar_NormalItems;
ConVar g_Cvar_VIPItems;
ConVar g_Cvar_VIPFlag;

char g_sNormalItems[64];
char g_sVIPItems[64];
#define PLUGIN_NAME "Store Roulette by Kewaii"
#define PLUGIN_AUTHOR "Kewaii"
#define PLUGIN_DESCRIPTION "Zephyrus Store Roulette"
#define PLUGIN_VERSION "1.3.9"
#define PLUGIN_TAG "{pink}[Roulette by Kewaii]{green}"

public Plugin myinfo =
{
    name        =    PLUGIN_NAME,
    author        =    PLUGIN_AUTHOR,
    description    =    PLUGIN_DESCRIPTION,
    version        =    PLUGIN_VERSION,
    url            =    "http://steamcommunity.com/id/KewaiiGamer"
};

public void OnPluginStart()
{	
	g_Cvar_VIPFlag = CreateConVar("kewaii_roulette_vip_flag", "a", "VIP Access Flag");
	g_Cvar_NormalItems = CreateConVar("kewaii_roulette_normal_items", "50,100,250,500", "Lists all the menu items for normal player roulette. Separate each item with a comma. Only integers allowed");
	g_Cvar_VIPItems = CreateConVar("kewaii_roulette_vip_items", "1000,2500,5000,10000", "Lists all the menu items for VIP player roulette. Separate each item with a comma. Only integers allowed");
	RegConsoleCmd("sm_roleta", CommandRoulette);
	RegConsoleCmd("sm_roulette", CommandRoulette);
	LoadTranslations("kewaii_roulette.phrases");
	AutoExecConfig(true, "kewaii_roulette");
}

public void OnClientPostAdminCheck(int client)
{
	isSpinning[client] = false;
}

public Action CommandRoulette(int client, int args)
{
	if (client > 0 && args < 1)
	{		
		CreateRouletteMenu(client).Display(client, 10);	
	}
	return Plugin_Handled;
}

Menu CreateRouletteMenu(int client)
{
	Menu menu = new Menu(RouletteMenuHandler);
	char buffer[128];
	Format(buffer, sizeof(buffer), "%T", "ChooseType", client);
	menu.SetTitle(buffer);	
	menu.AddItem("player", "Player");
	menu.AddItem("vip", "VIP", !HasClientVIP(client) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);		
	return menu;
}

public int RouletteMenuHandler(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(IsClientInGame(client))
			{
				char option[32];
				menu.GetItem(selection, option, sizeof(option));
				if (StrEqual(option, "player"))
				{
					CreatePlayerRouletteMenu(client).Display(client, MENU_TIME_FOREVER);
				}
				if (StrEqual(option, "vip"))
				{
					CreateVIPRouletteMenu(client).Display(client, MENU_TIME_FOREVER);
				}
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}


Menu CreatePlayerRouletteMenu(int client)
{
	Menu menu = new Menu(CreditsChosenMenuHandler);
	char buffer[128];
	Format(buffer, sizeof(buffer), "%T", "ChooseCredits", client, Store_GetClientCredits(client));
	menu.SetTitle(buffer);	
	GetConVarString(g_Cvar_NormalItems, g_sNormalItems, sizeof(g_sNormalItems));
	char sItems[18][16];
	ExplodeString(g_sNormalItems, ",", sItems, sizeof(sItems), sizeof(sItems[]));
	for (int i = 0; i < sizeof(sItems); i++) {
		if (!StrEqual(sItems[i], "")) {
			menu.AddItem(sItems[i], sItems[i], Store_GetClientCredits(client) >= StringToInt(sItems[i]) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);	
		}
	}
	menu.ExitBackButton = true;
	return menu;
}


Menu CreateVIPRouletteMenu(int client)
{
	Menu menu = new Menu(CreditsChosenMenuHandler);
	char buffer[128];		
	Format(buffer, sizeof(buffer), "%T", "ChooseCredits", client, Store_GetClientCredits(client));
	menu.SetTitle(buffer);	
	GetConVarString(g_Cvar_VIPItems, g_sVIPItems, sizeof(g_sVIPItems));
	char sItems[18][16];
	ExplodeString(g_sVIPItems, ",", sItems, sizeof(sItems), sizeof(sItems[]));
	for (int i = 0; i < sizeof(sItems); i++) {
		if (!StrEqual(sItems[i], "")) {
			menu.AddItem(sItems[i], sItems[i], Store_GetClientCredits(client) >= StringToInt(sItems[i]) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);	
		}
	}
	menu.ExitBackButton = true;
	return menu;
}

public int CreditsChosenMenuHandler(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(IsClientInGame(client))
			{
				char option[32];
				menu.GetItem(selection, option, sizeof(option));
								
				int crd = Store_GetClientCredits(client);
				int bet = StringToInt(option);
				if(crd >= bet)
				{
					if (!isSpinning[client])
					{
						Store_SetClientCredits(client, crd - bet);
						betAmount[client] = bet;
						SpinCredits(client);
						isSpinning[client] = true;
					}
					else
					{
						CPrintToChat(client, "%s %t", PLUGIN_TAG, "AlreadySpinning");
					}
				} 
				else
				{
					CPrintToChat(client, "%s %t", PLUGIN_TAG,  "NoEnoughCredits", bet - crd);
				}
			}
		}
		case MenuAction_Cancel:
		{
			if (IsClientInGame(client) && selection == MenuCancel_ExitBack)
			{
				CreateRouletteMenu(client).Display(client, 10);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public void SpinCredits(int client)
{
	int	FakeNumber = GetRandomInt(0,999);
	PrintHintText(client, "<font color='#ff0000'>[Credits Roulette]</font><font color='#00ff00'> Number:</font><font color='#0000ff'> %i", FakeNumber);
	if(ScrollTimes[client] == 0)
	{
		ClientCommand(client, "playgamesound *ui/csgo_ui_crate_open.wav");
	}
	if(ScrollTimes[client] < 20)
	{
		CreateTimer(0.05, TimerNext, client);
		ScrollTimes[client] += 1;
		ClientCommand(client, "playgamesound *ui/csgo_ui_crate_item_scroll.wav");
	} 
	else if(ScrollTimes[client] < 30)
	{
		float AddSomeTime = 0.05 * ScrollTimes[client] / 3;
		CreateTimer(AddSomeTime, TimerNext, client);
		ScrollTimes[client] += 1;
		ClientCommand(client, "playgamesound *ui/csgo_ui_crate_item_scroll.wav");
	}
	else if(ScrollTimes[client] == 30)
	{
		int troll = GetRandomInt(1,2);
		if(troll == 1)
		{
			ClientCommand(client, "playgamesound *ui/csgo_ui_crate_item_scroll.wav");
			ScrollTimes[client] += 1;
			CreateTimer(1.5, TimerNext, client);
		}
		else
		{
			ClientCommand(client, "playgamesound *ui/csgo_ui_crate_item_scroll.wav");
			CreateTimer(1.5, TimerFinishing, client);
			WinNumber[client] = FakeNumber;
			ScrollTimes[client] = 0;
		}
	} 
	else
	{
		ClientCommand(client, "playgamesound *ui/csgo_ui_crate_item_scroll.wav");
		CreateTimer(1.5, TimerFinishing, client);
		WinNumber[client] = FakeNumber;
		ScrollTimes[client] = 0;
	}
}

public Action TimerFinishing(Handle timer, any client)
{
	if (IsClientInGame(client))
	{
		isSpinning[client] = false;
		WinCredits(client, WinNumber[client], betAmount[client]);
	}
}

public void WinCredits(int client, int Number, int Bet)
{
	if(IsClientInGame(client))
	{
		CPrintToChatAll("%s %t", PLUGIN_TAG, "WinNumber", client, Number);		
		int multiplier;
		if(Number == 0)
		{
			multiplier = 25;
			ClientCommand(client, "playgamesound *ui/item_drop6_ancient.wav");
		}
		else if(Number > 0 && Number < 500)
		{
			multiplier = -1;
			ClientCommand(client, "playgamesound music/skog_01/lostround.mp3");
			CPrintToChatAll("%s %t", PLUGIN_TAG, "YouLost", client, Bet);
		}
		else if(Number >= 500 && Number < 600)
		{			
			multiplier = 0;
			ClientCommand(client, "playgamesound *ui/item_drop1_common.wav");
			CPrintToChatAll("%s %t", PLUGIN_TAG, "NoLoseNoWin", client);
		} 
		else if(Number >= 600 && Number < 750)
		{
			multiplier = 1;
			ClientCommand(client, "playgamesound *ui/item_drop2_uncommon.wav");
		}
		else if(Number >= 750 && Number < 850)
		{
			multiplier = 2;
			ClientCommand(client, "playgamesound *ui/item_drop2_uncommon.wav");
		} 
		else if(Number >= 850 && Number < 925)
		{
			multiplier = 3;
			ClientCommand(client, "playgamesound *ui/item_drop3_rare.wav");
		}
		else if(Number >= 925 && Number < 965)
		{			
			multiplier = 4;
			ClientCommand(client, "playgamesound *ui/item_drop3_rare.wav");
		} 
		else if(Number >= 965 && Number < 995)
		{
			multiplier = 5;
			ClientCommand(client, "playgamesound *ui/item_drop3_rare.wav");
		}
		else if(Number >= 995 && Number < 997)
		{
			multiplier = 10;
			ClientCommand(client, "playgamesound *ui/item_drop3_rare.wav");
		} 
		else if(Number >= 997 && Number < 999)
		{
			multiplier = 15;
			ClientCommand(client, "playgamesound *ui/item_drop3_rare.wav");
		} 
		else if(Number == 999)
		{
			multiplier = 20;
			ClientCommand(client, "playgamesound *ui/item_drop6_ancient.wav");
		} 	
		if (multiplier > 0)
		{	
			CPrintToChatAll("%s %t", PLUGIN_TAG, "YouWin", client, Bet * multiplier, multiplier);
			Store_SetClientCredits(client, Store_GetClientCredits(client) + Bet * (multiplier + 1));
		}
	}
}

public Action TimerNext(Handle timer, any client)
{
	if (IsClientInGame(client))
	{
		SpinCredits(client);
	}
}

public bool HasClientVIP(int client)
{
	char ConVarValue[32];
	GetConVarString(g_Cvar_VIPFlag, ConVarValue, sizeof(ConVarValue));
	int flag = ReadFlagString(ConVarValue);
	return CheckCommandAccess(client, "", flag, true);
	
}