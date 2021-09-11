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