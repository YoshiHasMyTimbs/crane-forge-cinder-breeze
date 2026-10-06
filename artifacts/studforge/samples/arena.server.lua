-- Test arena.server.lua
-- STUDForge place script. Paste into ServerScriptService as a Script.
-- Prompt: self-test prompt for arena

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local TITLE = "Test arena"
local GENRE = "arena"

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
part({ Name = "Arena", Size = Vector3.new(70, 1, 70), CFrame = CFrame.new(0, 1, 0), Color = Color3.fromRGB(50, 36, 70), Parent = map })
for i = 1, 6 do
	part({
		Name = "Pillar" .. i,
		Size = Vector3.new(4, 10, 4),
		CFrame = CFrame.new(math.cos(i) * 20, 6, math.sin(i) * 20),
		Color = Color3.fromRGB(90, 70, 130),
		Parent = map,
	})
end
local it
local timeAsIt = {}
local function setIt(player)
	it = player
	for _, other in Players:GetPlayers() do
		notify(other, player.Name .. " is It")
	end
end
local function hook(player, character)
	local root = character:WaitForChild("HumanoidRootPart", 5)
	if not root then
		return
	end
	root.Touched:Connect(function(hit)
		if it ~= player then
			return
		end
		local other = playerFromHit(hit)
		if other and other ~= player then
			setIt(other)
		end
	end)
end
Players.PlayerAdded:Connect(function(player)
	timeAsIt[player] = 0
	player.CharacterAdded:Connect(function(character)
		hook(player, character)
	end)
	if player.Character then
		hook(player, player.Character)
	end
end)
task.spawn(function()
	task.wait(3)
	local list = Players:GetPlayers()
	if #list > 0 then
		setIt(list[1])
	end
	local ends = os.clock() + 75
	while os.clock() < ends do
		if it then
			timeAsIt[it] = (timeAsIt[it] or 0) + 0.5
		end
		task.wait(0.5)
	end
	local best, bestTime = nil, math.huge
	for _, player in Players:GetPlayers() do
		local t = timeAsIt[player] or 0
		if t < bestTime then
			best, bestTime = player, t
		end
		notify(player, "Round over")
	end
	if best then
		best.leaderstats.Score.Value += 5
		notify(best, "Least time as It")
	end
end)

print("[STUDForge] " .. TITLE .. " (" .. GENRE .. ") loaded")
