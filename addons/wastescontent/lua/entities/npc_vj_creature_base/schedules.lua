require("ai_vj_schedule")
/*-----------------------------------------------
	*** Copyright (c) 2012-2020 by DrVrej, All rights reserved. ***
	No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
	without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
-----------------------------------------------*/
function ENT:RunAI(strExp) -- Called from the engine every 0.1 seconds
	if self:GetState() == VJ_STATE_FREEZE then self:MaintainActivity() return end
	//print("Running the RunAI")
	//self:SetArrivalActivity(ACT_COWER)
	//self:SetArrivalSpeed(1000)
	if self:IsRunningBehavior() or self:DoingEngineSchedule() then return true end
	if (!self.CurrentSchedule or (self.CurrentSchedule != nil && ((self:IsMoving() && self.CurrentSchedule.CanBeInterrupted == true) or (!self:IsMoving())))) && ((self.VJ_PlayingSequence == false) or (self.VJ_PlayingSequence == true && self.VJ_IsPlayingInterruptSequence == true)) then self:SelectSchedule() end
	if (self.CurrentSchedule) then self:DoSchedule(self.CurrentSchedule) end
	if self.VJ_PlayingSequence == false && self.VJ_IsPlayingInterruptSequence == false then self:MaintainActivity() end
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:DoRunCode_OnFail(schedule)
	if schedule == nil then return false end
	if schedule.AlreadyRanCode_OnFail == true then return false end
	if schedule.RunCode_OnFail != nil then schedule.AlreadyRanCode_OnFail = true schedule.RunCode_OnFail() return true end
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:DoRunCode_OnFinish(schedule)
	if schedule == nil then return false end
	if schedule.AlreadyRanCode_OnFinish == true then return false end
	if schedule.RunCode_OnFinish != nil then schedule.AlreadyRanCode_OnFinish = true schedule.RunCode_OnFinish() return true end
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:SetState(state, time)
	state = state or VJ_STATE_NONE
	time = time or -1
	self.AIState = state
	if state == VJ_STATE_FREEZE then -- Reset the tasks
		self:TaskComplete()
		self:VJ_TASK_IDLE_STAND()
	end
	if time >= 0 then
		timer.Create("timer_state_reset"..self:EntIndex(), time, 1, function()
			self:SetState()
		end)
	else
		timer.Remove("timer_state_reset"..self:EntIndex())
	end
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:GetState()
	return self.AIState
end
local tr_addvec = Vector(0,0,2)
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:StartSchedule(schedule)
	if self:GetState() == VJ_STATE_ONLY_ANIMATION && schedule.IsPlayActivity != true then return end
	if (IsValid(self:GetInternalVariable("m_hOpeningDoor")) or self:GetInternalVariable("m_flMoveWaitFinished") > 0) && self.CurrentSchedule != nil && schedule.Name == self.CurrentSchedule.Name then return end -- If it's the same task and it's opening a door, then DONT CONTINUE
	self:ClearCondition(35)
	if (!schedule.RunCode_OnFail) then schedule.RunCode_OnFail = nil end -- Code that will run ONLY when it fails!
	if (!schedule.RunCode_OnFinish) then schedule.RunCode_OnFinish = nil end -- Code that will run once the task finished (Will run even if failed)
	if (!schedule.ResetOnFail) then schedule.ResetOnFail = false end
	if (!schedule.StopScheduleIfNotMoving) then schedule.StopScheduleIfNotMoving = false end -- Will stop from certain entities, such as other NPCs
	if (!schedule.StopScheduleIfNotMoving_Any) then schedule.StopScheduleIfNotMoving_Any = false end -- Will stop from any blocking entity!
	if (!schedule.CanBeInterrupted) then schedule.CanBeInterrupted = false end
	if (!schedule.ConstantlyFaceEnemy) then schedule.ConstantlyFaceEnemy = false end -- Constantly face the enemy while doing this task
	if (!schedule.ConstantlyFaceEnemyVisible) then schedule.ConstantlyFaceEnemyVisible = false end
	if (!schedule.CanShootWhenMoving) then schedule.CanShootWhenMoving = false end -- Is it able to fire when moving?
	if self.MovementType == VJ_MOVETYPE_STATIONARY && schedule.IsMovingTask == true then
		return
	end
	for _,v in ipairs(schedule.Tasks) do
		if schedule.IsMovingTask == true then break end
		if v.TaskName == "TASK_RUN_PATH" or v.TaskName == "TASK_RUN_PATH_FLEE" or v.TaskName == "TASK_RUN_PATH_TIMED" or v.TaskName == "TASK_RUN_PATH_FOR_UNITS" or v.TaskName == "TASK_RUN_PATH_WITHIN_DIST" then schedule.IsMovingTask = true schedule.IsMovingTask_Run = true break end
		if v.TaskName == "TASK_WALK_PATH" or v.TaskName == "TASK_WALK_PATH_TIMED" or v.TaskName == "TASK_WALK_PATH_WITHIN_DIST" or v.TaskName == "TASK_WALK_PATH_FOR_UNITS" then schedule.IsMovingTask = true schedule.IsMovingTask_Walk = true break end
		schedule.IsMovingTask = false
		schedule.IsMovingTask_Run = false
		schedule.IsMovingTask_Walk = false
	end
	if schedule.IsMovingTask == nil then schedule.IsMovingTask = false end
	if schedule.IsMovingTask == true then
		local tr = util.TraceHull({
			start = self:GetPos(),
			endpos = self:GetPos(),
			mins = self:OBBMins() + tr_addvec,
			maxs = self:OBBMaxs() + tr_addvec,
			filter = self
		})
		if IsValid(tr.Entity) && tr.Entity:IsNPC() && !VJ_HasValue(self.EntitiesToNoCollide,tr.Entity:GetClass()) then
			self:DoRunCode_OnFail(schedule)
			return
		end
	end
	if schedule.IsMovingTask_Run == nil then schedule.IsMovingTask_Run = false end
	if schedule.IsMovingTask_Walk == nil then schedule.IsMovingTask_Walk = false end
	if schedule.CanShootWhenMoving == true && self.CurrentWeaponAnimation != nil && IsValid(self:GetEnemy()) then
		self:DoWeaponAttackMovementCode(true, (schedule.IsMovingTask_Walk and 1) or 0) -- Send 1 if the current task is walking!
		self:SetArrivalActivity(self.CurrentWeaponAnimation)
	end
	schedule.AlreadyRanCode_OnFail = false
	schedule.AlreadyRanCode_OnFinish = false
	// lua_run PrintTable(Entity(1):GetEyeTrace().Entity.CurrentSchedule)
	//PrintTable(schedule)
	//if schedule.Name != "vj_chase_enemy" then PrintTable(schedule) end
	self:DoRunCode_OnFinish(self.CurrentSchedule) -- Yete arten schedule garne, verchatsoor
	self.CurrentSchedule = schedule
	self.CurrentTaskID = 1
	self.GetNumberOfTasks = tonumber(schedule:NumTasks()) -- Or else nil
	self:SetTask(schedule:GetTask(1))
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:DoSchedule(schedule)
	if self:TaskFinished() then self:NextTask(schedule) end
	if self.CurrentTask then self:RunTask(self.CurrentTask) end
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:ScheduleFinished(schedule)
	schedule = schedule or self.CurrentSchedule
	self:DoRunCode_OnFinish(schedule)
	self.CurrentSchedule 	= nil
	self.CurrentTask 		= nil
	self.CurrentTaskID 		= nil
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:SetTask(task)
	self.CurrentTask 	= task
	self.bTaskComplete 	= false
	self.TaskStartTime 	= CurTime()
	self:StartTask(self.CurrentTask)
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:NextTask(schedule)
	//print(self.GetNumberOfTasks)
	//print(self.CurrentTaskID)
	if !schedule or !self then return end
	if self.GetNumberOfTasks == nil then //1
	print("WARNING: VJ BASE ANIMATION SYSTEM IS BROKEN!") end
	//self:ScheduleFinished(schedule)
	//return end
	//if self.CurrentTaskID > 3 then return end -- if CurrentTaskID more than 3, should we tell then game not to run it? Still have to figure it out
	//print("Running NextTask")
	self.CurrentTaskID = self.CurrentTaskID +1
	//if self.CurrentTaskID != nil then
	if (self.CurrentTaskID > self.GetNumberOfTasks) then
		self:ScheduleFinished(schedule)
		return
	end //end
	self:SetTask(schedule:GetTask(self.CurrentTaskID))
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:OnTaskComplete()
	//self:DoRunCode_OnFinish(self.CurrentSchedule) -- Will break many movement tasks (Ex: Humans Taking cover to reload)
	self.bTaskComplete = true
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:StartTask(task) if task == nil or !task or !self then return end task:Start(self) end
function ENT:RunTask(task) if !task or !self then return end task:Run(self) end
function ENT:TaskTime() return CurTime() - self.TaskStartTime end
function ENT:TaskFinished() return self.bTaskComplete end
function ENT:StartEngineTask(iTaskID,TaskData) end
function ENT:RunEngineTask(iTaskID,TaskData) end
function ENT:StartEngineSchedule(scheduleID) self:ScheduleFinished() self.bDoingEngineSchedule = true end
function ENT:EngineScheduleFinish() self.bDoingEngineSchedule = nil end
function ENT:DoingEngineSchedule() return self.bDoingEngineSchedule end
function ENT:OnCondition(iCondition) end
/*-----------------------------------------------
	*** Copyright (c) 2012-2020 by DrVrej, All rights reserved. ***
	No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
	without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
-----------------------------------------------*/