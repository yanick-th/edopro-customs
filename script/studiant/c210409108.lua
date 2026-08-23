--Studiant Takanashi Hoshino
--Script by yanick-th
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	--Xyz Summon procedure
	Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsRace,RACE_FAIRY),5,3,s.ovfilter,aux.Stringid(id,0),3,s.xyzop)
	--Your opponent cannot target Fairy monsters you control with effects, except "Studiant Takanashi Hoshino".
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e1:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(s.imtg)
	e1:SetValue(aux.tgoval)
	c:RegisterEffect(e1)
	--Battle Limit
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_SELECT_BATTLE_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(0,LOCATION_MZONE)
	e2:SetValue(function(e,c) return not c:IsCode(id) and c:IsRace(RACE_FAIRY) end)
	c:RegisterEffect(e2)
	--Target this card or 1 face-up monster your opponent controls; Gain DEF or lose ATK/DEF and negate
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_CARD_TARGET)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E|TIMING_MAIN_END|TIMING_DAMAGE_STEP)
	e3:SetCost(Cost.DetachFromSelf(1,99,function(e,og) e:SetLabel(#og) end))
	e3:SetCountLimit(1,id)
	e3:SetTarget(s.natg)
	e3:SetOperation(s.naop)
	c:RegisterEffect(e3)
	
end

s.listed_series={0x45e}
s.listed_names={id}

function s.ovfilter(c,tp,lc)
	return c:IsFaceup() and c:IsRank(3) and c:IsSetCard(0x45e,lc,SUMMON_TYPE_XYZ,tp)
		and c:IsType(TYPE_XYZ,lc,SUMMON_TYPE_XYZ,tp)
end

function s.xyzop(e,tp,chk)
	if chk==0 then return Duel.GetFlagEffect(tp,id)==0 end
	Duel.RegisterFlagEffect(tp,id,RESET_PHASE|PHASE_END,0,1)
	return true
end

function s.imtg(e,c)
	return not c:IsCode(id) and c:IsRace(RACE_FAIRY)
end

function s.natg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and s.tgfieldfilter(chkc,e,tp) end
	if chk==0 then return Duel.IsExistingTarget(s.tgfieldfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil,e,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local tc=Duel.SelectTarget(tp,s.tgfieldfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil,e,tp):GetFirst()
	if tc==e:GetHandler() then
		e:SetCategory(CATEGORY_DEFCHANGE)
	else
		e:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DEFCHANGE)
		if Card.IsNegatableMonster(tc) then
			Duel.SetOperationInfo(0,CATEGORY_DISABLE,tc,1,0,0)
		end
	end
end
function s.tgfieldfilter(c,e,tp)
	return c==e:GetHandler() or (c:IsFaceup() and c:IsControler(1-tp))
end

function s.naop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
    local tc=Duel.GetFirstTarget()
    if not tc:IsFaceup() or not tc:IsRelateToEffect(e) then return end

	if tc==e:GetHandler() then
		--Increase DEF
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_DEFENSE)
	    e1:SetReset(RESETS_STANDARD_PHASE_END,2)
		e1:SetValue(300*e:GetLabel())
		tc:RegisterEffect(e1)
	else
		--Decrease ATK/DEF and negate
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
        e1:SetReset(RESETS_STANDARD_PHASE_END)
		e1:SetValue(-300*e:GetLabel())
		tc:RegisterEffect(e1)
        local e2=e1:Clone()
		e2:SetCode(EFFECT_UPDATE_DEFENSE)
		tc:RegisterEffect(e2)

		if tc:IsCanBeDisabledByEffect(e) then
			Duel.NegateRelatedChain(tc,RESET_TURN_SET)
			--Negate its effects
			local e3=Effect.CreateEffect(c)
			e3:SetType(EFFECT_TYPE_SINGLE)
			e3:SetCode(EFFECT_DISABLE)
			e3:SetReset(RESETS_STANDARD_PHASE_END)
			tc:RegisterEffect(e3)
			local e4=Effect.CreateEffect(c)
			e4:SetType(EFFECT_TYPE_SINGLE)
			e4:SetCode(EFFECT_DISABLE_EFFECT)
			e4:SetValue(RESET_TURN_SET)
			e4:SetReset(RESETS_STANDARD_PHASE_END)
			tc:RegisterEffect(e4)
		end
    end
end
