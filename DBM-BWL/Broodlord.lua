local mod	= DBM:NewMod("Broodlord", "DBM-BWL", 1)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20240204192134")
mod:SetCreatureID(12017)

mod:SetModelID(14308)
mod:RegisterCombat("yell", L.Pull)--L.Pull is backup for classic, since classic probably won't have ENCOUNTER_START to rely on and player regen never works for this boss

mod:RegisterEventsInCombat(
	"SPELL_CAST_SUCCESS 23331 18670 25778",
	"SPELL_AURA_APPLIED 24573",
	"SPELL_AURA_REMOVED 24573"
)

--Mortal Strike: 10-20, Blast Wave: 12-32, Knock Away: 13-30. i.e., timers on this fight would be near useless
--(ability.id = 18670 or ability.id = 23331 or ability.id = 24573) and type = "cast"
local warnBlastWave		= mod:NewSpellAnnounce(23331, 2)
local warnKnockAway		= mod:NewSpellAnnounce(18670, 3)
local warnMortal		= mod:NewTargetNoFilterAnnounce(24573, 2, nil, "Tank|Healer", 4)

local timerBlastWaveCD	= mod:NewCDTimer(8.2, 23331, nil, nil, nil, 2, nil, nil, true) -- ~4s variance [8.20-12.53]. Added "keep" arg. (25m Onyxia [2024-02-03]@[22:41:24]) - "Blast Wave-23331-npc:12017-135 = pull:28.34, 11.30, 10.76, 8.39, 9.12, 8.20, 12.53, 10.57, 10.51, 12.82, 12.24, 8.67, 12.19"
local timerKnockAwayCD	= mod:NewCDTimer(21.68, 18670, nil, nil, nil, 3, nil, nil, true) -- ~13s variance [21.68-34.93]. Added "keep" arg. (25m Onyxia [2024-02-03]@[22:41:24]) - "Knock Away-25778-npc:12017-135 = pull:26.83, 24.87, 21.68, 28.09, 24.92, 34.93"
local timerMortal		= mod:NewTargetTimer(5, 24573, nil, "Tank|Healer", 4, 5, nil, DBM_COMMON_L.TANK_ICON)

function mod:OnCombatStart(delay)
	timerBlastWaveCD:Start(28.34-delay)
	timerKnockAwayCD:Start(26.83-delay)
end

function mod:SPELL_CAST_SUCCESS(args)
	if args.spellId == 23331 and args:IsSrcTypeHostile() then
		warnBlastWave:Show()
		timerBlastWaveCD:Start()
	elseif args.spellId == 18670 or args.spellId == 25778 then -- 02/02/2024: on Warmane it's using wrong id - https://www.warmane.com/bugtracker/report/120897
		warnKnockAway:Show()
		timerKnockAwayCD:Start()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args.spellId == 24573 and args:IsDestTypePlayer() then
		warnMortal:Show(args.destName)
		timerMortal:Start(args.destName)
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args.spellId == 24573 and args:IsDestTypePlayer() then
		timerMortal:Stop(args.destName)
	end
end
