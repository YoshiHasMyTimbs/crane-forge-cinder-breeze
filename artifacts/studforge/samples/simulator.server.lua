-- Test simulator.server.lua
-- STUDForge place script. Paste into ServerScriptService as a Script.
-- Prompt: self-test prompt for simulator

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local TITLE = "Test simulator"
local GENRE = "simulator"

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
local mint = part({
	Name = "MintPad",
	Size = Vector3.new(16, 1, 16),
	CFrame = CFrame.new(0, 2, 0),
	Color = Color3.fromRGB(40, 180, 120),
	Material = Enum.Material.Neon,
	Parent = map,
})
local rebirth = part({ Name = "Rebirth", Size = Vector3.new(10, 1, 10), CFrame = CFrame.new(0, 2, 22), Color = Color3.fromRGB(160, 90, 255), Parent = map })
local debounce = {}
mint.Touched:Connect(function(hit)
	local player = playerFromHit(hit)
	if not player or debounce[player] then
		return
	end
	debounce[player] = true
	local mult = player:GetAttribute("MintMult") or 1
	player.leaderstats.Coins.Value += mult
	player.leaderstats.Score.Value += 1
	task.delay(0.35, function()
		debounce[player] = nil
	end)
end)
rebirth.Touched:Connect(function(hit)
	local player = playerFromHit(hit)
	if not player then
		return
	end
	if player.leaderstats.Coins.Value < 100 then
		notify(player, "Need 100 coins to rebirth")
		return
	end
	player.leaderstats.Coins.Value = 0
	player:SetAttribute("MintMult", (player:GetAttribute("MintMult") or 1) + 1)
	notify(player, "Rebirth complete")
end)

print("[STUDForge] " .. TITLE .. " (" .. GENRE .. ") loaded")
