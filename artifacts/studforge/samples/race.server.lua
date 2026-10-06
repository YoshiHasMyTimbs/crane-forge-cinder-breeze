-- Test race.server.lua
-- STUDForge place script. Paste into ServerScriptService as a Script.
-- Prompt: self-test prompt for race

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local TITLE = "Test race"
local GENRE = "race"

local remotes = ReplicatedStorage:FindFirstChild("StudForgeRemotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "StudForgeRemotes"
	remotes.Parent = ReplicatedStorage
end
local stateEvent = remotes:FindFirstChild("State")
if not stateEvent then
	stateEvent = Instance.new("RemoteEvent")
	stateEvent.Name = "State"
	stateEvent.Parent = remotes
end

local function notify(player, message)
	stateEvent:FireClient(player, message)
end

local function ensureLeaderstats(player)
	if player:FindFirstChild("leaderstats") then
		return
	end
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = 0
	coins.Parent = stats
	local score = Instance.new("IntValue")
	score.Name = "Score"
	score.Value = 0
	score.Parent = stats
	stats.Parent = player
end

Players.PlayerAdded:Connect(function(player)
	ensureLeaderstats(player)
	player.CharacterAdded:Connect(function()
		player:SetAttribute("Won", nil)
	end)
end)
for _, player in Players:GetPlayers() do
	ensureLeaderstats(player)
end

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = props.Material or Enum.Material.SmoothPlastic
	p.Color = props.Color or Color3.fromRGB(40, 44, 56)
	p.Size = props.Size or Vector3.new(8, 1, 8)
	p.CFrame = props.CFrame or CFrame.new(0, 2, 0)
	p.Name = props.Name or "Part"
	p.Parent = props.Parent
	return p
end

local function clearMap()
	local old = workspace:FindFirstChild("StudForgeMap")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "StudForgeMap"
	folder.Parent = workspace
	part({
		Name = "SpawnPad",
		Size = Vector3.new(24, 1, 24),
		CFrame = CFrame.new(0, 1, 0),
		Color = Color3.fromRGB(36, 40, 52),
		Parent = folder,
	})
	return folder
end

local function playerFromHit(hit)
	local model = hit and hit.Parent
	if not model then
		return nil
	end
	return Players:GetPlayerFromCharacter(model)
end

local map = clearMap()
for i = 0, 7 do
	local angle = i / 8 * math.pi * 2
	local cp = part({
		Name = "Gate" .. i,
		Size = Vector3.new(10, 1, 6),
		CFrame = CFrame.new(math.cos(angle) * 40, 2, math.sin(angle) * 40),
		Color = i == 0 and Color3.fromRGB(255, 210, 60) or Color3.fromRGB(70, 130, 255),
		Parent = map,
	})
	cp.Touched:Connect(function(hit)
		local player = playerFromHit(hit)
		if not player then
			return
		end
		local nextGate = player:GetAttribute("NextGate") or 0
		if i ~= nextGate then
			return
		end
		if i == 7 then
			local lap = (player:GetAttribute("Lap") or 1) + 1
			player:SetAttribute("Lap", lap)
			player:SetAttribute("NextGate", 0)
			if lap > 3 then
				player.leaderstats.Score.Value += 10
				notify(player, "Finished")
			else
				notify(player, "Lap " .. lap)
			end
		else
			player:SetAttribute("NextGate", i + 1)
			notify(player, "Gate " .. (i + 1))
		end
	end)
end

print("[STUDForge] " .. TITLE .. " (" .. GENRE .. ") loaded")
