AddCSLuaFile("shared.lua")
include('shared.lua')
/*-----------------------------------------------
	*** Copyright (c) 2012-2021 by DrVrej, All rights reserved. ***
	No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
	without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
-----------------------------------------------*/
ENT.Model = {"models/vj_hlr/hl1/alien_cannon.mdl"} -- The game will pick a random model from the table when the SNPC is spawned | Add as many as you want
ENT.StartHealth = 100
ENT.HullType = HULL_WIDE_SHORT
ENT.SightDistance = 6000 -- How far it can see
ENT.SightAngle = 180 -- The sight angle | Example: 180 would make the it see all around it | Measured in degrees and then converted to radians
ENT.MovementType = VJ_MOVETYPE_STATIONARY -- How does the SNPC move?
ENT.CanTurnWhileStationary = false -- If set to true, the SNPC will be able to turn while it's a stationary SNPC
ENT.VJC_Data = {
    ThirdP_Offset = Vector(0, 0, 0), -- The offset for the controller when the camera is in third person
    FirstP_Bone = "joint3", -- If left empty, the base will attempt to calculate a position for first person
    FirstP_Offset = Vector(0, 0, 50), -- The offset for the controller when the camera is in first person
	FirstP_ShrinkBone = false, -- Should the bone shrink? Useful if the bone is obscuring the player's view
}
---------------------------------------------------------------------------------------------------------------------------------------------
ENT.VJ_NPC_Class = {"CLASS_XEN"} -- NPCs with the same class with be allied to each other
ENT.HasMeleeAttack = false -- Should the SNPC have a melee attack?

ENT.HasRangeAttack = true -- Should the SNPC have a range attack?
ENT.DisableDefaultRangeAttackCode = true -- When true, it won't spawn the range attack entity, allowing you to make your own
ENT.DisableRangeAttackAnimation = true -- if true, it will disable the animation code
ENT.RangeDistance = 6000 -- This is how far away it can shoot
ENT.RangeToMeleeDistance = 170 -- How close does it have to be until it uses melee?
ENT.RangeAttackAngleRadius = 180 -- What is the attack angle radius? | 100 = In front of the SNPC | 180 = All around the SNPC
ENT.TimeUntilRangeAttackProjectileRelease = 0 -- How much time until the projectile code is ran?
ENT.NextRangeAttackTime = 0.5 -- How much time until it can use a range attack?

ENT.Medic_CanBeHealed = false -- If set to false, this SNPC can't be healed!
ENT.PoseParameterLooking_InvertPitch = true -- Inverts the pitch poseparameters (X)
ENT.PoseParameterLooking_InvertYaw = true -- Inverts the yaw poseparameters (Y)
ENT.Immune_AcidPoisonRadiation = true -- Immune to Acid, Poison and Radiation
ENT.Immune_Bullet = true -- Immune to bullet type damages
ENT.Immune_Melee = true -- Immune to melee-type damage | Example: Crowbar, slash damages
ENT.Immune_Physics = true -- Immune to physics impacts, won't take damage from props
ENT.GetDamageFromIsHugeMonster = true -- Should it get damaged no matter what by SNPCs that are tagged as VJ_IsHugeMonster?
ENT.DeathCorpseModel = {"models/vj_hlr/hl1/alien_cannon_bottom.mdl"} -- The corpse model that it will spawn when it dies | Leave empty to use the NPC's model | Put as many models as desired, the base will pick a random one.
ENT.GibOnDeathDamagesTable = {"All"} -- Damages that it gibs from | "UseDefault" = Uses default damage types | "All" = Gib from any damage
	-- ====== Sound File Paths ====== --
-- Leave blank if you don't want any sounds to play
ENT.SoundTbl_Breath = {"vj_hlr/hl1_npc/xencannon/alien_powernode.wav"}
ENT.SoundTbl_Impact = {"ambient/energy/spark1.wav","ambient/energy/spark2.wav","ambient/energy/spark3.wav","ambient/energy/spark4.wav"}
ENT.SoundTbl_Death = {"vj_hlr/hl1_npc/xencannon/bustconcrete1.wav","vj_hlr/hl1_npc/xencannon/bustconcrete2.wav"}

ENT.BreathSoundLevel = 70
ENT.DeathSoundLevel = 90

-- Custom
ENT.Cannon_HasLOS = false
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:CustomOnInitialize()
	self:SetCollisionBounds(Vector(45,45,65), Vector(-45,-45,0))
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:CustomOnAcceptInput(key, activator, caller, data)
	//print(key)
	if key == "shoot" then
		self:RangeAttackCode()
	end
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:CustomOn_PoseParameterLookingCode(pitch, yaw, roll)
	-- Compare the difference between the current position of the pose parameter and the position it's suppose to go to
	if (math.abs(math.AngleDifference(self:GetPoseParameter("aim_yaw"), math.ApproachAngle(self:GetPoseParameter("aim_yaw"), yaw, self.PoseParameterLooking_TurningSpeed))) >= 10) or (math.abs(math.AngleDifference(self:GetPoseParameter("aim_pitch"), math.ApproachAngle(self:GetPoseParameter("aim_pitch"), pitch, self.PoseParameterLooking_TurningSpeed))) >= 10) then
		self.Cannon_HasLOS = false
	else
		self.Cannon_HasLOS = true
	end
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:CustomAttackCheck_RangeAttack()
	if self.Cannon_HasLOS == true then return true end
end
local laserdmg = 50
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:CustomRangeAttackCode()
	local startpos = self:GetAttachment(1).Pos
	local tr = util.TraceLine({
		start = startpos,
		endpos = self:GetEnemy():GetPos() + self:GetEnemy():OBBCenter() + VectorRand(-15, 15),
		filter = {self} // self.extmdl
	})
	local hitpos = tr.HitPos
	local elec = EffectData()
	elec:SetStart(startpos)
	elec:SetOrigin(hitpos)
	elec:SetEntity(self)
	elec:SetAttachment(1)
	util.Effect("VJ_HLR_XenCannon_Beam", elec)
	util.VJ_SphereDamage(self, self, hitpos, 30, laserdmg, DMG_ENERGYBEAM, true, false, {Force=90})
	VJ_EmitSound(self, "vj_hlr/hl1_npc/xencannon/fire.wav", 90, 100)
	sound.Play("vj_hlr/hl1_npc/pitworm/pit_worm_attack_eyeblast_impact.wav", hitpos, 60)
	
	local StartGlow1 = ents.Create("env_sprite")
	StartGlow1:SetKeyValue("model","vj_hl/sprites/flare3.vmt")
	StartGlow1:SetKeyValue("rendercolor","0 0 255")
	StartGlow1:SetKeyValue("GlowProxySize","5.0")
	StartGlow1:SetKeyValue("HDRColorScale","1.0")
	StartGlow1:SetKeyValue("renderfx","14")
	StartGlow1:SetKeyValue("rendermode","3")
	StartGlow1:SetKeyValue("renderamt","255")
	StartGlow1:SetKeyValue("disablereceiveshadows","0")
	StartGlow1:SetKeyValue("mindxlevel","0")
	StartGlow1:SetKeyValue("maxdxlevel","0")
	StartGlow1:SetKeyValue("framerate","10.0")
	StartGlow1:SetKeyValue("spawnflags","0")
	StartGlow1:SetKeyValue("scale","5")
	StartGlow1:SetPos(self:GetPos())
	StartGlow1:Spawn()
	StartGlow1:SetParent(self)
	StartGlow1:Fire("SetParentAttachment", "Cannon")
	self:DeleteOnRemove(StartGlow1)
	timer.Simple(0.1, function() SafeRemoveEntity(StartGlow1) end)
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:CustomOnTakeDamage_BeforeDamage(dmginfo, hitgroup)
	if dmginfo:GetDamagePosition() != vec then
		local rico = EffectData()
		rico:SetOrigin(dmginfo:GetDamagePosition())
		rico:SetScale(4) -- Size
		rico:SetMagnitude(2) -- Effect type | 1 = Animated | 2 = Basic
		util.Effect("VJ_HLR_Rico",rico)
	end
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:CustomOnKilled(dmginfo, hitgroup)
	local spr = ents.Create("env_sprite")
	spr:SetKeyValue("model","vj_hl/sprites/zerogxplode.vmt")
	spr:SetKeyValue("GlowProxySize","2.0")
	spr:SetKeyValue("HDRColorScale","1.0")
	spr:SetKeyValue("renderfx","14")
	spr:SetKeyValue("rendermode","5")
	spr:SetKeyValue("renderamt","255")
	spr:SetKeyValue("disablereceiveshadows","0")
	spr:SetKeyValue("mindxlevel","0")
	spr:SetKeyValue("maxdxlevel","0")
	spr:SetKeyValue("framerate","15.0")
	spr:SetKeyValue("spawnflags","0")
	spr:SetKeyValue("scale","3")
	spr:SetPos(self:GetPos() + self:GetUp()*20)
	spr:Spawn()
	spr:Fire("Kill", "", 0.9)
	timer.Simple(0.9, function() if IsValid(spr) then spr:Remove() end end)
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:CustomOnDeath_AfterCorpseSpawned(dmginfo, hitgroup, corpseEnt)
	ParticleEffectAttach("smoke_exhaust_01a", PATTACH_ABSORIGIN_FOLLOW, corpseEnt, 0)
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:SetUpGibesOnDeath(dmginfo, hitgroup)
	self:CreateGibEntity("obj_vj_gib","models/vj_hlr/gibs/metalgibs_sub1.mdl",{BloodDecal="",Pos=self:LocalToWorld(Vector(0,0,20)),CollideSound={"vj_hlr/fx/metal1.wav","vj_hlr/fx/metal2.wav","vj_hlr/fx/metal3.wav","vj_hlr/fx/metal4.wav","vj_hlr/fx/metal5.wav"}})
	self:CreateGibEntity("obj_vj_gib","models/vj_hlr/gibs/metalgibs_sub2.mdl",{BloodDecal="",Pos=self:LocalToWorld(Vector(0,0,20)),CollideSound={"vj_hlr/fx/metal1.wav","vj_hlr/fx/metal2.wav","vj_hlr/fx/metal3.wav","vj_hlr/fx/metal4.wav","vj_hlr/fx/metal5.wav"}})
	self:CreateGibEntity("obj_vj_gib","models/vj_hlr/gibs/metalgibs_sub3.mdl",{BloodDecal="",Pos=self:LocalToWorld(Vector(0,0,20)),CollideSound={"vj_hlr/fx/metal1.wav","vj_hlr/fx/metal2.wav","vj_hlr/fx/metal3.wav","vj_hlr/fx/metal4.wav","vj_hlr/fx/metal5.wav"}})
	self:CreateGibEntity("obj_vj_gib","models/vj_hlr/gibs/metalgibs_sub4.mdl",{BloodDecal="",Pos=self:LocalToWorld(Vector(0,0,20)),CollideSound={"vj_hlr/fx/metal1.wav","vj_hlr/fx/metal2.wav","vj_hlr/fx/metal3.wav","vj_hlr/fx/metal4.wav","vj_hlr/fx/metal5.wav"}})
	self:CreateGibEntity("obj_vj_gib","models/vj_hlr/gibs/metalgibs_sub5.mdl",{BloodDecal="",Pos=self:LocalToWorld(Vector(0,0,20)),CollideSound={"vj_hlr/fx/metal1.wav","vj_hlr/fx/metal2.wav","vj_hlr/fx/metal3.wav","vj_hlr/fx/metal4.wav","vj_hlr/fx/metal5.wav"}})
	self:CreateGibEntity("obj_vj_gib","models/vj_hlr/gibs/metalgibs_sub1.mdl",{BloodDecal="",Pos=self:LocalToWorld(Vector(0,0,20)),CollideSound={"vj_hlr/fx/metal1.wav","vj_hlr/fx/metal2.wav","vj_hlr/fx/metal3.wav","vj_hlr/fx/metal4.wav","vj_hlr/fx/metal5.wav"}})
	self:CreateGibEntity("obj_vj_gib","models/vj_hlr/gibs/metalgibs_sub2.mdl",{BloodDecal="",Pos=self:LocalToWorld(Vector(0,0,20)),CollideSound={"vj_hlr/fx/metal1.wav","vj_hlr/fx/metal2.wav","vj_hlr/fx/metal3.wav","vj_hlr/fx/metal4.wav","vj_hlr/fx/metal5.wav"}})
	self:CreateGibEntity("obj_vj_gib","models/vj_hlr/gibs/metalgibs_sub3.mdl",{BloodDecal="",Pos=self:LocalToWorld(Vector(0,0,20)),CollideSound={"vj_hlr/fx/metal1.wav","vj_hlr/fx/metal2.wav","vj_hlr/fx/metal3.wav","vj_hlr/fx/metal4.wav","vj_hlr/fx/metal5.wav"}})
	self:CreateGibEntity("obj_vj_gib","models/vj_hlr/gibs/metalgibs_sub4.mdl",{BloodDecal="",Pos=self:LocalToWorld(Vector(0,0,20)),CollideSound={"vj_hlr/fx/metal1.wav","vj_hlr/fx/metal2.wav","vj_hlr/fx/metal3.wav","vj_hlr/fx/metal4.wav","vj_hlr/fx/metal5.wav"}})
	self:CreateGibEntity("obj_vj_gib","models/vj_hlr/gibs/metalgibs_sub5.mdl",{BloodDecal="",Pos=self:LocalToWorld(Vector(0,0,20)),CollideSound={"vj_hlr/fx/metal1.wav","vj_hlr/fx/metal2.wav","vj_hlr/fx/metal3.wav","vj_hlr/fx/metal4.wav","vj_hlr/fx/metal5.wav"}})
	return true, {AllowCorpse=true}
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:CustomGibOnDeathSounds(dmginfo, hitgroup)
	VJ_EmitSound(self, "vj_hlr/hl1_weapon/explosion/debris3.wav", 150, math.random(100,100))
	return false
end
/*-----------------------------------------------
	*** Copyright (c) 2012-2021 by DrVrej, All rights reserved. ***
	No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
	without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
-----------------------------------------------*/