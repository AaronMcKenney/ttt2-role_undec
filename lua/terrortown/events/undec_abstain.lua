if SERVER then
    AddCSLuaFile()

    resource.AddFile("materials/vgui/ttt/vskin/events/undec_abstain.vmt")
end

if CLIENT then
	EVENT.title = "title_event_undec_abstain"
	EVENT.icon = Material("vgui/ttt/vskin/events/undec_abstain.vmt")
	
	function EVENT:GetText()
		return {
			{
				string = "desc_event_undec_abstain",
				params = {
					name = self.event.undec_name
				},
				translateParams = true
			}
		}
    end
end

if SERVER then
	function EVENT:Trigger(undec)
		self:AddAffectedPlayers(
			{undec:SteamID64()},
			{undec:GetName()}
		)
		
		return self:Add({
			serialname = self.event.title,
			undec_name = undec:GetName(),
			undec_id = undec:SteamID64()
		})
	end
	
	function EVENT:CalculateScore()
		self:SetPlayerScore(self.event.undec_id, {
			score = -1
		})
	end
	
	function EVENT:Serialize()
		return self.event.serialname
	end
end