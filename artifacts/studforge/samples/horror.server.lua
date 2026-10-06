-- Test horror.server.lua
-- STUDForge place script. Paste into ServerScriptService as a Script.
-- Prompt: self-test prompt for horror

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local TITLE = "Test horror"
local GENRE = "horror"

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
part({ Name = "Lobby", Size = Vector3.new(60, 1, 60), CFrame = CFrame.new(0, 1, 0), Color = Color3.fromRGB(18, 18, 22), Parent = map })
for i = 1, 8 do
	part({
		Name = "Cover" .. i,
		Size = Vector3.new(6, 8, 2),
		CFrame = CFrame.new(math.cos(i) * 18, 5, math.sin(i) * 18),
		Color = Color3.fromRGB(32, 32, 38),
		Parent = map,
	})
end
local seeker
local function pickSeeker()
	local list = Players:GetPlayers()
	if #list == 0 then
		return nil
	end
	return list[math.random(1, #list)]
end
local function hookTag(player, character)
	local root = character:WaitForChild("HumanoidRootPart", 5)
	if not root then
		return
	end
	root.Touched:Connect(function(hit)
		if seeker ~= player then
			return
		end
		local other = playerFromHit(hit)
		if other and other ~= player then
			other.leaderstats.Score.Value += 0
			notify(other, "Caught")
		end
	end)
end
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		hookTag(player, character)
	end)
end)
task.spawn(function()
	while true do
		seeker = pickSeeker()
		for _, player in Players:GetPlayers() do
			notify(player, seeker and (seeker.Name .. " is the seeker") or "Waiting")
		end
		task.wait(60)
		for _, player in Players:GetPlayers() do
			if player ~= seeker then
				player.leaderstats.Score.Value += 1
				notify(player, "Survived the round")
			end
		end
		task.wait(8)
	end
end)

print("[STUDForge] " .. TITLE .. " (" .. GENRE .. ") loaded")
