local L = LANG.GetLanguageTableReference("en")

-- GENERAL ROLE LANGUAGE STRINGS
L[UNDECIDED.name] = "Undecided"
L["info_popup_" .. UNDECIDED.name] = [[You are Undecided. You may choose your role from a limited selection.

Failure to vote shall lead to Consequences.]]
L["body_found_" .. UNDECIDED.abbr] = "They were Undecided."
L["search_role_" .. UNDECIDED.abbr] = "This person was Undecided!"
L["target_" .. UNDECIDED.name] = "Undecided"
L["ttt2_desc_" .. UNDECIDED.name] = [[You are Undecided. You may choose your role from a limited selection.

Failure to vote shall lead to Consequences.]]

-- OTHER ROLE LANGUAGE STRINGS
L["BALLOT_TITLE_" .. UNDECIDED.name] = "Choose Your Role"
L["CONSEQUENCES_" .. UNDECIDED.name] = "YOU HAVE FAILED TO VOTE AND NOW MUST SUFFER THE CONSEQUENCES."
L["BAD_BALLOT_" .. UNDECIDED.name] = "Bad ballot! Please yell at the admin for their blatant disenfranchisement."
L["INVALID_RESPONSE_" .. UNDECIDED.name] = "Invalid response to the ballot! Received an id of '{i}', which is not in range of 1 and {n}."
L["BAD_ROLE_" .. UNDECIDED.name] = "{role} wasn't supposed to be on the ballot at all! Report this to your admin. In the meantime, here's a new ballot."

-- EVENT STRINGS
-- Need to be very specifically worded, due to how the system translates them.
L["title_event_undec_vote"] = "An Undecided player voted"
L["desc_event_undec_vote"] = "{name} voted to become: {role}."
L["tooltip_undec_vote_score"] = "Voted: {score}"
L["undec_vote_score"] = "Voted:"
L["title_event_undec_abstain"] = "An Undecided player abstained from voting"
L["desc_event_undec_abstain"] = "{name} abstained from voting."
L["tooltip_undec_abstain_score"] = "Abstention: {score}"
L["undec_abstain_score"] = "Abstention:"

-- CONVAR STRINGS
L["label_undecided_num_choices"] = "# choices Undecided has to choose from"
L["label_undecided_ballot_timer"] = "Time Undecided has to vote"
L["label_undecided_time_between_ballots"] = "If > 0, time until another ballot is given"
L["label_undecided_no_vote_punishment_mode"] = "If the Undecided fails to vote:"
L["label_undecided_no_vote_punishment_mode_0"] = "0: D E A T H   P E N A L T Y"
L["label_undecided_no_vote_punishment_mode_1"] = "1: Randomly assigned a role"
L["label_undecided_no_vote_punishment_mode_2"] = "2: Become an Innocent"
L["label_undecided_no_vote_punishment_mode_3"] = "3: Become a Jester"
L["label_undecided_weight_innocent"] = "Prob. of an Innocent role appearing"
L["label_undecided_weight_detective"] = "Prob. of a Detective role appearing"
L["label_undecided_weight_traitor"] = "Prob. of a Traitor role appearing"
L["label_undecided_weight_evil"] = "Prob. of an evil role appearing"
L["label_undecided_weight_neutral"] = "Prob. of a neutral role appearing"
L["label_undecided_can_vote_for_self"] = "The Undecided can vote for Undecided"
L["label_undecided_role_enable_mode"] = "A role can be voted on if it's:"
L["label_undecided_role_enable_mode_0"] = "0: Enabled in the server"
L["label_undecided_role_enable_mode_1"] = "1: Disabled in the server"
L["label_undecided_role_enable_mode_2"] = "2: Either enabled or disabled"