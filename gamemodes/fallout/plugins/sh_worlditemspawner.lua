local PLUGIN = PLUGIN
PLUGIN.name = "World Item Spawner"
PLUGIN.author = "Black Tea"
PLUGIN.desc = "World Item Spawner."
PLUGIN.itempoints = PLUGIN.itempoints or {}
PLUGIN.spawngroups = { -- Example is based on HL2RP items.
	["default"] = {
		{"bleach"},
	},
	["example"] = {
		{"ration"},
	},
	["all"] = { -- for machine plugin.
		{"Empty Abstinthe Bottle"},
		{"Duct Tape"},
		{"Empty Bottle"},
		{"Pressure Cooker"},
		{"Scrap Electronics"},
		{"Toaster"},
		{"Steam Guage Assembly"},
		{"Jar of Gunpowder"},
		{"Scrap Metal"},
		{"Toy Bot"},
		{"Ballistic Fiber"},
		{"Circuitry"},
		{"Steel"},
		{"Sensor Module"},
		{"Nuclear Material"},
		{"Toy Gutsy"},
		{"Trigger Kit"},
		{"Scrap Wood"},
		{"Broken Telephone"},
		{"Car Tire"},
		{"Desk Lamp"},
		{"Empty Soda"},
		{"A Can of Paint"},
		{"A Metal Bucket"},
		{"A Clock"},
		{"A Metal Pot"},
		{"A Metal Pan"},
		{"A Screwdriver"},
		{"A Wrench"},
		{"A Shoe"},
		{"A Saw Blade"},
		{"Empty Syringe"},
		{"A Pack of Cigarettes"},
		{"Per-War Money"},
		{"Insta Mash"},
		{"Dirty Water"},
		{"Wine"},
		{"Absinthe"},
		{"Whiskey"},
		{"Vodka"},
		{"Nuka Cola"},
		{"Sunset Sarsaparilla"},
		{"Purified Water"},
		{"Radioactive Gumdrops"},
		{"Bubblegum"},
		{"Blowtorch Fuel"},
		{"Dandy Boy Apples"},
		{"Cram"},
		{"Potato Chips"},
		{"Pork N Beans"},
		{"Bandages"},
		{"Tweezers"},
		{"Suture Needle"},
		{"Burn Cream"},
		{"Painkillers"},
		{"Buffout"},
		{"Mentats"},
		{"Stimpak"},
		{"Med-X"},
		{"Rebound"},

	}
}

PLUGIN.spawnrate = 120
PLUGIN.maxitems = 100
PLUGIN.itemsperspawn = 1
PLUGIN.spawneditems = PLUGIN.spawneditems or {}

if SERVER then
	local spawntime = 1

	function PLUGIN:ItemShouldSave(entity)
		return (!entity.generated)
	end

	function PLUGIN:Think()
		if spawntime > CurTime() then return end
		spawntime = CurTime() + self.spawnrate
		for k, v in ipairs(self.spawneditems) do
			if (!v:IsValid()) then
				table.remove(self.spawneditems, k)
			end
		end

		if #self.spawneditems >= self.maxitems then return end

		for i = 1, self.itemsperspawn do
			if #self.spawneditems >= self.maxitems then

				return
			end

			local v = table.Random(self.itempoints)

			if (!v) then
				return
			end


			local data = {}
			data.start = v[1]
			data.endpos = data.start + Vector(0, 0, 1)
			data.filter = client
			data.mins = Vector(-16, -16, 0)
			data.maxs = Vector(16, 16, 16)
			local trace = util.TraceHull(data)

			if trace.Entity:IsValid() then
				continue
			end

			local idat = table.Random(self.spawngroups[v[2]]) or self.spawngroup["default"]
			local item = nut.item.Spawn(v[1] + Vector( math.Rand(-8,8), math.Rand(-8,8), 10 ), AngleRand(), idat[1], idat[2] or {})
			item.generated = true
			table.insert( self.spawneditems, item )
		end
	end

	function PLUGIN:LoadData()
		self.itempoints = nut.util.ReadTable("itempoints")
	end

	function PLUGIN:SaveData()
		for k, v in ipairs(self.spawneditems) do
			v:Remove()
		end
		nut.util.WriteTable("itempoints", self.itempoints)
	end

else

	netstream.Hook("nut_DisplaySpawnPoints", function(data)
		for k, v in pairs(data) do
			local emitter = ParticleEmitter( v[1] )
			local smoke = emitter:Add( "sprites/glow04_noz", v[1] )
			smoke:SetVelocity( Vector( 0, 0, 1 ) )
			smoke:SetDieTime(10)
			smoke:SetStartAlpha(255)
			smoke:SetEndAlpha(255)
			smoke:SetStartSize(64)
			smoke:SetEndSize(64)
			smoke:SetColor(255,186,50)
			smoke:SetAirResistance(300)
		end
	end)

end

nut.command.Register({
	adminOnly = true,
	syntax = "<string itemgroup>",
	onRun = function(client, arguments)
		local trace = client:GetEyeTraceNoCursor()
		local hitpos = trace.HitPos + trace.HitNormal*5
		local spawngroup = arguments[1] or "default"
		table.insert( PLUGIN.itempoints, { hitpos, spawngroup } )
		nut.util.Notify( "You added ".. spawngroup .. " item spawner." )
	end
}, "itemspawnadd")

nut.command.Register({
	adminOnly = true,
	onRun = function(client, arguments)
		local trace = client:GetEyeTraceNoCursor()
		local hitpos = trace.HitPos + trace.HitNormal*5
		local range = arguments[1] or 128
		local mt = 0
		for k, v in pairs( PLUGIN.itempoints ) do
			local distance = v[1]:Distance( hitpos )
			if distance <= tonumber(range) then
				PLUGIN.itempoints[k] = nil
				mt = mt + 1
			end
		end
		nut.util.Notify( mt .. " item spawners has been removed.")
	end
}, "itemspawnremove")

nut.command.Register({
	adminOnly = true,
	onRun = function(client, arguments)
		if SERVER then
			netstream.Start(client, "nut_DisplaySpawnPoints", PLUGIN.itempoints)
			nut.util.Notify( "Displayed All Points for 10 secs." )
		end
	end
}, "itemspawndisplay")