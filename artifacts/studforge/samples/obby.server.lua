-- Test obby.server.lua
-- STUDForge place script. Paste into ServerScriptService as a Script.
-- Prompt: self-test prompt for obby

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local TITLE = "Test obby"
local GENRE = "obby"

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
local checkpoints = {}
for i = 1, 12 do
	local platform = part({
		Name = "Jump" .. i,
		Size = Vector3.new(10, 1, 10),
		CFrame = CFrame.new(i * 14, 2 + (i % 3) * 4, 0),
		Color = Color3.fromRGB(255, 70 + i * 8, 40),
		Material = Enum.Material.Neon,
		Parent = map,
	})
	if i % 3 == 0 then
		local cp = part({
			Name = "Checkpoint" .. i,
			Size = Vector3.new(6, 1, 6),
			CFrame = platform.CFrame * CFrame.new(0, 2, 0),
			Color = Color3.fromRGB(80, 220, 140),
			Parent = map,
		})
		table.insert(checkpoints, cp)
		cp.Touched:Connect(function(hit)
			local player = playerFromHit(hit)
			if not player then
				return
			end
			player:SetAttribute("Checkpoint", i)
			notify(player, "Checkpoint " .. i)
		end)
	end
end

local win = part({
	Name = "WinPad",
	Size = Vector3.new(12, 1, 12),
	CFrame = CFrame.new(13 * 14, 8, 0),
	Color = Color3.fromRGB(255, 208, 60),
	Material = Enum.Material.Neon,
	Parent = map,
})
win.Touched:Connect(function(hit)
	local player = playerFromHit(hit)
	if not player or player:GetAttribute("Won") then
		return
	end
	player:SetAttribute("Won", true)
	player.leaderstats.Coins.Value += 25
	player.leaderstats.Score.Value += 1
	notify(player, "Clear. +25 coins")
end)

task.spawn(function()
	while true do
		task.wait(90)
		for _, player in Players:GetPlayers() do
			player:SetAttribute("Won", nil)
			notify(player, "Timer reset")
		end
	end
end)

print("[STUDForge] " .. TITLE .. " (" .. GENRE .. ") loaded")
