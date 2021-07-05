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
