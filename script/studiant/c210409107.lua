--Studiant Sorasaki Hina
--Script by yanick-th
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	--Xyz Summon procedure
	Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsRace,RACE_FAIRY),5,3,s.ovfilter,aux.Stringid(id,2),3,s.xyzop)
	--Change ATK and allow multiple attacks
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_ATKCHANGE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetProperty(EFFECT_FLAG_DAMAGE_STEP)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCost(Cost.DetachFromSelf(1,99,function(e,og) e:SetLabel(#og) end))
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E|TIMING_MAIN_END|TIMING_DAMAGE_STEP)
	e1:SetCountLimit(1,id)
	e1:SetOperation(s.desop)
	c:RegisterEffect(e1)
	-- Add to hand or attach
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DELAY+EFFECT_FLAG_DAMAGE_STEP)
	e2:SetCode(EVENT_CUSTOM+id)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.gythtg)
	e2:SetOperation(s.gythop)
	c:RegisterEffect(e2)
	local g=Group.CreateGroup()
	g:KeepAlive()
	e2:SetLabelObject(g)
	--Keep track of a Fairy monsters or "Studiant" cards sent to the GY
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetLabelObject(e2)
	e3:SetOperation(s.regop)
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

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsFaceup() and c:IsRelateToEffect(e) then
		--Increase ATK
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(300*e:GetLabel())
		e1:SetReset(RESETS_STANDARD_DISABLE_PHASE_END)
		c:RegisterEffect(e1)
		--Can attack all your opponent's monsters, once each
		local e2=Effect.CreateEffect(e:GetHandler())
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_ATTACK_ALL)
		e2:SetValue(1)
		e2:SetReset(RESETS_STANDARD_DISABLE_PHASE_END)
		c:RegisterEffect(e2)
	end
end

function s.gythfilter(c,e,tp)
	return c:IsCanBeEffectTarget(e) and c:IsLocation(LOCATION_GRAVE) and c:IsControler(tp)
		and (c:IsSetCard(0x45e) or (c:IsRace(RACE_FAIRY) and c:IsMonster()))
		and (c:IsAbleToHand() or Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_MZONE,0,1,nil,tp,c))
end
function s.xyzfilter(c,tp,tg)
	return c:IsFaceup() and c:IsSetCard(0x45e) and c:IsType(TYPE_XYZ)
		and tg:IsCanBeXyzMaterial(c,tp,REASON_EFFECT)
end

function s.gythtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local g=e:GetLabelObject():Filter(s.gythfilter,nil,e,tp)
	if chkc then return g:IsContains(chkc) and s.gythfilter(chkc,e,tp) end
	if chk==0 then return #g>0 end
	local tc=nil
	if #g>1 then
		Duel.Hint(HINT_SELECTMSG,tp,e:GetDescription())
		tc=g:Select(tp,1,1,nil):GetFirst()
	else
		tc=g:GetFirst()
	end
	Duel.SetTargetCard(tc)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,tc,1,tp,0)
end

function s.gythop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
    if not tc:IsRelateToEffect(e) then return end

	aux.ToHandOrElse(tc,tp,
		function() return Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_MZONE,0,1,nil,tp,tc) end,
		function()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
			local oc=Duel.SelectMatchingCard(tp,s.xyzfilter,tp,LOCATION_MZONE,0,1,1,nil,tp,tc):GetFirst()
			if oc then
				Duel.HintSelection(oc,true)
				Duel.Overlay(oc,tc)
			end
		end,
		aux.Stringid(id,3)
	)
end

function s.regop(e,tp,eg,ep,ev,re,r,rp)
	local tg=eg:Filter(s.gythfilter,nil,e,tp)
	if #tg>0 then
		for tc in tg:Iter() do
			tc:RegisterFlagEffect(id,RESET_CHAIN,0,1)
		end
		local g=e:GetLabelObject():GetLabelObject()
		if Duel.GetCurrentChain()==0 then g:Clear() end
		g:Merge(tg)
		g:Remove(function(c) return c:GetFlagEffect(id)==0 end,nil)
		e:GetLabelObject():SetLabelObject(g)
		Duel.RaiseSingleEvent(e:GetHandler(),EVENT_CUSTOM+id,e,0,tp,tp,0)
	end
end
