--must be called from a quest step task where the parent task is a ffxiv_quest_task object
function quest_step_complete_eval()
	return ml_task_hub:CurrentTask().stepCompleted
end

function quest_step_complete_execute()
	ml_task_hub:CurrentTask():ParentTask().currentStepCompleted = true
	ml_task_hub:CurrentTask().completed = true
	if (ml_task_hub:CurrentTask().params["delay"] ~= nil) then
		ml_task_hub:CurrentTask():SetDelay(ml_task_hub:CurrentTask().params["delay"])
	end
end

c_questcanstart = inheritsFrom( ml_cause )
e_questcanstart = inheritsFrom( ml_effect )
function c_questcanstart:evaluate()
	if (TimeSince(ml_task_hub:CurrentTask().startTimer) > 1000) then
		return not ml_task_hub:CurrentTask().quest:isStarted()
	else
		return false
	end
end
function e_questcanstart:execute()
	local task = ml_task_hub:CurrentTask().quest:GetStartTask()
	if (ValidTable(task)) then
		if(task.params["meshname"] ~= nil) then
			if(task.params["meshname"] ~= NavigationManager:GetNavMeshName()) then
				mm.ChangeNavMesh(task.params["meshname"])
			end
		end
	
		ml_task_hub:CurrentTask():AddSubTask(task)
		ml_task_hub:CurrentTask().currentStepCompleted = false
		ml_task_hub:CurrentTask().currentStepIndex = 1
		gCurrQuestStep = tostring(ml_task_hub:CurrentTask().currentStepIndex)
		Settings.FFXIVMINION.currentQuestStep = tonumber(gCurrQuestStep)
	end
end

c_questiscomplete = inheritsFrom( ml_cause )
e_questiscomplete = inheritsFrom( ml_effect )
function c_questiscomplete:evaluate()
	return ml_task_hub:CurrentTask().quest:isComplete()
end
function e_questiscomplete:execute()
	local task = ml_task_hub:CurrentTask().quest:GetCompleteTask()
	if (ValidTable(task)) then
		if(task.params["meshname"] ~= nil) then
			if(task.params["meshname"] ~= NavigationManager:GetNavMeshName()) then
				mm.ChangeNavMesh(task.params["meshname"])
			end
		end
	
		ml_task_hub:CurrentTask():AddSubTask(task)
		ml_task_hub:CurrentTask().currentStepCompleted = false
	end
end

c_nextqueststep = inheritsFrom( ml_cause )
e_nextqueststep = inheritsFrom( ml_effect )
function c_nextqueststep:evaluate()
	if (not ml_task_hub:CurrentTask().quest:isStarted() or
		ml_task_hub:CurrentTask().quest:isComplete())
	then
		return false
	end
	
	return ml_task_hub:CurrentTask().currentStepCompleted
end
function e_nextqueststep:execute()
	if (ml_task_hub:CurrentTask().currentStepIndex == 1 and
		Settings.FFXIVMINION.currentQuestStep ~= nil and
		Settings.FFXIVMINION.currentQuestStep > 1) 
	then
		ml_task_hub:CurrentTask().currentStepIndex = Settings.FFXIVMINION.currentQuestStep
	else
		ml_task_hub:CurrentTask().currentStepIndex = ml_task_hub:CurrentTask().currentStepIndex + 1
	end
	
	local task = ml_task_hub:CurrentTask().quest:GetStepTask(ml_task_hub:CurrentTask().currentStepIndex)
	if (ValidTable(task)) then
		if(task.params["meshname"] ~= nil) then
			if(task.params["meshname"] ~= NavigationManager:GetNavMeshName()) then
				mm.ChangeNavMesh(task.params["meshname"])
			end
		end
		
		if(task.params["type"] == "kill") then
			if(Settings.FFXIVMINION.questKillCount ~= nil) then
				task.killCount = Settings.FFXIVMINION.questKillCount
			end
		end
		
		ml_task_hub:CurrentTask():AddSubTask(task)
		
		--update quest step state
		ml_task_hub:ThisTask().currentStepCompleted = false
		gCurrQuestStep = tostring(ml_task_hub:ThisTask().currentStepIndex)
		Settings.FFXIVMINION.currentQuestStep = tonumber(gCurrQuestStep)
	end
end

c_questmovetomap = inheritsFrom( ml_cause )
e_questmovetomap = inheritsFrom( ml_effect )
function c_questmovetomap:evaluate()
	local mapID = ml_task_hub:CurrentTask().params["mapid"]
    if (mapID and mapID > 0) then
        if(Player.localmapid ~= mapID) then
			e_questmovetomap.mapID = mapID
			return true
        end
    end
	
	return false
end
function e_questmovetomap:execute()
	local task = ffxiv_task_movetomap.Create()
	task.destMapID = e_questmovetomap.mapID
	ml_task_hub:CurrentTask():AddSubTask(task)
end

c_questmovetopos = inheritsFrom( ml_cause )
e_questmovetopos = inheritsFrom( ml_effect )
function c_questmovetopos:evaluate()
	local mapID = ml_task_hub:CurrentTask().params["mapid"]
    if (mapID and mapID > 0) then
        if(Player.localmapid == mapID) then
			local pos = ml_task_hub:CurrentTask().params["pos"]
			return Distance2D(Player.pos.x, Player.pos.z, pos.x, pos.z) > 2
        end
    end
	
	return false
end
function e_questmovetopos:execute()
	local pos = ml_task_hub:CurrentTask().params["pos"]
	local task = ffxiv_task_movetopos.Create()
	local newTask = ffxiv_task_movetopos.Create()
	newTask.pos = pos
	ml_task_hub:CurrentTask():AddSubTask(newTask)
end

c_questaccept = inheritsFrom( ml_cause )
e_questaccept = inheritsFrom( ml_effect )
function c_questaccept:evaluate()
	local id = ffxiv_task_quest.currentQuest.id
    if (id and id > 0) then
		return Quest:IsQuestAcceptDialogOpen(id)
    end
	
	return false
end
function e_questaccept:execute()
	Quest:AcceptQuest()
	ml_task_hub:CurrentTask():ParentTask().startTimer = ml_global_information.Now
	ml_task_hub:CurrentTask().stepCompleted = true
end

c_questcomplete = inheritsFrom( ml_cause )
e_questcomplete = inheritsFrom( ml_effect )
function c_questcomplete:evaluate()
	return Quest:IsQuestRewardDialogOpen()
end
function e_questcomplete:execute()
	if(ml_task_hub:CurrentTask().params["itemreward"]) then
		Quest:CompleteQuestReward(ml_task_hub:CurrentTask().params["itemrewardslot"])
	else
		Quest:CompleteQuestReward()
	end
	
	ml_task_hub:CurrentTask().stepCompleted = true
	ml_task_hub:CurrentTask():ParentTask().questCompleted = true
end

c_questinteract = inheritsFrom( ml_cause )
e_questinteract = inheritsFrom( ml_effect )
function c_questinteract:evaluate()
	local id = ml_task_hub:ThisTask().params["id"]
    if (id and id > 0) then
		local el = EntityList("contentid="..tostring(id))
		if(ValidTable(el)) then
			local id, entity = next(el)
			if(entity) then
				if 	(entity.type == 5 and entity.distance2d < 6) or
					(entity.distance < 3) 
				then
					e_questinteract.entity = entity
					return true
				end
			end
        end
    end
	
	return false
end
function e_questinteract:execute()
	local entity = e_questinteract.entity
	if (entity) then
		Player:Interact(entity.id)
		if(	ml_task_hub:ThisTask().params["type"] == "interact"  and not
			ml_task_hub:ThisTask().params["itemturnin"] )
			then
			ml_task_hub:ThisTask().stepCompleted = true
		end
	end
end

c_questhandover = inheritsFrom( ml_cause )
e_questhandover = inheritsFrom( ml_effect )
function c_questhandover:evaluate()
	return Quest:IsRequestDialogOpen()
end
function e_questhandover:execute()
	if(ml_task_hub:CurrentTask().params["itemturnin"]) then
		if(ml_task_hub:CurrentTask().params["itemturninid"]) then
			if(not ml_task_hub:CurrentTask().idset) then
				ml_task_hub:CurrentTask().idset = {}
				for _, id in pairs(ml_task_hub:CurrentTask().params["itemturninid"]) do
					ml_task_hub:CurrentTask().idset[id] = false
				end
				ml_task_hub:CurrentTask().timer = ml_global_information.Now
			elseif(TimeSince(ml_task_hub:CurrentTask().timer) > 2000) then
				local handoverDone = true
				for id, handover in pairs(ml_task_hub:CurrentTask().idset) do
					if (not handover) then
						local item = Inventory:Get(id)
						if(ValidTable(item)) then
							item:HandOver()
							ml_task_hub:CurrentTask().idset[id] = true
							ml_task_hub:CurrentTask().timer = ml_global_information.Now
							handoverDone = false
							break
						end
					end
				end
				
				if(handoverDone) then
					Quest:RequestHandOver()
					if (ml_task_hub:CurrentTask().params["type"] == "interact") then
						ml_task_hub:CurrentTask().stepCompleted = true
					end
				end
			end
		else
			ml_error("Quest item handover required but no itemturninid set specified in profile")
		end
	else
		ml_error("Quest item handover required but itemturnin not specified in profile")
	end
end

c_questkill = inheritsFrom( ml_cause )
e_questkill = inheritsFrom( ml_effect )
function c_questkill:evaluate()
	local id = ml_task_hub:CurrentTask().params["id"]
    if (id and id > 0) then
		local el = EntityList("shortestpath,onmesh,alive,attackable,contentid="..tostring(id))
		if(ValidTable(el)) then
			local id, entity = next(el)
			if(entity) then
				e_questkill.id = id
				return true
			end
        end
    end
	
	return false
end
function e_questkill:execute()
	local newTask = ffxiv_task_killtarget.Create()
	newTask.targetid = e_questkill.id
	newTask.task_complete_execute = 
		function()
			local count = ml_task_hub:CurrentTask():ParentTask().killCount
			if(not count) then
				ml_task_hub:CurrentTask():ParentTask().killCount = 1
			else
				ml_task_hub:CurrentTask():ParentTask().killCount = count + 1
			end
			Settings.FFXIVMINION.questKillCount = ml_task_hub:CurrentTask():ParentTask().killCount
			ml_task_hub:CurrentTask().completed = true
		end
	ml_task_hub:CurrentTask():AddSubTask(newTask)
end

c_atinteract = inheritsFrom( ml_cause )
e_atinteract = inheritsFrom( ml_effect )
function c_atinteract:evaluate()
	if (ml_task_hub:CurrentTask().name == "MOVETOPOS") then
		local id = ml_task_hub:ThisTask().params["id"]
		if (id and id > 0) then
			local el = EntityList("contentid="..tostring(id))
			if(ValidTable(el)) then
				local id, entity = next(el)
				if(entity) then
					if 	(entity.type == 5 and entity.distance2d < 6) or
						(entity.distance < 3) 
					then
						return true
					end
				end
			end
		end
	end
	
	return false
end
function e_atinteract:execute()
	ml_task_hub:CurrentTask():Terminate()
	ml_task_hub:CurrentTask():task_complete_execute()
end

c_indialog = inheritsFrom( ml_cause )
e_indialog = inheritsFrom( ml_effect )
function c_indialog:evaluate()
	return Quest:IsInDialog()
end
function e_indialog:execute()
	--do nothing, this is a blocking cne to avoid spamming
end

c_questyesno = inheritsFrom( ml_cause )
e_questyesno = inheritsFrom( ml_effect )
function c_questyesno:evaluate()
	return ControlVisible("SelectYesno")
end
function e_questyesno:execute()
	PressYesNo(true)
end

c_questisloading = inheritsFrom( ml_cause )
e_questisloading = inheritsFrom( ml_effect )
function c_questisloading:evaluate()
	return Quest:IsLoading()
end
function e_questisloading:execute()
	--do nothing, this is a blocking cne
end