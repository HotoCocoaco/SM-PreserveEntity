#include <dhooks>

public Plugin myinfo = 
{
	name = "Sm Extra Preserved Entity",
	author = "AlliedModders LLC",
	description = "Extra S_PreserveEnts",
	version = "0.1",
	url = "https://github.com/HotoCocoaco"
};

ArrayList g_hExtraPreserveEntsClassname;
DynamicHook g_hDHookRoundCleanupShouldIgnore;
DynamicHook g_hDHookShouldCreateEntity;

public void OnPluginStart()
{
	Handle gamedatafile = LoadGameConfigFile("sm-extra-preserve-ents");
	if (gamedatafile == INVALID_HANDLE)
	{
		SetFailState("Cannot open gamedata file sm-extra-preserve-ents.txt");
		return;
	}
	
	if (!g_hDHookRoundCleanupShouldIgnore.SetFromConf(gamedatafile, SDKConf_Virtual, "CTeamplayRoundBasedRules::RoundCleanupShouldIgnore"))
	{
		SetFailState("Failed to get offset of CTeamplayRoundBasedRules::RoundCleanupShouldIgnore");
		return;
	}
	g_hDHookRoundCleanupShouldIgnore.AddParam(HookParamType_CBaseEntity);
	g_hDHookRoundCleanupShouldIgnore.HookGamerules(Hook_Pre, DHook_RoundCleanupShouldIgnore);

	if (!g_hDHookShouldCreateEntity.SetFromConf(gamedatafile, SDKConf_Virtual, "CTeamplayRoundBasedRules::ShouldCreateEntity"))
	{
		SetFailState("Failed to get offset of CTeamplayRoundBasedRules::ShouldCreateEntity");
		return;
	}
	g_hDHookShouldCreateEntity.AddParam(HookParamType_String);
	g_hDHookShouldCreateEntity.HookGamerules(Hook_Pre, DHook_ShouldCreateEntity);

	RegAdminCmd("sm_reloadextrapreserveents", Command_ReloadClassnames, ADMFLAG_GENERIC, "Reload the list of preserved entities' classname.");
}

public void OnMapStart()
{
	g_hExtraPreserveEntsClassname = new ArrayList(128);
	ReloadClassnames();
}

public void OnMapEnd()
{
	delete g_hExtraPreserveEntsClassname;
}

MRESReturn DHook_RoundCleanupShouldIgnore(DHookReturn hReturn, DHookParam hParams)
{
	int entity = hParams.Get(1);
	char classname[128];	GetEntityClassname(entity, classname, sizeof(classname));
	if (IsExtraEntsClassname(classname))
	{
		hReturn.Value = true;
		return MRES_Override;
	}

	return MRES_Ignored;
}

MRESReturn DHook_ShouldCreateEntity(DHookReturn hReturn, DHookParam hParams)
{
	char classname[128];	hParams.GetString(1, classname, sizeof(classname));
	if (IsExtraEntsClassname(classname))
	{
		hReturn.Value = false;
		return MRES_Override;
	}

	return MRES_Ignored;
}

Action Command_ReloadClassnames(int client, int args)
{
	if (!ReloadClassnames())
	{
		ReplyToCommand(client, "Failed to reload the preserved entities' classname list. Check sourcemod error logs for details.");
		return Plugin_Handled;
	}

	ReplyToCommand(client, "The list of preserved entities' classname has been reloaded.");
	return Plugin_Handled;
	
}

bool ReloadClassnames()
{
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/preserve_entities_classname.cfg");

	Handle file = OpenFile(path, "r");
	if (file == INVALID_HANDLE)
	{
		LogError("Cannot open file configs/preserve_entities_classname.cfg");
		return false;
	}

	g_hExtraPreserveEntsClassname.Clear();
	char classname[128];

	while (!IsEndOfFile(file))
	{
		if ( !ReadFileLine(file, classname, sizeof(classname)) )
		{
			break;
		}

		int commentstart;
		commentstart = StrContains(classname, "//");
		if (commentstart != -1)
		{
			classname[commentstart] = 0;
		}
		commentstart = StrContains(classname, "#");
		if (commentstart != -1)
		{
			classname[commentstart] = 0;
		}
		
		int length = strlen(classname);
		if (length < 2)
		{
			continue;
		}

		TrimString(classname);
		g_hExtraPreserveEntsClassname.PushString(classname);
	}

	delete file;
	return true;
}

bool IsExtraEntsClassname(const char[] classname)
{
	int length = g_hExtraPreserveEntsClassname.Length;
	for(int i = 0; i < length; i++)
	{
		char save_classname[128];
		g_hExtraPreserveEntsClassname.GetString(i, save_classname, sizeof(save_classname));
		if (StrEqual(save_classname, classname))
		{
			return true;
		}
	}

	return false;
}