if SERVER then
    AddCSLuaFile()

    resource.AddFile("materials/vgui/ttt/vskin/events/undec_vote.vmt")
end

if CLIENT then
	EVENT.title = "title_event_undec_vote"
	EVENT.icon = Material("vgui/ttt/vskin/events/undec_vote.vmt")
	
	function EVENT:GetText()
		return {
			{
				string = "desc_event_undec_vote",
				params = {
					name = self.event.undec_name,
					role = self.event.role_str
				},
				translateParams = true
			}
		}
    end
end

if SERVER then
	function EVENT:Trigger(undec, role)
		self:AddAffectedPlayers(
			{undec:SteamID64()},
			{undec:GetName()}
		)
		
		local role_data = roles.GetByIndex(role)

		return self:Add({
			serialname = self.event.title,
			undec_id = undec:SteamID64(),
			undec_name = undec:GetName(),
			has_voted = undec.undec_has_voted,
			role_str = role_data.name
		})
	end
	
	function EVENT:CalculateScore()
		--Only give the player a point once, to prevent lucky players who keep choosing "undecided" from making too many points.
		if not self.event.has_voted then
			self:SetPlayerScore(self.event.undec_id, {
				score = 1
			})
		end
	end
	
	function EVENT:Serialize()
		return self.event.serialname
	end
end