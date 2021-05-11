AddCSLuaFile("shared.lua")
include('shared.lua')
/*--------------------------------------------------
	*** Copyright (c) 2012-2020 by DrVrej, All rights reserved. ***
	No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
	without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
--------------------------------------------------*/
ENT.CanQuitController = true -- Can the user exit the controller?
ENT.User_CanRespawn = true -- If set to false, the user will die when the NPC dies
ENT.LastPressedKey = BUTTON_CODE_NONE -- The last button the user pressed
ENT.LastPressedKeyTime = 0 -- Time since the user last pressed a key
ENT.CrosshairTrackingActivated = false

-- Control values --
ENT.VJNPC_Values = nil -- A hash table to hold all the values that need to be reset after the NPC is uncontrolled
ENT.AbleToTurn = true
ENT.CurrentAttackAnimation = 0
ENT.LastIdleAngle = 0
ENT.ZoomLevelOriginalZ = 0
ENT.VJControllerEntityIsRemoved = false

util.AddNetworkString("vj_controller_hud")
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:CustomOnInitialize() end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:CustomOnSetControlledNPC() end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:CustomOnThink() end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:CustomOnKeyPressed(key) end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:CustomOnStopControlling() end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:CustomOnRemove() end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:Initialize()
	self:SetModel("models/props_junk/watermelon01_chunk02c.mdl")
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_NONE)
	//self:StartControlling()
	self:CustomOnInitialize()
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:StartControlling()
	//self.TheController = self:GetOwner()
	//if (self.TheController) then return end
	//print(self.TheController)
	self.TheController.IsControlingNPC = true
	self.TheController.VJ_TheControllerEntity = self

	self.PropCamera = ents.Create("prop_dynamic")
	self.PropCamera:SetPos(self.ControlledNPC:GetPos() + Vector(0,0,self.ControlledNPC:OBBMaxs().z +20)) //self.ControlledNPC:EyePos()
	self.PropCamera:SetModel("models/props_junk/watermelon01_chunk02c.mdl")
	self.PropCamera:SetParent(self.ControlledNPC)
	self.PropCamera:SetRenderMode(RENDERMODE_NONE)
	self.PropCamera:Spawn()
	self.PropCamera:SetColor(Color(0,0,0,0))
	self.PropCamera:SetNoDraw(false)
	self.PropCamera:DrawShadow(false)
	self:DeleteOnRemove(self.PropCamera)

	self.TheController:Spectate(OBS_MODE_CHASE)
	//self.TheController:SetPos(self.PropCamera:GetPos())
	self.TheController:SpectateEntity(self.PropCamera)
	self.TheController:SetNoTarget(true)
	self.TheController:DrawShadow(false)
	self.TheController:SetNoDraw(true)
	self.TheController:SetMoveType(MOVETYPE_OBSERVER)
	self.TheController:DrawViewModel(false)
	self.TheController:DrawWorldModel(false)
	self.ControllerHealth = self.TheController:Health()
	self.ControllerArmor = self.TheController:Armor()
	if (IsValid(self.TheController:GetActiveWeapon())) then
	self.ControllerActiveWeapon = self.TheController:GetActiveWeapon():GetClass() end
	self.ControllerCurrentWeapons = {}
	for _, v in pairs(self.TheController:GetWeapons()) do
	table.insert(self.ControllerCurrentWeapons,v:GetClass()) end
	self.TheController:StripWeapons()
	
	self.ZoomLevelOriginalZ = self.PropCamera:GetLocalPos()
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:SetControlledNPC(GetEntity)
	-- Set the bullseye entity values
	self.NPCBullseye = ents.Create("obj_vj_bullseye")
	self.NPCBullseye:SetPos(GetEntity:GetPos() + GetEntity:GetForward()*100 + GetEntity:GetUp()*50)//Vector(GetEntity:OBBMaxs().x +20,0,GetEntity:OBBMaxs().z +20))
	self.NPCBullseye:SetModel("models/hunter/blocks/cube025x025x025.mdl")
	//self.NPCBullseye:SetParent(GetEntity)
	self.NPCBullseye:SetRenderMode(RENDERMODE_NONE)
	self.NPCBullseye:Spawn()
	self.NPCBullseye:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
	self.NPCBullseye.EnemyToIndividual = true
	self.NPCBullseye.EnemyToIndividualEnt = GetEntity
	self.NPCBullseye:SetColor(Color(0,0,0,0))
	self.NPCBullseye:SetNoDraw(false)
	self.NPCBullseye:DrawShadow(false)
	self:DeleteOnRemove(self.NPCBullseye)

	-- Set the NPC values
	self.ControlledNPC = GetEntity
	self.ControlledNPC.VJ_IsBeingControlled = true
	self.ControlledNPC.VJ_TheController = self.TheController
	self.ControlledNPC.VJ_TheControllerEntity = self
	self.ControlledNPC.VJ_TheControllerBullseye = self.NPCBullseye
	self.ControlledNPC:SetEnemy(NULL)
	self.ControlledNPC.Enemy = NULL
	self.ControlledNPC:VJ_Controller_InitialMessage(self.TheController)
	if self.ControlledNPC.IsVJBaseSNPC == true then
		self.ControlledNPC:Controller_Initialize(self.TheController)
		if IsValid(self.ControlledNPC:GetEnemy()) then
			self.ControlledNPC:AddEntityRelationship(self.ControlledNPC:GetEnemy(), D_NU, 99)
			self.ControlledNPC:GetEnemy():AddEntityRelationship(self.ControlledNPC, D_NU, 99)
			self.ControlledNPC:ResetEnemy(false)
			self.ControlledNPC:SetEnemy(self.NPCBullseye)
		end
		self.VJNPC_Values = {
			[1] = self.ControlledNPC.DisableWandering,
			[2] = self.ControlledNPC.DisableChasingEnemy,
			[3] = self.ControlledNPC.DisableTakeDamageFindEnemy,
			[4] = self.ControlledNPC.DisableTouchFindEnemy,
			[5] = self.ControlledNPC.DisableSelectSchedule,
			[6] = self.ControlledNPC.CallForHelp,
			[7] = self.ControlledNPC.CallForBackUpOnDamage,
			[8] = self.ControlledNPC.BringFriendsOnDeath,
			[9] = self.ControlledNPC.FollowPlayer,
			[10] = self.ControlledNPC.CanDetectGrenades,
			[11] = self.ControlledNPC.Passive_RunOnTouch,
			[12] = self.ControlledNPC.Passive_RunOnDamage,
			[13] = self.ControlledNPC.IsGuard,
		}
		self.ControlledNPC.DisableWandering = true
		self.ControlledNPC.DisableChasingEnemy = true
		self.ControlledNPC.DisableTakeDamageFindEnemy = true
		self.ControlledNPC.DisableTouchFindEnemy = true
		self.ControlledNPC.DisableSelectSchedule = true
		self.ControlledNPC.CallForHelp = false
		self.ControlledNPC.CallForBackUpOnDamage = false
		self.ControlledNPC.BringFriendsOnDeath = false
		self.ControlledNPC.FollowPlayer = false
		self.ControlledNPC.CanDetectGrenades = false
		self.ControlledNPC.Passive_RunOnTouch = false
		self.ControlledNPC.Passive_RunOnDamage = false
		self.ControlledNPC.IsGuard = false
		
		self.ControlledNPC.vACT_StopAttacks = true
		self.ControlledNPC.NextThrowGrenadeT = 0
	end
	self.ControlledNPC:ClearSchedule()
	self.ControlledNPC:StopMoving()
	timer.Simple(0.2, function()
		if IsValid(self.ControlledNPC) then
			self.AbleToTurn = true
			self.ControlledNPC.vACT_StopAttacks = false
			self.ControlledNPC:SetEnemy(self.NPCBullseye)
		end
	end)
	self:CustomOnSetControlledNPC()
end
//ENT.TestLerp = 0
---------------------------------------------------------------------------------------------------------------------------------------------
hook.Add("PlayerButtonDown","VJ_NPC_CONTROLLER",function(ply, button)
	//print(button)
	if ply.IsControlingNPC == true && IsValid(ply.VJ_TheControllerEntity) then
		local cent = ply.VJ_TheControllerEntity
		cent.LastPressedKey = button
		cent.LastPressedKeyTime = CurTime()
		cent:CustomOnKeyPressed(button)
		
		if cent.CanQuitController == true and button == KEY_END then
			cent:StopControlling()
		end
		
		if button == KEY_T then
			cent:DoCrosshairTracking()
		end
		
		local zoom = ply:GetInfoNum("vj_npc_cont_zoomdist", 5)
		if button == KEY_LEFT then
			cent.PropCamera:SetLocalPos(cent.PropCamera:GetLocalPos() + Vector(0, zoom, 0))
		elseif button == KEY_RIGHT then
			cent.PropCamera:SetLocalPos(cent.PropCamera:GetLocalPos() - Vector(0, zoom, 0))
		elseif button == KEY_UP then
			if ply:KeyDown(IN_SPEED) then
				cent.PropCamera:SetLocalPos(cent.PropCamera:GetLocalPos() + Vector(0, 0, zoom))
			else
				cent.PropCamera:SetLocalPos(cent.PropCamera:GetLocalPos() + Vector(zoom, 0, 0))
			end
		elseif button == KEY_DOWN then
			if ply:KeyDown(IN_SPEED) then
				cent.PropCamera:SetLocalPos(cent.PropCamera:GetLocalPos() - Vector(0, 0, zoom))
			else
				cent.PropCamera:SetLocalPos(cent.PropCamera:GetLocalPos() - Vector(zoom, 0, 0))
			end
		end
		
		if button == KEY_BACKSPACE then
			cent.PropCamera:SetLocalPos(cent.ZoomLevelOriginalZ)
		end
	end
end)
---------------------------------------------------------------------------------------------------------------------------------------------
/*hook.Add("KeyPress","VJ_NPC_CONTROLLER",function(ply, key)
	if ply.IsControlingNPC == true && IsValid(ply.VJ_TheControllerEntity) then
		local cent = ply.VJ_TheControllerEntity
		if key == IN_USE then
			cent:StopControlling()
		end
	end
end)*/
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:Think()
	if (!self.PropCamera:IsValid()) then self:StopControlling() return end
	if !IsValid(self.TheController) /*or self.TheController:KeyDown(IN_USE)*/ or self.TheController:Health() <= 0 or (!self.TheController.IsControlingNPC) or !IsValid(self.ControlledNPC) or (self.ControlledNPC:Health() <= 0) then self:StopControlling() return end
	if self.TheController.IsControlingNPC != true then return end
	if self.TheController.IsControlingNPC && IsValid(self.ControlledNPC) then
		if self.ControlledNPC.Flinching == true then return end
		if self.TheController:GetInfoNum("vj_npc_cont_hud", 1) == 1 then
			local AttackTypes = {MeleeAttack=false,RangeAttack=false,LeapAttack=false,WeaponAttack=false,GrenadeAttack=false,Ammo="---"}
			if self.ControlledNPC.IsVJBaseSNPC == true then
				if self.ControlledNPC.HasMeleeAttack == true then AttackTypes["MeleeAttack"] = true end
				if self.ControlledNPC.HasRangeAttack == true then AttackTypes["RangeAttack"] = true end
				if self.ControlledNPC.HasLeapAttack == true then AttackTypes["LeapAttack"] = true end
				if IsValid(self.ControlledNPC:GetActiveWeapon()) then AttackTypes["WeaponAttack"] = true AttackTypes["Ammo"] = self.ControlledNPC:GetActiveWeapon():Clip1() end
				if self.ControlledNPC.HasGrenadeAttack == true then AttackTypes["GrenadeAttack"] = true end
			end
			net.Start("vj_controller_hud")
			net.WriteBool(false)
			net.WriteFloat(self.ControlledNPC:GetMaxHealth())
			net.WriteFloat(self.ControlledNPC:Health())
			net.WriteString(self.ControlledNPC:GetName())
			net.WriteTable(AttackTypes)
			net.Send(self.TheController)
		end
		
		if #self.TheController:GetWeapons() > 0 then self.TheController:StripWeapons() end
		local tr_ply = util.TraceLine({start = self.TheController:EyePos(), endpos = self.TheController:EyePos() + (self.TheController:GetAimVector() * 32768), filter = {self.TheController,self.ControlledNPC}})
		if IsValid(self.NPCBullseye) then
			self.NPCBullseye:SetPos(tr_ply.HitPos)
		end
		
		-- Turning
		if !self.ControlledNPC:IsMoving() && self.ControlledNPC.PlayingAttackAnimation == false && self.AbleToTurn == true && self.ControlledNPC.IsReloadingWeapon != true && CurTime() > self.ControlledNPC.NextChaseTime && self.ControlledNPC.IsVJBaseSNPC_Tank != true then
			//self.ControlledNPC:SetAngles(Angle(0,self.TheController:GetAimVector():Angle().y,0))
			local angdif = math.abs(math.AngleDifference(self.TheController:EyeAngles().y, self.LastIdleAngle))
			self.LastIdleAngle = self.ControlledNPC:EyeAngles().y //tr_ply.HitPos
			self.ControlledNPC:VJ_TASK_IDLE_STAND()
			if ((self.ControlledNPC.MovementType != VJ_MOVETYPE_STATIONARY) or (self.ControlledNPC.MovementType == VJ_MOVETYPE_STATIONARY && self.ControlledNPC.CanTurnWhileStationary == true)) then
				if (VJ_AnimationExists(self.ControlledNPC, ACT_TURN_LEFT) == false && VJ_AnimationExists(self.ControlledNPC, ACT_TURN_RIGHT) == false) or (angdif <= 50 && self.ControlledNPC:GetActivity() != ACT_TURN_LEFT && self.ControlledNPC:GetActivity() != ACT_TURN_RIGHT) then
					//self.ControlledNPC:VJ_TASK_IDLE_STAND()
					self.ControlledNPC:FaceCertainPosition(tr_ply.HitPos, 0.1)
				else
					self.NextIdleStandTime = 0
					self.ControlledNPC:SetLastPosition(tr_ply.HitPos) // self.TheController:GetEyeTrace().HitPos
					self.ControlledNPC:VJ_TASK_FACE_X("TASK_FACE_LASTPOSITION")
				end
			end
			//self.TestLerp = self.ControlledNPC:GetAngles().y
			//self.ControlledNPC:SetAngles(Angle(0,Lerp(100*FrameTime(),self.TestLerp,self.TheController:GetAimVector():Angle().y),0))
		end

		self:CustomOnThink()
		self.AbleToTurn = true

		-- camerayin deghe portsetsi pokhel, Chaskhadav
		/*if self.TheController:KeyDown(IN_ATTACK2) then
			self.PropCamera:SetParent(NULL)
			self.PropCamera:SetPos(self.ControlledNPC:GetPos())
			self.PropCamera:SetParent(self.ControlledNPC)
		end*/

		-- Weapon attack
		if IsValid(self.ControlledNPC:GetActiveWeapon()) && self.ControlledNPC.IsVJBaseSNPC == true && self.ControlledNPC.IsVJBaseSNPC_Human == true && !self.ControlledNPC:IsMoving() && self.ControlledNPC:GetActiveWeapon().IsVJBaseWeapon == true && self.TheController:KeyDown(IN_ATTACK2) && self.ControlledNPC.IsReloadingWeapon == false && self.ControlledNPC.MeleeAttacking == false && self.ControlledNPC.ThrowingGrenade == false && self.ControlledNPC.vACT_StopAttacks == false then
			//self.ControlledNPC:SetAngles(Angle(0,math.ApproachAngle(self.ControlledNPC:GetAngles().y,self.TheController:GetAimVector():Angle().y,100),0))
			self.ControlledNPC:FaceCertainPosition(tr_ply.HitPos, 0.2)
			self.AbleToTurn = false
			if VJ_IsCurrentAnimation(self.ControlledNPC,self.ControlledNPC:TranslateToWeaponAnim(self.ControlledNPC.CurrentWeaponAnimation)) == false && VJ_IsCurrentAnimation(self.ControlledNPC,self.ControlledNPC.AnimTbl_WeaponAttack) == false then
				self.AbleToTurn = false
				self.ControlledNPC.CurrentWeaponAnimation = VJ_PICK(self.ControlledNPC.AnimTbl_WeaponAttack)
				self.ControlledNPC:VJ_ACT_PLAYACTIVITY(self.ControlledNPC.CurrentWeaponAnimation,false,2,false)
			end
		end

		-- Movement
		if self.ControlledNPC.MovementType != VJ_MOVETYPE_STATIONARY && self.ControlledNPC.PlayingAttackAnimation == false && CurTime() > self.ControlledNPC.NextChaseTime && self.ControlledNPC.IsVJBaseSNPC_Tank != true then
			local gerta_for = self.TheController:KeyDown(IN_FORWARD)
			local gerta_bac = self.TheController:KeyDown(IN_BACK)
			local gerta_lef = self.TheController:KeyDown(IN_MOVELEFT)
			local gerta_rig = self.TheController:KeyDown(IN_MOVERIGHT)
			local gerta_arak = self.TheController:KeyDown(IN_SPEED)
			
			if gerta_for then
				if self.ControlledNPC.MovementType == VJ_MOVETYPE_AERIAL or self.MovementType == VJ_MOVETYPE_AQUATIC then
					if gerta_arak then
						self.ControlledNPC:AAMove_ChaseEnemy(true)
					else
						self.ControlledNPC:AAMove_ChaseEnemy(true,true)
					end
				else
					if gerta_lef then
						self:StartMovement(self.TheController:GetAimVector(),Angle(0,45,0))
					elseif gerta_rig then
						self:StartMovement(self.TheController:GetAimVector(),Angle(0,-45,0))
					else
						self:StartMovement(self.TheController:GetAimVector(),Angle(0,0,0))
					end
				end
			elseif gerta_bac then
				if gerta_lef then
					self:StartMovement(self.TheController:GetAimVector()*-1,Angle(0,-45,0))
				elseif gerta_rig then
					self:StartMovement(self.TheController:GetAimVector()*-1,Angle(0,45,0))
				else
					self:StartMovement(self.TheController:GetAimVector()*-1,Angle(0,0,0))
				end
			elseif gerta_lef then
				self:StartMovement(self.TheController:GetAimVector(),Angle(0,90,0))
			elseif gerta_rig then
				self:StartMovement(self.TheController:GetAimVector(),Angle(0,-90,0))
			elseif !gerta_arak && !gerta_rig && !gerta_lef && !gerta_bac && !gerta_for then
				self.ControlledNPC:StopMoving()
				if self.ControlledNPC.MovementType == VJ_MOVETYPE_AERIAL or self.MovementType == VJ_MOVETYPE_AQUATIC then self.ControlledNPC:AAMove_Stop() end
			end
			/*if (self.TheController:KeyDown(IN_USE)) then
				self.ControlledNPC:StopMoving()
				self:StopControlling()
			end*/
		end
	end
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:StartMovement(Dir,Rot)
	local DontMove = false
	local PlyAimVec = Dir
	PlyAimVec.z = 0
	PlyAimVec:Rotate(Rot)
	local CenterToPos = self.ControlledNPC:OBBCenter():Distance(self.ControlledNPC:OBBMins()) + 20 // self.ControlledNPC:OBBMaxs().z
	local NPCPos = self.ControlledNPC:GetPos() + self.ControlledNPC:GetUp()*CenterToPos
	local groundSpeed = math.Clamp(self.ControlledNPC:GetSequenceGroundSpeed(self.ControlledNPC:GetSequence()), 300, 9999)
	local forwardtr = util.TraceLine({start = NPCPos, endpos = NPCPos + PlyAimVec*groundSpeed, filter = {self,self.TheController,self.ControlledNPC}})
	//local npcvel = self.ControlledNPC:GetGroundSpeedVelocity()
	//if self.ControlledNPC:GetMovementActivity() > 0 then print(self.ControlledNPC:GetSequenceGroundSpeed(self.ControlledNPC:SelectWeightedSequence(self.ControlledNPC:GetMovementActivity()))) end
	//self.ControlledNPC:GetSequenceGroundSpeed(self.ControlledNPC:SelectWeightedSequence(self.ControlledNPC:GetActivity()))
	//Vector(math.abs(npcvel.x),math.abs(npcvel.y),math.abs(npcvel.z))
	local CalculateWallToNPC = NPCPos:Distance(forwardtr.HitPos) - 40
	if self.TheController:GetInfoNum("vj_npc_cont_devents",0) == 1 then
		VJ_CreateTestObject(NPCPos,self:GetAngles(),Color(0,255,255)) -- NPC's calculated position
		VJ_CreateTestObject(forwardtr.HitPos,self:GetAngles(),Color(255,255,0)) -- forward trace position
	end
	if NPCPos:Distance(forwardtr.HitPos) >= 51 then
		local FinalPos = Vector((self.ControlledNPC:GetPos()+PlyAimVec*CalculateWallToNPC).x,(self.ControlledNPC:GetPos()+PlyAimVec*CalculateWallToNPC).y,forwardtr.HitPos.z)
		local downtr = util.TraceLine({start = FinalPos, endpos = FinalPos + self:GetUp()*-(200+CenterToPos), filter = {self,self.TheController,self.ControlledNPC}})
		local CalculateDownDistance = (FinalPos.z-CenterToPos) - downtr.HitPos.z
		if CalculateDownDistance >= 150 then
			DontMove = true
			CalculateWallToNPC = CalculateWallToNPC - CalculateDownDistance
		end
		FinalPos = Vector((self.ControlledNPC:GetPos()+PlyAimVec*CalculateWallToNPC).x,(self.ControlledNPC:GetPos()+PlyAimVec*CalculateWallToNPC).y,forwardtr.HitPos.z)
		if self.TheController:GetInfoNum("vj_npc_cont_devents",0) == 1 then
			VJ_CreateTestObject(downtr.HitPos,self:GetAngles(),Color(0,255,0)) -- Down trace position
			VJ_CreateTestObject(FinalPos,self:GetAngles(),Color(255,0,0)) -- Final move position
		end
		if DontMove == false then
			self.ControlledNPC:SetLastPosition(FinalPos)
			local movetype = "TASK_WALK_PATH"
			if (self.TheController:KeyDown(IN_SPEED)) then movetype = "TASK_RUN_PATH" end
			self.ControlledNPC:VJ_TASK_GOTO_LASTPOS(movetype,function(x)
				//self.ControlledNPC:SetLastPosition(self.TheController:GetEyeTrace().HitPos)
				if self.TheController:KeyDown(IN_ATTACK2) && self.ControlledNPC.IsVJBaseSNPC_Human == true then
					x.ConstantlyFaceEnemy = true
					x.CanShootWhenMoving = true
				else
					if self.CrosshairTrackingActivated == true then
						x.ConstantlyFaceEnemy = true
					else
						x:EngTask("TASK_FACE_LASTPOSITION", 0)
					end
				end
			end)
		end
	end
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:DoCrosshairTracking()
	if self.CrosshairTrackingActivated == false then
		self.TheController:ChatPrint("Bullseye tracking activated!")
		self.CrosshairTrackingActivated = true
	else
		self.TheController:ChatPrint("Bullseye tracking deactivated!")
		self.CrosshairTrackingActivated = false
	end
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:StopControlling()
	//if !IsValid(self.TheController) then return self:Remove() end
	self:CustomOnStopControlling()

	if IsValid(self.TheController) then
		local playerpos = self.TheController:GetPos()
		self.TheController:UnSpectate()
		self.TheController:KillSilent() -- If we don't, we will get bugs like no being able to pick up weapons when walking over them.
		if self.User_CanRespawn == true then
			self.TheController:Spawn()
			for _, v in pairs(self.ControllerCurrentWeapons) do
				self.TheController:Give(v)
			end
			if (self.ControllerActiveWeapon) then self.TheController:SelectWeapon(self.ControllerActiveWeapon) end
			self.TheController:SetHealth(self.ControllerHealth)
			self.TheController:SetArmor(self.ControllerArmor)
		end
		if IsValid(self.PropCamera) then
		self.TheController:SetPos(self.PropCamera:GetPos() +self.PropCamera:GetUp()*100) else
		self.TheController:SetPos(playerpos) end
		self.TheController:SetNoDraw(false)
		self.TheController:DrawShadow(true)
		self.TheController:SetNoTarget(false)
		//self.TheController:Spectate(OBS_MODE_NONE)
		self.TheController:DrawViewModel(true)
		self.TheController:DrawWorldModel(true)
		//self.TheController:SetMoveType(MOVETYPE_WALK)
		self.TheController.IsControlingNPC = false
		self.TheController.VJ_TheControllerEntity = NULL
	end
	self.TheController = NULL

	if IsValid(self.ControlledNPC) then
		//self.ControlledNPC:StopMoving()
		self.ControlledNPC.VJ_IsBeingControlled = false
		self.ControlledNPC.VJ_TheController = NULL
		self.ControlledNPC.VJ_TheControllerEntity = NULL
		//self.ControlledNPC:ClearSchedule()
		if self.ControlledNPC.IsVJBaseSNPC == true then
			self.ControlledNPC.DisableWandering = self.VJNPC_Values[1]
			self.ControlledNPC.DisableChasingEnemy = self.VJNPC_Values[2]
			self.ControlledNPC.DisableTakeDamageFindEnemy = self.VJNPC_Values[3]
			self.ControlledNPC.DisableTouchFindEnemy = self.VJNPC_Values[4]
			self.ControlledNPC.DisableSelectSchedule = self.VJNPC_Values[5]
			self.ControlledNPC.CallForHelp = self.VJNPC_Values[6]
			self.ControlledNPC.CallForBackUpOnDamage = self.VJNPC_Values[7]
			self.ControlledNPC.BringFriendsOnDeath = self.VJNPC_Values[8]
			self.ControlledNPC.FollowPlayer = self.VJNPC_Values[9]
			self.ControlledNPC.CanDetectGrenades = self.VJNPC_Values[10]
			self.ControlledNPC.Passive_RunOnTouch = self.VJNPC_Values[11]
			self.ControlledNPC.Passive_RunOnDamage = self.VJNPC_Values[12]
			self.ControlledNPC.IsGuard = self.VJNPC_Values[13]
		end
	end
	//self.PropCamera:Remove()
	self.VJControllerEntityIsRemoved = true
	self:Remove()
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:OnRemove()
	self:CustomOnRemove()
	if self.VJControllerEntityIsRemoved == false then
		self:StopControlling()
	end
	net.Start("vj_controller_hud")
	net.WriteBool(true)
	net.WriteFloat(0)
	net.WriteFloat(0)
	net.WriteString(" ")
	net.WriteTable({})
	net.Broadcast()
end
/*--------------------------------------------------
	*** Copyright (c) 2012-2020 by DrVrej, All rights reserved. ***
	No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
	without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
--------------------------------------------------*/
