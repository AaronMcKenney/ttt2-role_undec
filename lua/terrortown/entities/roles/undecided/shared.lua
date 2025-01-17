if SERVER then
	AddCSLuaFile()
	resource.AddFile("materials/vgui/ttt/dynamic/roles/icon_undec.vmt")
	util.AddNetworkString("TTT2UndecidedBallotRequest")
	util.AddNetworkString("TTT2UndecidedBallotResponse")
end

function ROLE:PreInitialize()
	self.color = Color(200, 0, 200, 255)
	self.abbr = "undec" -- abbreviation
	
	self.score.teamKillsMultiplier = 0
	self.score.killsMultiplier = 0
	self.score.aliveTeammatesBonusMultiplier = 0
	
	self.preventFindCredits = true
	
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
		
		--The Undecided starts with 0 credits, which in turn means that if they become a shopping role they will still have 0 credits.
		--While this is lame, it is probably better than giving them credits for game balance reasons.
		credits = 0,
		creditsAwardDeadEnable = 0,
		creditsAwardKillEnable = 0,
		shopFallback = SHOP_DISABLED,
		
		togglable = true
	}
end

--Cached variable, used if someone becomes Undecided in the middle of a round
local NUM_PLYS_AT_ROUND_BEGIN = 0
--Used to signify that the role may be hidden as an Innocent
local ROLE_INNOCENT_ASTERISK = -1

local function IsInSpecDM(ply)
	if SpecDM and (ply.IsGhost and ply:IsGhost()) then
		return true
	end
	
	return false
end

local function GetNumPlayers()
	if NUM_PLYS_AT_ROUND_BEGIN > 0 then
		return NUM_PLYS_AT_ROUND_BEGIN
	end
	
	local num_players = 0
	for _, ply in ipairs(player.GetAll()) do
		if not ply:IsSpec() and not IsInSpecDM(ply) then
			num_players = num_players + 1
		end
	end
	
	return num_players
end

local function DestroyBallot(ply)
	if SERVER then
		--print("UNDEC_DEBUG DestroyBallot(SERVER): Destroying ballot for " .. ply:GetName())
		--Remove the timer now that the player's no longer an Undecided, and tell the client to also remove their timer.
		if timer.Exists("UndecidedBallotTimer_Server_" .. ply:SteamID64()) then
			timer.Remove("UndecidedBallotTimer_Server_" .. ply:SteamID64())
		end
		ply.undec_ballot = nil
		
		net.Start("TTT2UndecidedBallotResponse")
		net.Send(ply)
	else --CLIENT
		local client = LocalPlayer()
		--print("UNDEC_DEBUG DestroyBallot(CLIENT): Destroying ballot for " .. client:GetName())
		if timer.Exists("UndecidedBallotTimer_Client") then
			timer.Remove("UndecidedBallotTimer_Client")
		end
		if client.undec_frame and client.undec_frame.Close then
			client.undec_frame:Close()
		end
		hook.Remove("Think", "UndecidedThink")
	end
end

hook.Add("TTTBeginRound", "TTTBeginRoundUndecided", function()
	--Note: This is for when someone becomes an Undecided in the middle of a round.
	--Roles are assigned before BeginRound, so NUM_PLYS_AT_ROUND_BEGIN won't be used for undecideds at the start of the game.
	--However, explicitly assign NUM_PLYS_AT_ROUND_BEGIN here as we only know how many players there actually are right here.
	
	NUM_PLYS_AT_ROUND_BEGIN = GetNumPlayers()
end)

local function ResetAllUndecidedData()
	if SERVER then
		for _, ply in ipairs(player.GetAll()) do
			--Remove the ballot for everyone so that it doesn't show up next round.
			--Do this for everyone as they may have changed roles while the ballot is up.
			--Don't do this in the TTTBeginRound hook, as that will immediately destroy the ballots of players who spawned as Undecided.
			DestroyBallot(ply)
			
			if timer.Exists("UndecidedNewBallotTimer_Server_" .. ply:SteamID64()) then
				timer.Remove("UndecidedNewBallotTimer_Server_" .. ply:SteamID64())
			end
			
			ply.undec_has_voted = nil
			STATUS:RemoveStatus(ply, "ttt2_undec_vote")
		end
	end
	
	--Reset NUM_PLYS_AT_ROUND_BEGIN, as players may join/leave the server between now and the next TTTBeginRound
	NUM_PLYS_AT_ROUND_BEGIN = 0
end
hook.Add("TTTPrepareRound", "TTTPrepareRoundUndecided", ResetAllUndecidedData)
hook.Add("TTTEndRound", "TTTEndRoundUndecided", ResetAllUndecidedData)

if SERVER then
	--Punishment Mode Enum for failing to vote in time.
	local PUNISH_MODE = {DEATH = 0, RAND = 1, INNO = 2, JES = 3}
	local ENABLE_MODE = {EN = 0, DIS = 1, EN_OR_DIS = 2}
	--Forward declaration needed as both SetDeadlineForNewBallot and CreateBallot call each other.
	local CreateBallot, SetDeadlineForNewBallot
	
	--Print statements for UNDEC_DEBUG
	--local function PrintRoleList(title, role_list)
	--	local role_list_str = title .. ": ["
	--	for i = 1, #role_list do
	--		local role_data = roles.GetByIndex(role_list[i])
	--		role_list_str = role_list_str .. role_data.name
	--		if i < #role_list then
	--			role_list_str = role_list_str .. ", "
	--		end
	--	end
	--	role_list_str = role_list_str .. "]"
	--	print(role_list_str)
	--end
	--
	--local function PrintWeightThresholds(inno_weight, det_weight, tra_weight, evil_weight, neut_weight)
	--	weight_thresh_str = "Weight Thresholds: "
	--	if inno_weight > 0 then
	--		weight_thresh_str = weight_thresh_str .. "Inno(<=" .. inno_weight .. ") "
	--	end
	--	if det_weight > 0 then
	--		weight_thresh_str = weight_thresh_str .. "Det(<=" .. inno_weight + det_weight .. ") " 
	--	end
	--	if tra_weight > 0 then
	--		weight_thresh_str = weight_thresh_str .. "Tra(<=" .. inno_weight + det_weight + tra_weight .. ") " 
	--	end
	--	if evil_weight > 0 then
	--		weight_thresh_str = weight_thresh_str .. "Evil(<=" .. inno_weight + det_weight + tra_weight + evil_weight .. ") " 
	--	end
	--	if neut_weight > 0 then
	--		weight_thresh_str = weight_thresh_str .. "Neut(<=" .. inno_weight + det_weight + tra_weight + evil_weight  + neut_weight .. ") " 
	--	end
	--	print(weight_thresh_str)
	--end
	
	local function CreateClientBallotEntry(role_id)
		local out_role_id = role_id
		
		--In a few cases the client is lied to about the role that they have (Currently that's the Shinigami, Wrath, and Lycanthrope).
		--For these cases, obscure them alongside the role that they're pretending to be, so that the client won't be able to unravel the role's secret.
		local num_players = GetNumPlayers()
		local shini_can_exist = (SHINIGAMI and GetConVar("ttt_shinigami_enabled"):GetBool() and num_players >= GetConVar("ttt_shinigami_min_players"):GetInt())
		local cloaked_wrath_can_exist = (WRATH and GetConVar("ttt_wrath_enabled"):GetBool() and num_players >= GetConVar("ttt_wrath_min_players"):GetInt() and GetConVar("ttt_wrath_cannot_see_own_role"):GetBool())
		local cloaked_lyc_can_exist = (LYCANTHROPE and GetConVar("ttt_lycanthrope_enabled"):GetBool() and num_players >= GetConVar("ttt_lycanthrope_min_players"):GetInt() and not GetConVar("ttt2_lyc_know_role"):GetBool())
		if (role_id == ROLE_INNOCENT and (shini_can_exist or cloaked_wrath_can_exist or cloaked_lyc_can_exist)) or
			(SHINIGAMI and role_id == ROLE_SHINIGAMI) or
			(REVENANT and role_id == ROLE_REVENANT) or
			(WRATH and role_id == ROLE_WRATH and GetConVar("ttt_wrath_cannot_see_own_role"):GetBool()) or
			(LYCANTHROPE and role_id == ROLE_LYCANTHROPE and not GetConVar("ttt2_lyc_know_role"):GetBool()) then
			out_role_id = ROLE_INNOCENT_ASTERISK
		end
		
		--Does not handle the case where the Undecided can vote on roles not normally enabled, and all of the cloaked special innocent roles are disabled.
		--No plans to handle that case: it only occurs during debug sessions for edge cases, and can't think of an edge case where it's necessary.
		
		return out_role_id
	end
	
	local function PunishTheNonVoter(ply)
		local mode = GetConVar("ttt2_undecided_no_vote_punishment_mode"):GetInt()
		LANG.Msg(ply, "CONSEQUENCES_" .. UNDECIDED.name, nil, MSG_MSTACK_WARN)
		events.Trigger(EVENT_UNDEC_ABSTAIN, ply)
		
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
		
		STATUS:RemoveStatus(ply, "ttt2_undec_vote")
	end
	
	local function RoleCanAppearOnBallot(role_data)
		local num_plys = GetNumPlayers()

		if role_data.notSelectable or role_data.index == ROLE_NONE then
			--notSelectable is true for roles spawned under special circumstances, such as the Ravenous or the Graverobber.
			--ROLE_NONE should not be messed with. It would be mildly funny if it were selectable, but would probably bug out the server.
			return false
		end

		--role_data.builtin will be true for INNOCENT and TRAITOR, which are always enabled.
		local enabled = true
		local min_players = 0
		if not role_data.builtin then
			enabled = GetConVar("ttt_" .. role_data.name .. "_enabled"):GetBool()
			min_players = GetConVar("ttt_" .. role_data.name .. "_min_players"):GetInt()
		end

		--Feature request for those who want the Undecided to select between roles normally unavailable.
		if GetConVar("ttt2_undecided_role_enable_mode"):GetInt() == ENABLE_MODE.DIS then
			enabled = not enabled
		elseif GetConVar("ttt2_undecided_role_enable_mode"):GetInt() == ENABLE_MODE.EN_OR_DIS then
			enabled = true
		end

		--can_vote_for_self overrides ttt2_undecided_role_enable_mode
		if role_data.index == ROLE_UNDECIDED then
			enabled = GetConVar("ttt2_undecided_can_vote_for_self"):GetBool()
		end

		if not enabled or min_players > num_plys then
			return false
		end
		
		return true
	end
	
	function CreateBallot(ply)
		STATUS:RemoveStatus(ply, "ttt2_undec_vote")
		
		--Could shorten this function by combining the groups into a table, but its not that big of a deal. May need to do that if feature bloat occurs.
		local ballot = {}
		
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
			if not RoleCanAppearOnBallot(role_data) then
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
		
		--print("\nUNDEC_DEBUG CreateBallot:")
		--PrintRoleList("Innocent Role List", inno_role_list)
		--PrintRoleList("Detective Role List", det_role_list)
		--PrintRoleList("Traitor Role List", tra_role_list)
		--PrintRoleList("Evil Role List", evil_role_list)
		--PrintRoleList("Neutral Role List", neut_role_list)
		
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
		
		--UNDEC_DEBUG
		--PrintWeightThresholds(inno_weight, det_weight, tra_weight, evil_weight, neut_weight)
		
		local total_weight = inno_weight + det_weight + tra_weight + evil_weight + neut_weight
		for i = 1, num_choices do
			if total_weight <= 0 then
				--UNDEC_DEBUG
				--print("Total weight is 0!")
				break
			end
			
			--Each weight is a bucket. If the random number lands in the bucket, choose a random role from the corresponding list.
			--ExtractRandomEntry both returns a random entry in the list and removes it.
			local r = math.random(total_weight)
			--UNDEC_DEBUG
			--print("Choice " .. i .. ": r=" .. r)
			if inno_weight > 0 and r <= inno_weight then
				ballot[#ballot + 1] = table.ExtractRandomEntry(inno_role_list)
				if #inno_role_list <= 0 then
					total_weight = total_weight - inno_weight
					inno_weight = 0
					--UNDEC_DEBUG
					--print("Innocent Role List is now empty!")
					--PrintWeightThresholds(inno_weight, det_weight, tra_weight, evil_weight, neut_weight)
				end
			elseif det_weight > 0 and r <= inno_weight + det_weight then
				ballot[#ballot + 1] = table.ExtractRandomEntry(det_role_list)
				if #det_role_list <= 0 then
					total_weight = total_weight - det_weight
					det_weight = 0
					--UNDEC_DEBUG
					--print("Detective Role List is now empty!")
					--PrintWeightThresholds(inno_weight, det_weight, tra_weight, evil_weight, neut_weight)
				end
			elseif tra_weight > 0 and r <= inno_weight + det_weight + tra_weight then
				ballot[#ballot + 1] = table.ExtractRandomEntry(tra_role_list)
				if #tra_role_list <= 0 then
					total_weight = total_weight - tra_weight
					tra_weight = 0
					--UNDEC_DEBUG
					--print("Traitor Role List is now empty!")
					--PrintWeightThresholds(inno_weight, det_weight, tra_weight, evil_weight, neut_weight)
				end
			elseif evil_weight > 0 and r <= inno_weight + det_weight + tra_weight + evil_weight then
				ballot[#ballot + 1] = table.ExtractRandomEntry(evil_role_list)
				if #evil_role_list <= 0 then
					total_weight = total_weight - evil_weight
					evil_weight = 0
					--UNDEC_DEBUG
					--print("Evil Role List is now empty!")
					--PrintWeightThresholds(inno_weight, det_weight, tra_weight, evil_weight, neut_weight)
				end
			else --r > inno_weight + det_weight + tra_weight + evil_weight
				ballot[#ballot + 1] = table.ExtractRandomEntry(neut_role_list)
				if #neut_role_list <= 0 then
					total_weight = total_weight - neut_weight
					neut_weight = 0
					--UNDEC_DEBUG
					--print("Neutral Role List is now empty!")
					--PrintWeightThresholds(inno_weight, det_weight, tra_weight, evil_weight, neut_weight)
				end
			end
		end
		
		--UNDEC_DEBUG
		--PrintRoleList("Ballot", ballot)
		--print("\n")
		
		ply.undec_ballot = ballot
		
		net.Start("TTT2UndecidedBallotRequest")
		local client_ballot = {}
		for i = 1, #ply.undec_ballot do
			client_ballot[i] = CreateClientBallotEntry(ply.undec_ballot[i])
		end
		net.WriteTable(client_ballot)
		net.WriteInt(GetConVar("ttt2_undecided_ballot_timer"):GetInt(), 16)
		net.Send(ply)
		
		timer.Create("UndecidedBallotTimer_Server_" .. ply:SteamID64(), GetConVar("ttt2_undecided_ballot_timer"):GetInt(), 1, function()
			if GetRoundState() == ROUND_ACTIVE and ply:Alive() and not IsInSpecDM(ply) and ply.undec_ballot then
				PunishTheNonVoter(ply)
				DestroyBallot(ply)
				SetDeadlineForNewBallot(ply)
			end
		end)
	end
	
	function SetDeadlineForNewBallot(ply)
		local time_between_ballots = GetConVar("ttt2_undecided_time_between_ballots"):GetInt()
		
		if time_between_ballots > 0 then
			timer.Create("UndecidedNewBallotTimer_Server_" .. ply:SteamID64(), time_between_ballots, 1, function()
				if GetRoundState() == ROUND_ACTIVE and ply:Alive() and not IsInSpecDM(ply) then
					DestroyBallot(ply)
					CreateBallot(ply)
				end
			end)
			
			STATUS:AddTimedStatus(ply, "ttt2_undec_between_ballots", time_between_ballots, true)
		end
	end
	
	function ROLE:GiveRoleLoadout(ply, isRoleChange)
		if timer.Exists("UndecidedBallotTimer_Server_" .. ply:SteamID64()) then
			--Recreate the ballot if the player somehow becomes Undecided multiple times in quick succession.
			DestroyBallot(ply)
		end
		
		if GetRoundState() ~= ROUND_POST then
			CreateBallot(ply)
		end
	end
	
	local function IsStickyTeam(team)
		--A hack. True if the supported team is not to be altered for balancing reasons.
		if (DOPPELGANGER and team == TEAM_DOPPELGANGER) or (COPYCAT and team == TEAM_COPYCAT) then
			return true
		end
		
		return false
	end
	
	net.Receive("TTT2UndecidedBallotResponse", function(len, ply)
		local ballot_id = net.ReadInt(16)
		local ballot_id_is_valid = (ply.undec_ballot and ballot_id > 0 and ballot_id <= #ply.undec_ballot)
		
		--print("UNDEC_DEBUG TTT2UndecidedBallotResponse: ply=" .. ply:GetName() .. ", ballot_id=" .. tostring(ballot_id) .. ", ballot_id_is_valid=" .. tostring(ballot_id_is_valid))
		
		if GetRoundState() == ROUND_ACTIVE and ply:Alive() and not IsInSpecDM(ply) and ballot_id_is_valid then
			local role_id = ply.undec_ballot[ballot_id]
			local role_data = roles.GetByIndex(role_id)
			DestroyBallot(ply)
			
			if not RoleCanAppearOnBallot(role_data) then
				LANG.Msg(ply, "BAD_ROLE_" .. UNDECIDED.name, {role=role_data.name}, MSG_MSTACK_WARN)
				CreateBallot(ply)
				return
			end
			
			events.Trigger(EVENT_UNDEC_VOTE, ply, role_id)
			
			--UNDEC_DEBUG
			--local role_data = roles.GetByIndex(role_id)
			--print("  chosen role is " .. role_data.name)
			
			if role_id ~= ply:GetSubRole() then
				if IsStickyTeam(ply:GetTeam()) then
					--An Undecided Doppelganger/Copycat maintains their team throughout the transition.
					--Allows for the Dop!Undec/Copy!Undec to extend their role changing abilities.
					ply:SetRole(role_id, ply:GetTeam())
				else
					ply:SetRole(role_id)
				end
				SendFullStateUpdate()
			end
			
			if role_id == ROLE_UNDECIDED then
				--If the Undecided picks their own role, give them another ballot.
				--Picking the Undecided role does not count as voting.
				CreateBallot(ply)
			else
				--Mark the player as having voted.
				ply.undec_has_voted = true
				STATUS:AddStatus(ply, "ttt2_undec_vote")
				
				SetDeadlineForNewBallot(ply)
			end
		else
			if GetRoundState() == ROUND_ACTIVE and ply:Alive() and not IsInSpecDM(ply) and not ballot_id_is_valid then
				LANG.Msg(ply, "INVALID_RESPONSE_" .. UNDECIDED.name, {i=tostring(ballot_id), n=tostring(#ply.undec_ballot)}, MSG_MSTACK_WARN)
				PunishTheNonVoter(ply)
				SetDeadlineForNewBallot(ply)
			end
			
			DestroyBallot(ply)
		end
	end)
	
	hook.Add("TTT2PostPlayerDeath", "TTT2PostPlayerDeathUndecided", function(victim, inflictor, attacker)
		if GetRoundState() == ROUND_ACTIVE and IsValid(victim) and victim:IsPlayer() and victim.undec_ballot then
			--Note: A new ballot is created should the Undecided respawn via GiveRoleLoadout.
			DestroyBallot(victim)
		end
	end)
end

if CLIENT then
	local function GetBallotEntryStr(maybe_role_id)
		if maybe_role_id >= 0 then
			local role_data = roles.GetByIndex(maybe_role_id)
			return LANG.TryTranslation(role_data.name)
		end
		
		--Otherwise the role is lying about what it really is. Only give a hint (in the form of an asterisk) as to what it could be.
		
		--ROLE_INNOCENT_ASTERISK
		local role_data = roles.GetByIndex(ROLE_INNOCENT)
		return LANG.TryTranslation(role_data.name) .. "*"
	end
	
	hook.Add("Initialize", "RegisteringStatusOnInitializeForUndecided", function()
		STATUS:RegisterStatus("ttt2_undec_vote", {
			hud = Material("vgui/ttt/undec_vote.png"),
			type = "good"
		})
		STATUS:RegisterStatus("ttt2_undec_between_ballots", {
			hud = Material("vgui/ttt/dynamic/roles/icon_undec.vtf"),
			type = "bad"
		})
	end)
	
	net.Receive("TTT2UndecidedBallotRequest", function()
		local client = LocalPlayer()
		local ballot = net.ReadTable()
		local ballot_timer = net.ReadInt(16)
		
		DestroyBallot()
		timer.Create("UndecidedBallotTimer_Client", ballot_timer, 1, function()
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
		
		local i = 1
		for ballot_id, maybe_role_id in pairs(ballot) do
			local ballot_entry_str = GetBallotEntryStr(maybe_role_id)
			local button = vgui.Create("DButton", client.undec_frame)
			button:SetText(ballot_entry_str)
			button:SetPos(0, 10 + (20 * i))
			button:SetSize(150,20)
			button.DoClick = function()
				net.Start("TTT2UndecidedBallotResponse")
				net.WriteInt(ballot_id, 16)
				net.SendToServer()
				DestroyBallot()
			end
			i = i + 1
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

	-------------
	-- CONVARS --
	-------------
	function ROLE:AddToSettingsMenu(parent)
		local form = vgui.CreateTTT2Form(parent, "header_roles_additional")

		form:MakeSlider({
			serverConvar = "ttt2_undecided_num_choices",
			label = "label_undecided_num_choices",
			min = 2,
			max = 10,
			decimal = 0,
		})

		form:MakeSlider({
			serverConvar = "ttt2_undecided_ballot_timer",
			label = "label_undecided_ballot_timer",
			min = 5,
			max = 120,
			decimal = 0,
		})

		form:MakeSlider({
			serverConvar = "ttt2_undecided_time_between_ballots",
			label = "label_undecided_time_between_ballots",
			min = 0,
			max = 240,
			decimal = 0,
		})

		form:MakeComboBox({
			serverConvar = "ttt2_undecided_no_vote_punishment_mode",
			label = "label_undecided_no_vote_punishment_mode",
			choices = {{
				value = 0,
				title = LANG.GetTranslation("label_undecided_no_vote_punishment_mode_0")
			},{
				value = 1,
				title = LANG.GetTranslation("label_undecided_no_vote_punishment_mode_1")
			},{
				value = 2,
				title = LANG.GetTranslation("label_undecided_no_vote_punishment_mode_2")
			},{
				value = 3,
				title = LANG.GetTranslation("label_undecided_no_vote_punishment_mode_3")
			}}
		})

		form:MakeSlider({
			serverConvar = "ttt2_undecided_weight_innocent",
			label = "label_undecided_weight_innocent",
			min = 0,
			max = 100,
			decimal = 0,
		})

		form:MakeSlider({
			serverConvar = "ttt2_undecided_weight_detective",
			label = "label_undecided_weight_detective",
			min = 0,
			max = 100,
			decimal = 0,
		})

		form:MakeSlider({
			serverConvar = "ttt2_undecided_weight_traitor",
			label = "label_undecided_weight_traitor",
			min = 0,
			max = 100,
			decimal = 0,
		})

		form:MakeSlider({
			serverConvar = "ttt2_undecided_weight_evil",
			label = "label_undecided_weight_evil",
			min = 0,
			max = 100,
			decimal = 0,
		})

		form:MakeSlider({
			serverConvar = "ttt2_undecided_weight_neutral",
			label = "label_undecided_weight_neutral",
			min = 0,
			max = 100,
			decimal = 0,
		})

		form:MakeCheckBox({
			serverConvar = "ttt2_undecided_can_vote_for_self",
			label = "label_undecided_can_vote_for_self"
		})

		form:MakeComboBox({
			serverConvar = "ttt2_undecided_role_enable_mode",
			label = "label_undecided_role_enable_mode",
			choices = {{
				value = 0,
				title = LANG.GetTranslation("label_undecided_role_enable_mode_0")
			},{
				value = 1,
				title = LANG.GetTranslation("label_undecided_role_enable_mode_1")
			},{
				value = 2,
				title = LANG.GetTranslation("label_undecided_role_enable_mode_2")
			}}
		})
	end
end
