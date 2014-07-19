ffxiv_task_hunt = inheritsFrom(ml_task)
ffxiv_task_hunt.rankS = "2953;2954;2955;2956;2957;2958;2959;2960;2961;2962;2963;2964;2965;2966;2967;2968;2969"
ffxiv_task_hunt.rankA = "2936;2937;2938;2939;2940;2941;2942;2943;2944;2945;2946;2947;2948;2949;2950;2951;2952"
ffxiv_task_hunt.rankB = "2919;2920;2921;2922;2923;2924;2925;2926;2927;2928;2929;2930;2931;2932;2933;2934;2935"

ffxiv_task_hunt.mainwindow = { name = "Hunt Manager", x = 50, y = 50, width = 250, height = 230}

ffxiv_task_hunt.hasTarget = false
ffxiv_task_hunt.location = 0
ffxiv_task_hunt.locationIndex = 0
ffxiv_task_hunt.locationTimer = 0

function ffxiv_task_hunt.Create()
    local newinst = inheritsFrom(ffxiv_task_hunt)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_hunt members
    newinst.name = "LT_HUNT"
    newinst.lastTarget = 0
    newinst.markerTime = 0
    newinst.currentMarker = false
	newinst.filterLevel = false
	newinst.startMap = Player.localmapid
    newinst.atMarker = false
	
	ffxiv_task_hunt.hasTarget = false
	ffxiv_task_hunt.locationTimer = 0
	ffxiv_task_hunt.location = 0
	ffxiv_task_hunt.locationIndex = 0

    return newinst
end

c_add_hunttarget = inheritsFrom( ml_cause )
e_add_hunttarget = inheritsFrom( ml_effect )
c_add_hunttarget.targetid = 0
c_add_hunttarget.rank = ""
c_add_hunttarget.name = ""
c_add_hunttarget.pos = {}
c_add_hunttarget.oocCastTimer = 0
function c_add_hunttarget:evaluate()
	if (ffxiv_task_hunt.hasTarget or ml_task_hub:CurrentTask().name == "LT_KILLTARGET") then
		return false
	end
	
	local parentTask = ""
	if (ml_task_hub:CurrentTask():ParentTask()) then
		parentTask = ml_task_hub:CurrentTask():ParentTask().name
	end
	
	--Only deal with aggro if we are not moving to a marker.
	if (ml_task_hub:CurrentTask().name ~= "MOVETOPOS" and ml_task_hub:CurrentTask().atMarker ) then
		local aggro = GetNearestAggro()
		if ValidTable(aggro) then
			if (aggro.hp.current > 0 and aggro.id and aggro.id ~= 0 and aggro.distance <= 30) then
				ml_global_information.IsWaiting = false
				c_add_hunttarget.targetid = aggro.id
				return true
			end
		end 
	end
    
	if (ml_global_information.IsWaiting) then 
		return false 
	end
	
	if (SkillMgr.Cast( Player, true)) then
		c_add_hunttarget.oocCastTimer = Now() + 1500
		return false
	end
	
	if (ActionList:IsCasting() or Now() < c_add_hunttarget.oocCastTimer) then
		return false
	end
	
    local rank, target = GetHuntTarget()
    if (ValidTable(target)) then
        if(target.hp.current > 0 and target.id ~= nil and target.id ~= 0) then
			c_add_hunttarget.name = target.name
			c_add_hunttarget.pos = target.pos
			c_add_hunttarget.rank = rank
            c_add_hunttarget.targetid = target.id
            return true
        end
    end
    
    return false
end
function e_add_hunttarget:execute()	
	ffxiv_task_hunt.hasTarget = true
	
	if (c_add_hunttarget.rank ~= "" and c_add_hunttarget.name ~= "") then
		if (c_add_hunttarget.rank == "S" and gHuntSRankSound == "1") then
			GameHacks:PlaySound(37)
			GameHacks:PlaySound(37)
			GameHacks:PlaySound(37)
		elseif (c_add_hunttarget.rank == "A" and gHuntARankSound == "1") then
			GameHacks:PlaySound(36)
			GameHacks:PlaySound(36)
			GameHacks:PlaySound(36)
		elseif (c_add_hunttarget.rank == "B" and gHuntBRankSound == "1") then
			GameHacks:PlaySound(38)
			GameHacks:PlaySound(38)
			GameHacks:PlaySound(38)
		end
		
		--Using /tell to self for now, for testing.
		if (c_add_hunttarget.rank == "S" and gHuntSRankShout == "1") then
			d("[/say FOUND ["..c_add_hunttarget.name.."] @ <pos>]")
			--SendTextCommand("/say "..
		elseif (c_add_hunttarget.rank == "A" and gHuntARankShout == "1") then
			d("[/say FOUND ["..c_add_hunttarget.name.."] @ <pos>]")
			--GameHacks:PlaySound(10)
		elseif (c_add_hunttarget.rank == "B" and gHuntBRankShout == "1") then
			d("[/say FOUND ["..c_add_hunttarget.name.."] @ <pos>]")
			--GameHacks:PlaySound(20)
		end
	end
	
    local newTask = ffxiv_task_killtarget.Create()
	Player:SetTarget(c_add_hunttarget.targetid)
    newTask.targetid = c_add_hunttarget.targetid
	newTask.rank = c_add_hunttarget.rank
	newTask.canEngage = false
	
	if (c_add_hunttarget.rank == "S") then
		newTask.failTimer = (tonumber(gHuntSRankMaxWait) * 1000)
		newTask.waitTimer = Now()
		newTask.safeDistance = 40
	elseif (c_add_hunttarget.rank == "A") then
		newTask.failTimer = (tonumber(gHuntARankMaxWait) * 1000)
		newTask.waitTimer = Now()
		newTask.safeDistance = 30
	elseif (c_add_hunttarget.rank == "B") then
		newTask.failTimer = (tonumber(gHuntARankMaxWait) * 1000)
		newTask.waitTimer = Now() + (tonumber(gHuntBRankWaitTime) * 1000)
		newTask.safeDistance = 22
	else
		newTask.failTimer = nil
		newTask.waitTimer = Now()
		newTask.safeDistance = 2
		newTask.canEngage = true
	end
	
	c_add_hunttarget.targetid = 0
	c_add_hunttarget.rank = ""
	c_add_hunttarget.name = ""
	c_add_hunttarget.pos = ""
	
    ml_task_hub:CurrentTask():AddSubTask(newTask)
end

c_nexthuntmarker = inheritsFrom( ml_cause )
e_nexthuntmarker = inheritsFrom( ml_effect )
function c_nexthuntmarker:evaluate()

    if (not ml_marker_mgr.markersLoaded) then
        return false
    end
    
    if ( ml_task_hub:CurrentTask().currentMarker ~= nil and ml_task_hub:CurrentTask().currentMarker ~= 0 ) then
        local marker = nil
        
        -- first check to see if we have no initiailized marker
        if (ml_task_hub:CurrentTask().currentMarker == false) then --default init value
            marker = ml_marker_mgr.GetNextMarker(strings[gCurrentLanguage].huntMarker, ml_task_hub:CurrentTask().filterLevel)
        
			if (marker == nil) then
				ml_task_hub:CurrentTask().filterLevel = false
				marker = ml_marker_mgr.GetNextMarker(strings[gCurrentLanguage].huntMarker, ml_task_hub:CurrentTask().filterLevel)
			end	
		end
        
        -- next check to see if our level is out of range
        if (marker == nil) then
            if (ValidTable(ml_task_hub:CurrentTask().currentMarker)) then
                if 	(ml_task_hub:CurrentTask().filterLevel) and
					(Player.level < ml_task_hub:CurrentTask().currentMarker:GetMinLevel() or 
                    Player.level > ml_task_hub:CurrentTask().currentMarker:GetMaxLevel()) 
                then
                    marker = ml_marker_mgr.GetNextMarker(ml_task_hub:CurrentTask().currentMarker:GetType(), ml_task_hub:CurrentTask().filterLevel)
                end
            end
        end
        
        -- last check if our time has run out
        if (marker == nil and ml_task_hub:CurrentTask().atMarker) then
            local time = ml_task_hub:CurrentTask().currentMarker:GetTime()
			if (time and time ~= 0 and TimeSince(ml_task_hub:CurrentTask().markerTime) > time * 1000) then
                ml_debug("Getting Next Marker, TIME IS UP!")
                marker = ml_marker_mgr.GetNextMarker(ml_task_hub:CurrentTask().currentMarker:GetType(), ml_task_hub:CurrentTask().filterLevel)
            else
                return false
            end
        end
        
        if (ValidTable(marker)) then
            e_nexthuntmarker.marker = marker
            return true
        end
    end
    
    return false
end
function e_nexthuntmarker:execute()
	--If we find a new marker, set it as current marker, and immediately move to it.
	--Set atMarker to false until we get there so that the timer does not count down until we arrive at the marker.
	ml_task_hub:CurrentTask().atMarker = false
    ml_task_hub:CurrentTask().currentMarker = e_nexthuntmarker.marker
    ml_task_hub:CurrentTask().markerTime = Now()
	ml_global_information.MarkerTime = Now()
    ml_global_information.MarkerMinLevel = ml_task_hub:CurrentTask().currentMarker:GetMinLevel()
    ml_global_information.MarkerMaxLevel = ml_task_hub:CurrentTask().currentMarker:GetMaxLevel()
    ml_global_information.BlacklistContentID = ml_task_hub:CurrentTask().currentMarker:GetFieldValue(strings[gCurrentLanguage].NOTcontentIDEquals)
    ml_global_information.WhitelistContentID = ml_task_hub:CurrentTask().currentMarker:GetFieldValue(strings[gCurrentLanguage].contentIDEquals)
	gStatusMarkerName = ml_task_hub:CurrentTask().currentMarker:GetName()
	
	local newTask = ffxiv_task_movetopos.Create()
    local markerPos = ml_task_hub:CurrentTask().currentMarker:GetPosition()
    local markerType = ml_task_hub:CurrentTask().currentMarker:GetType()
    newTask.pos = markerPos
    newTask.range = math.random(5,25)
	newTask.reason = "MOVE_HUNT_MARKER"
    ml_task_hub:CurrentTask():AddSubTask(newTask)
end

c_athuntmarker = inheritsFrom( ml_cause )
e_athuntmarker = inheritsFrom( ml_effect )
function c_athuntmarker:evaluate()
    if (ml_task_hub:CurrentTask().atMarker) then
        return false
    end
    
    if (ml_task_hub:CurrentTask().currentMarker ~= false and ml_task_hub:CurrentTask().currentMarker ~= nil) then
        local myPos = Player.pos
        local pos = ml_task_hub:CurrentTask().currentMarker:GetPosition()
        local distance = Distance2D(myPos.x, myPos.z, pos.x, pos.z)
		
		if (distance < math.random(5,25)) then
			return true
		end
    end
    
    return false
end
function e_athuntmarker:execute()
	ml_task_hub:CurrentTask().markerTime = Now()
	ml_global_information.MarkerTime = Now()
	ml_task_hub:CurrentTask().atMarker = true
	ffxiv_task_hunt.hasTarget = false
end

c_huntquit = inheritsFrom( ml_cause )
e_huntquit = inheritsFrom( ml_effect )
function c_huntquit:evaluate()
    if ( ml_task_hub:RootTask().name == "LT_HUNT" and ml_task_hub:CurrentTask().name == "LT_KILLTARGET" ) then		
		local target = EntityList:Get(ml_task_hub:CurrentTask().targetid)
		if (ml_task_hub:CurrentTask().failTimer and ml_task_hub:CurrentTask().failTimer ~= 0 and Now() > ml_task_hub:CurrentTask().failTimer) then
			if (not target or not target.attackable or (target and not target.alive) or (target and not target.onmesh and not InCombatRange(target.id))) then
				return true
			end
		elseif (ml_task_hub:CurrentTask().rank == "S") then
			local allies = EntityList("alive,friendly,chartype=4,targetable,maxdistance=50")
			if ((target.hp.percent >= tonumber(gHuntSRankHP)) and (not allies or TableSize(allies) < tonumber(gHuntSRankAllies))) then
				return true
			end
		elseif (ml_task_hub:CurrentTask().rank == "A") then
			local allies = EntityList("alive,friendly,chartype=4,targetable,maxdistance=50")
			if ((target.hp.percent >= tonumber(gHuntARankHP)) and (not allies or TableSize(allies) < tonumber(gHuntARankAllies))) then
				return true
			end
		end
    end
    
    return false
end
function e_huntquit:execute()
    if ( ml_task_hub:CurrentTask().targetid ~= nil and ml_task_hub:CurrentTask().targetid ~= 0 ) then
        -- blacklist hunt target for 5 minutes and terminate task
        local target = EntityList:Get(ml_task_hub:CurrentTask().targetid)
		ml_blacklist.AddBlacklistEntry(strings[gCurrentLanguage].monsters, target.contentid, target.name, Now() + 300*1000)
        ml_debug("Blacklisted "..target.name)
        ml_task_hub:CurrentTask():Terminate()
		ffxiv_task_hunt.hasTarget = false
    end
end

c_nexthuntlocation = inheritsFrom( ml_cause )
e_nexthuntlocation = inheritsFrom( ml_effect )
c_nexthuntlocation.location = {}
c_nexthuntlocation.locationIndex = 0
function c_nexthuntlocation:evaluate()	
	d(ffxiv_task_hunt.locationTimer - Now())
	
	local locations = gHuntLocations
	--First check to see if we are on a valid starting map, and if we are, start here.
	if (ffxiv_task_hunt.locationIndex == 0 and ffxiv_task_hunt.location == 0) then
		local startHere = false
		for i, location in spairs(locations) do
			if (location.mapid == Player.localmapid) then
				startHere = true
			end
			if (startHere) then
				ffxiv_task_hunt.location = location.mapid
				ffxiv_task_hunt.locationIndex = tonumber(i)
				ffxiv_task_hunt.locationTimer = Now() + (tonumber(location.timer) * 60 * 1000)
				return false
			end
		end
	end
	
	if (Now() > ffxiv_task_hunt.locationTimer and not ffxiv_task_hunt.hasTarget) then
		local maxLocation = TableSize(locations)
		local newLocation = {}
		
		if (ffxiv_task_hunt.locationIndex == maxLocation and maxLocation > 1) then
			--We're at the last location, so use the first.
			newLocation = locations["1"]
			--Verify that there is infact an aetheryte that we can teleport to here.
			local aetherytes = Player:GetAetheryteList()
			for i, aetheryte in pairs(aetherytes) do
				if tonumber(aetheryte.territory) == newLocation.mapid then
					newLocation.teleport = aetheryte.id
					c_nexthuntlocation.location = newLocation
					c_nexthuntlocation.locationIndex = 1
					return true
				end
			end			
		else
			newLocation = locations[tostring(ffxiv_task_hunt.locationIndex + 1)]
			local aetherytes = Player:GetAetheryteList()
			for i, aetheryte in pairs(aetherytes) do
				if tonumber(aetheryte.territory) == newLocation.mapid then
					newLocation.teleport = aetheryte.id
					c_nexthuntlocation.location = newLocation
					c_nexthuntlocation.locationIndex = (ffxiv_task_hunt.locationIndex + 1)
					return true
				end
			end	
		end
	end
	
	return false
end
function e_nexthuntlocation:execute()
	--ml_task_hub:Add(task.Create(), LONG_TERM_GOAL, TP_ASAP) REACTIVE_GOAL or IMMEDIATE_GOAL
	local location = c_nexthuntlocation.location
	Player:Stop()
	Dismount()
	
	if (Player.ismounted) then
		return
	end
	
	if (Player.castinginfo.channelingid ~= 5) then
		Player:Teleport(location.teleport)
	elseif (Player.castinginfo.channelingid == 5) then
		ffxiv_task_hunt.location = location.mapid
		ffxiv_task_hunt.locationIndex = c_nexthuntlocation.locationIndex
		ffxiv_task_hunt.locationTimer = Now() + (tonumber(location.timer) * 60 * 1000) + 15000 -- Add on 15 seconds for teleport time.
				
		local newTask = ffxiv_task_teleport.Create()
		newTask.mapID = location.mapid
		newTask.mesh = mm.defaultMaps[location.mapid]
		ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_ASAP)
	end
end

function ffxiv_task_hunt:Init()    
    local ke_dead = ml_element:create( "Dead", c_dead, e_dead, 25 )
    self:add(ke_dead, self.overwatch_elements)
    
    local ke_flee = ml_element:create( "Flee", c_flee, e_flee, 15 )
    self:add(ke_flee, self.overwatch_elements)
    
    local ke_rest = ml_element:create( "Rest", c_rest, e_rest, 14 )
    self:add(ke_rest, self.overwatch_elements)
	
	local ke_nextLocation = ml_element:create( "NextLocation", c_nexthuntlocation, e_nexthuntlocation, 13 )
    self:add(ke_nextLocation, self.overwatch_elements)
	
	local ke_addKillTarget = ml_element:create( "AddKillTarget", c_add_hunttarget, e_add_hunttarget, 12 )
    self:add(ke_addKillTarget, self.overwatch_elements)

	local ke_atMarker = ml_element:create( "AtMarker", c_athuntmarker, e_athuntmarker, 10 )
    self:add(ke_atMarker, self.overwatch_elements)
	
    local ke_nextMarker = ml_element:create( "NextMarker", c_nexthuntmarker, e_nexthuntmarker, 20 )
    self:add(ke_nextMarker, self.process_elements)
	
    self:AddTaskCheckCEs()
end

function ffxiv_task_hunt.GUIVarUpdate(Event, NewVals, OldVals)
    for k,v in pairs(NewVals) do
        if ( 	k == "gHuntMapID" or
				k == "gHuntMapTimer" or
				k == "gHuntMarkerRandomize" or 
				k == "gHuntLocations" or
				k == "gHuntMapID" or
				k == "gHuntMapTimer" or
				k == "gHuntMarkerStyle" or
				k == "gHuntSRankHP" or
				k == "gHuntSRankAllies" or
				k == "gHuntSRankMaxWait" or
				k == "gHuntSRankShout" or
				k == "gHuntSRankSound" or
				k == "gHuntARankHP" or
				k == "gHuntARankAllies" or
				k == "gHuntARankMaxWait" or
				k == "gHuntARankShout" or
				k == "gHuntARankSound" or
				k == "gHuntBRankWaitTime" or
				k == "gHuntBRankShout" or
				k == "gHuntBRankSound" )
		then
            Settings.FFXIVMINION[tostring(k)] = v
        end
    end
    GUI_RefreshWindow(ffxiv_task_hunt.mainwindow.name)
end

function ffxiv_task_hunt.UIInit()
	
	if (Settings.FFXIVMINION.gHuntLocations == nil) then
		Settings.FFXIVMINION.gHuntLocations = {}
	end
	if ( Settings.FFXIVMINION.gHuntMapID == nil ) then
		Settings.FFXIVMINION.gHuntMapID = ""
	end
	if ( Settings.FFXIVMINION.gHuntMapTimer == nil ) then
		Settings.FFXIVMINION.gHuntMapTimer = ""
	end
	if ( Settings.FFXIVMINION.gHuntMarkerStyle == nil ) then
		Settings.FFXIVMINION.gHuntMarkerStyle = "Marker List"
	end
	
	if ( Settings.FFXIVMINION.gHuntSRankHP == nil ) then
		Settings.FFXIVMINION.gHuntSRankHP = 1
	end
	if ( Settings.FFXIVMINION.gHuntSRankAllies == nil ) then
		Settings.FFXIVMINION.gHuntSRankAllies = 12
	end
	if ( Settings.FFXIVMINION.gHuntSRankMaxWait == nil ) then
		Settings.FFXIVMINION.gHuntSRankMaxWait = 120
	end
	if ( Settings.FFXIVMINION.gHuntSRankShout == nil ) then
		Settings.FFXIVMINION.gHuntSRankShout = "0"
	end
	if ( Settings.FFXIVMINION.gHuntSRankSound == nil ) then
		Settings.FFXIVMINION.gHuntSRankSound = "0"
	end
	
	if ( Settings.FFXIVMINION.gHuntARankHP == nil ) then
		Settings.FFXIVMINION.gHuntARankHP = 1
	end
	if ( Settings.FFXIVMINION.gHuntARankAllies == nil ) then
		Settings.FFXIVMINION.gHuntARankAllies = 2
	end
	if ( Settings.FFXIVMINION.gHuntARankMaxWait == nil ) then
		Settings.FFXIVMINION.gHuntARankMaxWait = 120
	end
	if ( Settings.FFXIVMINION.gHuntARankShout == nil ) then
		Settings.FFXIVMINION.gHuntARankShout = "0"
	end
	if ( Settings.FFXIVMINION.gHuntARankSound == nil ) then
		Settings.FFXIVMINION.gHuntARankSound = "0"
	end
	
	if ( Settings.FFXIVMINION.gHuntBRankWaitTime == nil ) then
		Settings.FFXIVMINION.gHuntBRankWaitTime = 0
	end
	if ( Settings.FFXIVMINION.gHuntBRankShout == nil ) then
		Settings.FFXIVMINION.gHuntBRankShout = "0"
	end
	if ( Settings.FFXIVMINION.gHuntBRankSound == nil ) then
		Settings.FFXIVMINION.gHuntBRankSound = "0"
	end
	
	GUI_NewWindow(ffxiv_task_hunt.mainwindow.name,cp.mainwindow.x,cp.mainwindow.y,cp.mainwindow.w,ffxiv_task_hunt.mainwindow.name.h)
	GUI_NewNumeric(ffxiv_task_hunt.mainwindow.name,"HP % <=",			"gHuntSRankHP",		"S-Rank Hunt")
	GUI_NewNumeric(ffxiv_task_hunt.mainwindow.name,"Nearby Allies >",	"gHuntSRankAllies", "S-Rank Hunt")
	GUI_NewNumeric(ffxiv_task_hunt.mainwindow.name,"Max Wait (s)",		"gHuntSRankMaxWait", "S-Rank Hunt")
	GUI_NewCheckbox(ffxiv_task_hunt.mainwindow.name,"Play Sound",		"gHuntSRankSound", "S-Rank Hunt")
	GUI_NewCheckbox(ffxiv_task_hunt.mainwindow.name,"Perform Shout",	"gHuntSRankShout", "S-Rank Hunt")
	
	GUI_NewNumeric(ffxiv_task_hunt.mainwindow.name,"HP % <=",			"gHuntARankHP",		"A-Rank Hunt")
	GUI_NewNumeric(ffxiv_task_hunt.mainwindow.name,"Nearby Allies >",	"gHuntARankAllies", "A-Rank Hunt")
	GUI_NewNumeric(ffxiv_task_hunt.mainwindow.name,"Max Wait (s)",		"gHuntARankMaxWait", "A-Rank Hunt")
	GUI_NewCheckbox(ffxiv_task_hunt.mainwindow.name,"Play Sound",		"gHuntARankSound", "A-Rank Hunt")
	GUI_NewCheckbox(ffxiv_task_hunt.mainwindow.name,"Perform Shout",	"gHuntARankShout", "A-Rank Hunt")
	
	GUI_NewNumeric(ffxiv_task_hunt.mainwindow.name,"Wait Time",			"gHuntBRankWaitTime","B-Rank Hunt")
	GUI_NewCheckbox(ffxiv_task_hunt.mainwindow.name,"Play Sound",		"gHuntBRankSound", "B-Rank Hunt")
	GUI_NewCheckbox(ffxiv_task_hunt.mainwindow.name,"Perform Shout",	"gHuntBRankShout", "B-Rank Hunt")
	
    GUI_NewField(ffxiv_task_hunt.mainwindow.name,"Map ID",				"gHuntMapID","New Location")
	GUI_NewNumeric(ffxiv_task_hunt.mainwindow.name,"Map Time (minutes)","gHuntMapTimer","New Location")
	GUI_NewComboBox(ffxiv_task_hunt.mainwindow.name,"Map Marker Style",	"gHuntMarkerStyle","New Location", "Marker List,Randomize")	
	GUI_NewButton(ffxiv_task_hunt.mainwindow.name,"Add Location",		"ffxiv_huntAddLocation",	"New Location")

	GUI_UnFoldGroup(ffxiv_task_hunt.mainwindow.name,"New Location" )
	GUI_SizeWindow(ffxiv_task_hunt.mainwindow.name,ffxiv_task_hunt.mainwindow.width,ffxiv_task_hunt.mainwindow.height)
	GUI_WindowVisible(ffxiv_task_hunt.mainwindow.name, false)
	
	gHuntLocations = Settings.FFXIVMINION.gHuntLocations
	gHuntMapID = Settings.FFXIVMINION.gHuntMapID
	gHuntMapTimer = Settings.FFXIVMINION.gHuntMapTimer
	gHuntMarkerStyle = Settings.FFXIVMINION.gHuntMarkerStyle
	gHuntSRankHP = Settings.FFXIVMINION.gHuntSRankHP
	gHuntSRankAllies = Settings.FFXIVMINION.gHuntSRankAllies
	gHuntSRankMaxWait = Settings.FFXIVMINION.gHuntSRankMaxWait
	gHuntSRankShout = Settings.FFXIVMINION.gHuntSRankShout
	gHuntSRankSound = Settings.FFXIVMINION.gHuntSRankSound
	gHuntARankHP = Settings.FFXIVMINION.gHuntARankHP
	gHuntARankAllies = Settings.FFXIVMINION.gHuntARankAllies
	gHuntARankMaxWait = Settings.FFXIVMINION.gHuntARankMaxWait
	gHuntARankShout = Settings.FFXIVMINION.gHuntARankShout
	gHuntARankSound = Settings.FFXIVMINION.gHuntARankSound
	gHuntBRankWaitTime = Settings.FFXIVMINION.gHuntBRankWaitTime
	gHuntBRankShout = Settings.FFXIVMINION.gHuntBRankShout
	gHuntBRankSound = Settings.FFXIVMINION.gHuntBRankSound
	
	ffxiv_task_hunt.SetupMarkers()
end

function ffxiv_task_hunt.SetupMarkers()
    local huntMarker = ml_marker:Create("huntTemplate")
	huntMarker:SetType(strings[gCurrentLanguage].huntMarker)
	--huntMarker:AddField("string", strings[gCurrentLanguage].contentIDEquals, "")
	--huntMarker:AddField("string", strings[gCurrentLanguage].NOTcontentIDEquals, "")
    huntMarker:SetTime(300)
    huntMarker:SetMinLevel(1)
    huntMarker:SetMaxLevel(50)
	--huntMarker:SetColor({r = 70, g = 240, b = 10})
    ml_marker_mgr.AddMarkerTemplate(huntMarker)
    ml_marker_mgr.RefreshMarkerTypes()
	ml_marker_mgr.RefreshMarkerNames()
end

function ffxiv_task_hunt.AddHuntLocation()
	local list = gHuntLocations
	local key = TableSize(list) + 1
	
	local location = {
		mapid = gHuntMapID,
		timer = gHuntMapTimer,
		randomize = gHuntMarkerStyle,
	}
	
	list[tostring(key)] = location
	gHuntLocations = list
	Settings.FFXIVMINION.gHuntLocations = gHuntLocations
	ffxiv_task_hunt.RefreshHuntLocations()
end

function ffxiv_task_hunt.RemoveHuntLocation(key)
	local list = gHuntLocations
	local newList = {}
	local newKey = 1
	
	--Rebuild the list without the unwanted key, rather than actually remove it, to retain the integer index.
	for k,v in spairs(list) do
		if (k ~= key and k == tostring(newKey)) then
			newList[tostring(newKey)] = v
		end
		newKey = newKey + 1
	end
	
	gHuntLocations = newList
	Settings.FFXIVMINION.gHuntLocations = gHuntLocations
	ffxiv_task_hunt.RefreshHuntLocations()
end


function ffxiv_task_hunt.RefreshHuntLocations()
	local winName = ffxiv_task_hunt.mainwindow.name
	local tabName = "Locations"
	local list = gHuntLocations
	
	GUI_DeleteGroup(winName,tabName)
	if (TableSize(list) > 0) then
		for k,v in spairs(list) do
			GUI_NewButton(winName, v.mapid,	"ffxiv_huntRemoveLocation"..tostring(k), tabName)
		end
		GUI_UnFoldGroup(winName,tabName)
	end
	
	GUI_SizeWindow(winName,ffxiv_task_hunt.mainwindow.width,ffxiv_task_hunt.mainwindow.height)
	GUI_RefreshWindow(winName)
end

function ffxiv_task_hunt.ShowMenu()
	local wnd = GUI_GetWindowInfo(ffxivminion.Windows.Main.Name)	
    GUI_MoveWindow( ffxiv_task_hunt.mainwindow.name, wnd.x+wnd.width,wnd.y) 
    GUI_WindowVisible( ffxiv_task_hunt.mainwindow.name,true)	
	ffxiv_task_hunt.RefreshHuntLocations()
	gHuntMapID = Player.localmapid
end

function ffxiv_task_hunt.HandleButtons( Event, Button )	
	if ( Event == "GUI.Item" and string.find(Button,"ffxiv_hunt") ~= nil ) then
		if (Button == "ffxiv_huntAddLocation") then
			ffxiv_task_hunt.AddHuntLocation()
		end
		
		if (string.find(Button,"ffxiv_huntRemoveLocation") ~= nil) then
			local key = Button:gsub("ffxiv_huntRemoveLocation","")
			ffxiv_task_hunt.RemoveHuntLocation(key)
		end
	end
end
RegisterEventHandler("GUI.Item",		ffxiv_task_hunt.HandleButtons)
RegisterEventHandler("HuntManager.toggle", ffxiv_task_hunt.ShowMenu)
RegisterEventHandler("GUI.Update",ffxiv_task_hunt.GUIVarUpdate)