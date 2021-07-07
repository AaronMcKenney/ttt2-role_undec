if SERVER then
	AddCSLuaFile()
	resource.AddFile("materials/vgui/ttt/dynamic/roles/icon_undec.vmt")
	util.AddNetworkString("TTT2UndecidedBallotRequest")
	util.AddNetworkString("TTT2UndecidedBallotResponse")
end

function ROLE:PreInitialize()
	self.color = Color(205, 0, 205, 255)
	self.abbr = "undec" -- abbreviation
	
	self.scoreKillsMultiplier = 1
	self.scoreTeamKillsMultiplier = -8
	
	self.preventFindCredits = true
	self.preventKillCredits = true
	self.preventTraitorAloneCredits = true
	
	self.fallbackTable = {}
	self.unknownTeam = true -- disables team voice chat.

	self.defaultTeam = TEAM_NONE
	--Prevent the game from ending while the Undecided is in play to give them an opportunity to choose a role that could change the outcome of the game.
	self.preventWin = false
	
	-- ULX ConVars
	self.conVarData = {
		pct = 0.13,
		maximum = 1,
		minPlayers = 6,
		random = 30,
		traitorButton = 0,
		
		credits = 0,
		creditsTraitorKill = 0,
		creditsTraitorDead = 0,
		shopFallback = SHOP_DISABLED,
		
		togglable = true
	}
end

--Punishment Mode Enum for failing to vote in time.
PUNISH_MODE = {DEATH = 0, RAND = 1, INNO = 2, JES = 3}

local function IsInSpecDM(ply)
	if SpecDM and (ply.IsGhost and ply:IsGhost()) then
		return true
	end
	
	return false
end

local function GetNumPlayers()
	local num_players = 0
	for _, ply in ipairs(player.GetAll()) do
		if not ply:IsSpec() and not IsInSpecDM(ply) then
			num_players = num_players + 1
		end
	end
	
	return num_players
end

if SERVER then
	local function PrintRoleList(title, role_list)
		local role_list_str = title .. ": ["
		for i = 1, #role_list do
			local role_data = roles.GetByIndex(role_list[i])
			role_list_str = role_list_str .. role_data.name
			if i < #role_list then
				role_list_str = role_list_str .. ", "
			end
		end
		role_list_str = role_list_str .. "]"
		print(role_list_str)
	end
	
	local function PrintWeightThresholds(inno_weight, det_weight, tra_weight, evil_weight, neut_weight)
		weight_thresh_str = "Weight Thresholds: "
		if inno_weight > 0 then
			weight_thresh_str = weight_thresh_str .. "Inno(<=" .. inno_weight .. ") "
		end
		if det_weight > 0 then
			weight_thresh_str = weight_thresh_str .. "Det(<=" .. inno_weight + det_weight .. ") " 
		end
		if tra_weight > 0 then
			weight_thresh_str = weight_thresh_str .. "Tra(<=" .. inno_weight + det_weight + tra_weight .. ") " 
		end
		if evil_weight > 0 then
			weight_thresh_str = weight_thresh_str .. "Evil(<=" .. inno_weight + det_weight + tra_weight + evil_weight .. ") " 
		end
		if neut_weight > 0 then
			weight_thresh_str = weight_thresh_str .. "Neut(<=" .. inno_weight + det_weight + tra_weight + evil_weight  + neut_weight .. ") " 
		end
		print(weight_thresh_str)
	end
	
	local function PunishTheNonVoter(ply)
		local mode = GetConVar("ttt2_undecided_no_vote_punishment_mode"):GetInt()
		LANG.Msg(ply, "CONSEQUENCES_" .. UNDECIDED.name, nil, MSG_MSTACK_ROLE)
		if mode == PUNISH_MODE.DEATH then
			ply:Kill()
		elseif mode == PUNISH_MODE.RAND then
			ply:SetRole(ply.undec_ballot[math.random(#ply.undec_ballot)])
			SendFullStateUpdate()
		elseif mode == PUNISH_MODE.JES and ROLE_JESTER then
			ply:SetRole(ROLE_JESTER)
			SendFullStateUpdate()
		else --PUNISH_MODE.INNO
			ply:SetRole(ROLE_INNOCENT)
			SendFullStateUpdate()
		end
		
		ply.undec_ballot = nil
	end
	
	local function CreateBallot(ply)
		--Could shorten this function by combining the groups into a table, but its not that big of a deal. May need to do that if feature bloat occurs.
		local ballot = {}
		local num_players = GetNumPlayers()
		
		local num_choices = GetConVar("ttt2_undecided_num_choices"):GetInt()
		local inno_weight = GetConVar("ttt2_undecided_weight_innocent"):GetInt()
		local det_weight = GetConVar("ttt2_undecided_weight_detective"):GetInt()
		local tra_weight = GetConVar("ttt2_undecided_weight_traitor"):GetInt()
		local evil_weight = GetConVar("ttt2_undecided_weight_evil"):GetInt()
		local neut_weight = GetConVar("ttt2_undecided_weight_neutral"):GetInt()
		
		local inno_role_list = {}
		local det_role_list = {}
		local tra_role_list = {}
		local evil_role_list = {}
		local neut_role_list = {}
		local role_data_list = roles.GetList()
		for i = 1, #role_data_list do
			local role_data = role_data_list[i]
			if role_data.notSelectable or role_data.index == ROLE_NONE then
				--notSelectable is true for roles spawned under special circumstances, such as the Ravenous or the Graverobber.
				--ROLE_NONE should not be messed with. It would be mildly funny if it were selectable, but would probably bug out the server.
				continue
			end
			
			--role_data.builtin will be true for INNOCENT and TRAITOR, which are always enabled.
			local enabled = true
			local min_players = 0
			if not role_data.builtin then
				enabled = GetConVar("ttt_" .. role_data.name .. "_enabled"):GetBool()
				min_players = GetConVar("ttt_" .. role_data.name .. "_min_players"):GetInt()
			end
			if not enabled or min_players > num_players then
				continue
			end
			
			if role_data.defaultTeam == TEAM_INNOCENT and (role_data.index == ROLE_INNOCENT or role_data.baserole == ROLE_INNOCENT) then
				inno_role_list[#inno_role_list + 1] = role_data.index
			elseif role_data.defaultTeam == TEAM_INNOCENT and (role_data.index == ROLE_DETECTIVE or role_data.baserole == ROLE_DETECTIVE) then
				det_role_list[#det_role_list + 1] = role_data.index
			elseif role_data.defaultTeam == TEAM_TRAITOR then
				tra_role_list[#tra_role_list + 1] = role_data.index
			elseif role_data.defaultTeam ~= TEAM_NONE and role_data.defaultTeam ~= TEAM_INNOCENT and role_data.defaultTeam ~= TEAM_TRAITOR then
				evil_role_list[#evil_role_list + 1] = role_data.index
			else --Not an Innocent or Detective. Not on the Traitor Team. Either some esoteric role on TEAM_INNOCENT (ex. Bodyguard) or TEAM_NONE.
				neut_role_list[#neut_role_list + 1] = role_data.index
			end
		end
		
		print("\nUNDEC_DEBUG CreateBallot:")
		PrintRoleList("Innocent Role List", inno_role_list)
		PrintRoleList("Detective Role List", det_role_list)
		PrintRoleList("Traitor Role List", tra_role_list)
		PrintRoleList("Evil Role List", evil_role_list)
		PrintRoleList("Neutral Role List", neut_role_list)
		
		--If a role list is empty, then set the corresponding weight to 0 so that we don't waste a choice trying to pick a role from it.
		if #inno_role_list <= 0 then
			inno_weight = 0
		end
		if #det_role_list <= 0 then
			det_weight = 0
		end
		if #tra_role_list <= 0 then
			tra_weight = 0
		end
		if #evil_role_list <= 0 then
			evil_weight = 0
		end
		if #neut_role_list <= 0 then
			neut_weight = 0
		end
		
		PrintWeightThresholds(inno_weight, det_weight, tra_weight, evil_weight, neut_weight)
		
		local total_weight = inno_weight + det_weight + tra_weight + evil_weight + neut_weight
		for i = 1, num_choices do
			if total_weight <= 0 then
				print("Total weight is 0!")
				break
			end
			
			--Each weight is a bucket. If the random number lands in the bucket, choose a random role from the corresponding list.
			--ExtractRandomEntry both returns a random entry in the list and removes it.
			local r = math.random(total_weight)
			print("Choice " .. i .. ": r=" .. r)
			if inno_weight > 0 and r <= inno_weight then
				ballot[#ballot + 1] = table.ExtractRandomEntry(inno_role_list)
				if #inno_role_list <= 0 then
					total_weight = total_weight - inno_weight
					inno_weight = 0
					print("Innocent Role List is now empty!")
					PrintWeightThresholds(inno_weight, det_weight, tra_weight, evil_weight, neut_weight)
				end
			elseif det_weight > 0 and r <= inno_weight + det_weight then
				ballot[#ballot + 1] = table.ExtractRandomEntry(det_role_list)
				if #det_role_list <= 0 then
					total_weight = total_weight - det_weight
					det_weight = 0
					print("Detective Role List is now empty!")
					PrintWeightThresholds(inno_weight, det_weight, tra_weight, evil_weight, neut_weight)
				end
			elseif tra_weight > 0 and r <= inno_weight + det_weight + tra_weight then
				ballot[#ballot + 1] = table.ExtractRandomEntry(tra_role_list)
				if #tra_role_list <= 0 then
					total_weight = total_weight - tra_weight
					tra_weight = 0
					print("Traitor Role List is now empty!")
					PrintWeightThresholds(inno_weight, det_weight, tra_weight, evil_weight, neut_weight)
				end
			elseif evil_weight > 0 and r <= inno_weight + det_weight + tra_weight + evil_weight then
				ballot[#ballot + 1] = table.ExtractRandomEntry(evil_role_list)
				if #evil_role_list <= 0 then
					total_weight = total_weight - evil_weight
					evil_weight = 0
					print("Evil Role List is now empty!")
					PrintWeightThresholds(inno_weight, det_weight, tra_weight, evil_weight, neut_weight)
				end
			else --r > inno_weight + det_weight + tra_weight + evil_weight
				ballot[#ballot + 1] = table.ExtractRandomEntry(neut_role_list)
				if #neut_role_list <= 0 then
					total_weight = total_weight - neut_weight
					neut_weight = 0
					print("Neutral Role List is now empty!")
					PrintWeightThresholds(inno_weight, det_weight, tra_weight, evil_weight, neut_weight)
				end
			end
		end
		
		PrintRoleList("Ballot", ballot)
		print("\n")
		
		ply.undec_ballot = ballot
		net.Start("TTT2UndecidedBallotRequest")
		net.WriteTable(ply.undec_ballot)
		net.Send(ply)
		
		timer.Create("UndecidedBallotTimer_Server_" .. ply:SteamID64(), GetConVar("ttt2_undecided_ballot_timer"):GetInt(), 1, function()
			if GetRoundState() == ROUND_ACTIVE and ply:Alive() and not IsInSpecDM(ply) and ply.undec_ballot then
				PunishTheNonVoter(ply)
			end
		end)
	end
	
	local function DestroyBallot(ply)
		print("UNDEC_DEBUG DestroyBallot: Destroying ballot for " .. ply:GetName())
		--Remove the timer now that the player's no longer an Undecided, and tell the client to also remove their timer.
		if timer.Exists("UndecidedBallotTimer_Server_" .. ply:SteamID64()) then
			timer.Remove("UndecidedBallotTimer_Server_" .. ply:SteamID64())
		end
		ply.undec_ballot = nil
		
		net.Start("TTT2UndecidedBallotResponse")
		net.Send(ply)
	end
	
	function ROLE:GiveRoleLoadout(ply, isRoleChange)
		if timer.Exists("UndecidedBallotTimer_Server_" .. ply:SteamID64()) then
			--Recreate the ballot if the player somehow becomes Undecided multiple times in quick succession.
			DestroyBallot(ply)
		end
		
		CreateBallot(ply)
	end
	
	net.Receive("TTT2UndecidedBallotResponse", function(len, ply)
		local role_id = net.ReadInt(16)
		local ballot_has_role_id = (ply.undec_ballot and table.HasValue(ply.undec_ballot, role_id))
		
		DestroyBallot(ply)
		if GetRoundState() == ROUND_ACTIVE and ply:Alive() and not IsInSpecDM(ply) and ballot_has_role_id then
			if role_id ~= ply:GetSubRole() then
				if DOPPELGANGER and ply:GetTeam() == TEAM_DOPPELGANGER then
					--An Undecided Doppelganger maintains their team throughout the transition.
					ply:SetRole(role_id, TEAM_DOPPELGANGER)
				else
					ply:SetRole(role_id)
				end
				SendFullStateUpdate()
			elseif role_id == ROLE_UNDECIDED then
				--If the Undecided picks their own role, give them another ballot.
				CreateBallot(ply)
			end
		end
	end)
	
	hook.Add("TTT2PostPlayerDeath", "TTT2PostPlayerDeathUndecided", function(victim, inflictor, attacker)
		if GetRoundState() == ROUND_ACTIVE and IsValid(victim) and victim:IsPlayer() and victim.undec_ballot then
			--Note: A new ballot is created should the Undecided respawn via GiveRoleLoadout.
			DestroyBallot(victim)
		end
	end)
	
	hook.Add("TTTEndRound", "TTTEndRoundUndecided", function()
		--Remove the ballot for everyone so that it doesn't show up next round.
		--Do this for everyone as they may have changed roles while the ballot is up.
		for _, ply in ipairs(player.GetAll()) do
			DestroyBallot(ply)
		end
	end)
end

if CLIENT then
	local function GetBallotEntryStr(role_data)
		local role_str = LANG.TryTranslation(role_data.name)
		
		--In a few cases the client is lied to about the role that they have (Currently that's the Shinigami, Wrath, and Lycanthrope).
		--For these cases, alter the string so that they along with the base Innocent appear as "Innocent*", to keep up that illusion.
		local num_players = GetNumPlayers()
		local shini_can_exist = (SHINIGAMI and GetConVar("ttt_shinigami_enabled"):GetBool() and num_players >= GetConVar("ttt_shinigami_min_players"):GetInt())
		local cloaked_wrath_can_exist = (WRATH and GetConVar("ttt_wrath_enabled"):GetBool() and num_players >= GetConVar("ttt_wrath_min_players"):GetInt() and GetConVar("ttt_wrath_cannot_see_own_role"):GetBool())
		local cloaked_lyc_can_exist = (LYCANTHROPE and GetConVar("ttt_lycanthrope_enabled"):GetBool() and num_players >= GetConVar("ttt_lycanthrope_min_players"):GetInt() and not GetConVar("ttt2_lyc_know_role"):GetBool())
		if (role_data.index == ROLE_INNOCENT and (shini_can_exist or cloaked_wrath_can_exist or cloaked_lyc_can_exist)) or
			(SHINIGAMI and role_data.index == ROLE_SHINIGAMI) or
			(WRATH and role_data.index == ROLE_WRATH and GetConVar("ttt_wrath_cannot_see_own_role"):GetBool()) or
			(LYCANTHROPE and role_data.index == ROLE_LYCANTHROPE and not GetConVar("ttt2_lyc_know_role"):GetBool()) then
			role_str = "Innocent*"
		end
		
		return role_str
	end
	
	local function DestroyBallot()
		local client = LocalPlayer()
		print("UNDEC_DEBUG DestroyBallot: Destroying ballot for " .. client:GetName())
		if timer.Exists("UndecidedBallotTimer_Client") then
			timer.Remove("UndecidedBallotTimer_Client")
		end
		if client.undec_frame and client.undec_frame.Close then
			client.undec_frame:Close()
		end
		hook.Remove("Think", "UndecidedThink")
	end
	
	net.Receive("TTT2UndecidedBallotRequest", function()
		local client = LocalPlayer()
		local ballot = net.ReadTable()
		
		DestroyBallot()
		timer.Create("UndecidedBallotTimer_Client", GetConVar("ttt2_undecided_ballot_timer"):GetInt(), 1, function()
			DestroyBallot()
		end)
		client.undec_frame = vgui.Create("DFrame")
		
		client.undec_frame:SetTitle(LANG.TryTranslation("BALLOT_TITLE_" .. UNDECIDED.name) .. " (" .. math.ceil(math.abs(timer.TimeLeft("UndecidedBallotTimer_Client"))) .. ")")
		client.undec_frame:SetPos(5, ScrH() / 3)
		client.undec_frame:SetSize(150, 10 + (20 * (#ballot + 1)))
		client.undec_frame:SetVisible(true)
		client.undec_frame:SetDraggable(false)
		client.undec_frame:ShowCloseButton(false)
		
		if #ballot <= 0 then
			LANG.Msg("BAD_BALLOT_" .. UNDECIDED.name, nil, MSG_MSTACK_ROLE)
			return
		end
		
		for i = 1, #ballot do
			local role_id = ballot[i]
			local role_data = roles.GetByIndex(role_id)
			local ballot_entry_str = GetBallotEntryStr(role_data)
			local button = vgui.Create("DButton", client.undec_frame)
			button:SetText(ballot_entry_str)
			button:SetPos(0, 10 + (20 * i))
			button:SetSize(150,20)
			button.DoClick = function()
				net.Start("TTT2UndecidedBallotResponse")
				net.WriteInt(role_id, 16)
				net.SendToServer()
				DestroyBallot()
			end
		end
		
		hook.Add("Think", "UndecidedThink", function()
			local client = LocalPlayer()
			if client.undec_frame and client.undec_frame.SetTitle and timer.Exists("UndecidedBallotTimer_Client") then
				client.undec_frame:SetTitle(LANG.TryTranslation("BALLOT_TITLE_" .. UNDECIDED.name) .. " (" .. math.ceil(math.abs(timer.TimeLeft("UndecidedBallotTimer_Client"))) .. ")")
			end
		end)
	end)
	
	net.Receive("TTT2UndecidedBallotResponse", function()
		DestroyBallot()
	end)
end