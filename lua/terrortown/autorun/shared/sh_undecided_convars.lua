--ConVar syncing
CreateConVar("ttt2_undecided_num_choices", "3", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_undecided_ballot_timer", "60", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_undecided_time_between_ballots", "0", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_undecided_no_vote_punishment_mode", "3", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_undecided_weight_innocent", "35", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_undecided_weight_detective", "5", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_undecided_weight_traitor", "15", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_undecided_weight_evil", "25", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_undecided_weight_neutral", "20", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_undecided_can_vote_for_self", "1", {FCVAR_ARCHIVE, FCVAR_NOTFIY})

hook.Add("TTTUlxDynamicRCVars", "TTTUlxDynamicUndecidedCVars", function(tbl)
	tbl[ROLE_UNDECIDED] = tbl[ROLE_UNDECIDED] or {}
	
	--# How many possible roles can the Undecided choose between?
	--  ttt2_undecided_num_choices [2..n] (default: 3)
	table.insert(tbl[ROLE_UNDECIDED], {
		cvar = "ttt2_undecided_num_choices",
		slider = true,
		min = 2,
		max = 10,
		decimal = 0,
		desc = "ttt2_undecided_num_choices (Def: 3)"
	})
	
	--# How many seconds does the Undecided have to choose their role?
	--  ttt2_undecided_ballot_timer [0..n] (default: 60)
	table.insert(tbl[ROLE_UNDECIDED], {
		cvar = "ttt2_undecided_ballot_timer",
		slider = true,
		min = 5,
		max = 120,
		decimal = 0,
		desc = "ttt2_undecided_ballot_timer (Def: 60)"
	})
	
	--# How many seconds after the voting period ends does the Undecided receive another ballot (<=0 to only receive one ballot per game)?
	--  ttt2_undecided_time_between_ballots [0..n] (default: 0)
	table.insert(tbl[ROLE_UNDECIDED], {
		cvar = "ttt2_undecided_time_between_ballots",
		slider = true,
		min = 0,
		max = 120,
		decimal = 0,
		desc = "ttt2_undecided_time_between_ballots (Def: 0)"
	})
	
	--# If the Undecided fails to vote, what should happen to them?
	--  ttt2_undecided_no_vote_punishment_mode [0..3] (default: 3)
	--  # 0: D E A T H   P E N A L T Y
	--  # 1: They get randomly assigned a role from the list of choices that they had.
	--  # 2: They become a regular old Innocent
	--  # 3: They become a Jester
	table.insert(tbl[ROLE_UNDECIDED], {
		cvar = "ttt2_undecided_no_vote_punishment_mode",
		combobox = true,
		desc = "ttt2_undecided_no_vote_punishment_mode (Def: 3)",
		choices = {
			"0 - D E A T H   P E N A L T Y",
			"1 - Random",
			"2 - Innocent",
			"3 - Jester"
		},
		numStart = 0
	})
	
	--# What is the weight of the possibiilty for an innocent subrole (including base innocent) from being presented to the Undecided?
	--  ttt2_undecided_weight_innocent [0..n] (default: 35)
	table.insert(tbl[ROLE_UNDECIDED], {
		cvar = "ttt2_undecided_weight_innocent",
		slider = true,
		min = 0,
		max = 100,
		decimal = 0,
		desc = "ttt2_undecided_weight_innocent (Def: 35)"
	})
	
	--# What is the weight of the possibiilty for a detective subrole (including base detective) from being presented to the Undecided?
	--  ttt2_undecided_weight_detective [0..n] (default: 5)
	table.insert(tbl[ROLE_UNDECIDED], {
		cvar = "ttt2_undecided_weight_detective",
		slider = true,
		min = 0,
		max = 100,
		decimal = 0,
		desc = "ttt2_undecided_weight_detective (Def: 5)"
	})
	
	--# What is the weight of the possibiilty for a traitor subrole (including base traitor) from being presented to the Undecided?
	--  ttt2_undecided_weight_traitor [0..n] (default: 15)
	table.insert(tbl[ROLE_UNDECIDED], {
		cvar = "ttt2_undecided_weight_traitor",
		slider = true,
		min = 0,
		max = 100,
		decimal = 0,
		desc = "ttt2_undecided_weight_traitor (Def: 15)"
	})
	
	--# What is the weight of the possibiilty for a role that has a team which isn't INNOCENT, TRAITOR, or NONE from being presented to the Undecided?
	--  ttt2_undecided_weight_evil [0..n] (default: 25)
	table.insert(tbl[ROLE_UNDECIDED], {
		cvar = "ttt2_undecided_weight_evil",
		slider = true,
		min = 0,
		max = 100,
		decimal = 0,
		desc = "ttt2_undecided_weight_evil (Def: 25)"
	})
	
	--# What is the weight of the possibiilty for a role that has no discernable team (ex. Amnesiac, Drunk) from being presented to the Undecided?
	--  ttt2_undecided_weight_neutral [0..n] (default: 20)
	table.insert(tbl[ROLE_UNDECIDED], {
		cvar = "ttt2_undecided_weight_neutral",
		slider = true,
		min = 0,
		max = 100,
		decimal = 0,
		desc = "ttt2_undecided_weight_neutral (Def: 20)"
	})
	
	--# Can the Undecided vote to be an Undecided?
	--  ttt2_undecided_can_vote_for_self [0/1] (default: 1)
	table.insert(tbl[ROLE_UNDECIDED], {
		cvar = "ttt2_undecided_can_vote_for_self",
		checkbox = true,
		desc = "ttt2_undecided_can_vote_for_self (Def: 1)"
	})
end)

hook.Add("TTT2SyncGlobals", "AddUndecidedGlobals", function()
	SetGlobalInt("ttt2_undecided_num_choices", GetConVar("ttt2_undecided_num_choices"):GetInt())
	SetGlobalInt("ttt2_undecided_ballot_timer", GetConVar("ttt2_undecided_ballot_timer"):GetInt())
	SetGlobalInt("ttt2_undecided_time_between_ballots", GetConVar("ttt2_undecided_time_between_ballots"):GetInt())
	SetGlobalInt("ttt2_undecided_no_vote_punishment_mode", GetConVar("ttt2_undecided_no_vote_punishment_mode"):GetInt())
	SetGlobalInt("ttt2_undecided_weight_innocent", GetConVar("ttt2_undecided_weight_innocent"):GetInt())
	SetGlobalInt("ttt2_undecided_weight_detective", GetConVar("ttt2_undecided_weight_detective"):GetInt())
	SetGlobalInt("ttt2_undecided_weight_traitor", GetConVar("ttt2_undecided_weight_traitor"):GetInt())
	SetGlobalInt("ttt2_undecided_weight_evil", GetConVar("ttt2_undecided_weight_evil"):GetInt())
	SetGlobalInt("ttt2_undecided_weight_neutral", GetConVar("ttt2_undecided_weight_neutral"):GetInt())
	SetGlobalBool("ttt2_undecided_can_vote_for_self", GetConVar("ttt2_undecided_can_vote_for_self"):GetBool())
end)

cvars.AddChangeCallback("ttt2_undecided_num_choices", function(name, old, new)
	SetGlobalInt("ttt2_undecided_num_choices", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_undecided_ballot_timer", function(name, old, new)
	SetGlobalInt("ttt2_undecided_ballot_timer", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_undecided_time_between_ballots", function(name, old, new)
	SetGlobalInt("ttt2_undecided_time_between_ballots", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_undecided_no_vote_punishment_mode", function(name, old, new)
	SetGlobalInt("ttt2_undecided_no_vote_punishment_mode", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_undecided_weight_innocent", function(name, old, new)
	SetGlobalInt("ttt2_undecided_weight_innocent", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_undecided_weight_detective", function(name, old, new)
	SetGlobalInt("ttt2_undecided_weight_detective", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_undecided_weight_traitor", function(name, old, new)
	SetGlobalInt("ttt2_undecided_weight_traitor", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_undecided_weight_evil", function(name, old, new)
	SetGlobalInt("ttt2_undecided_weight_evil", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_undecided_weight_neutral", function(name, old, new)
	SetGlobalInt("ttt2_undecided_weight_neutral", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_undecided_can_vote_for_self", function(name, old, new)
	SetGlobalBool("ttt2_undecided_can_vote_for_self", tobool(tonumber(new)))
end)
