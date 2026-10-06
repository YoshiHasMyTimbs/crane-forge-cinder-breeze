-- Test tycoon.server.lua
-- STUDForge place script. Paste into ServerScriptService as a Script.
-- Prompt: self-test prompt for tycoon

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local TITLE = "Test tycoon"
local GENRE = "tycoon"

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
part({ Name = "Plot", Size = Vector3.new(40, 1, 40), CFrame = CFrame.new(0, 1, 0), Color = Color3.fromRGB(48, 42, 36), Parent = map })
local dropper = part({ Name = "Dropper", Size = Vector3.new(6, 4, 6), CFrame = CFrame.new(-10, 8, 0), Color = Color3.fromRGB(180, 90, 40), Parent = map })
local collector = part({ Name = "Collector", Size = Vector3.new(8, 1, 8), CFrame = CFrame.new(12, 2, 0), Color = Color3.fromRGB(80, 200, 120), Parent = map })
local rate = 2
local button = part({ Name = "Upgrade", Size = Vector3.new(6, 1, 6), CFrame = CFrame.new(0, 2, 12), Color = Color3.fromRGB(255, 180, 40), Parent = map })
button.Touched:Connect(function(hit)
	local player = playerFromHit(hit)
	if not player then
		return
	end
	if player.leaderstats.Coins.Value < 20 then
		notify(player, "Need 20 coins")
		return
	end
	player.leaderstats.Coins.Value -= 20
	rate = math.max(0.4, rate - 0.3)
	notify(player, "Dropper faster")
end)
collector.Touched:Connect(function(hit)
	if hit.Name ~= "Ore" then
		return
	end
	hit:Destroy()
	for _, player in Players:GetPlayers() do
		player.leaderstats.Coins.Value += 1
	end
end)
task.spawn(function()
	while true do
		task.wait(rate)
		local ore = Instance.new("Part")
		ore.Name = "Ore"
		ore.Size = Vector3.new(1.4, 1.4, 1.4)
		ore.Color = Color3.fromRGB(210, 140, 60)
		ore.CFrame = dropper.CFrame * CFrame.new(0, -3, 0)
		ore.Parent = map
		Debris:AddItem(ore, 12)
	end
end)

print("[STUDForge] " .. TITLE .. " (" .. GENRE .. ") loaded")
