// Shared place-script generator. Roblox APIs are emitted, not executed here.
function buildPlaceScript(title, genre, prompt) {
  const safe = String(title || "Untitled Place").replace(/"/g, "").slice(0, 48);
  const note = String(prompt || "").replace(/--/g, "").slice(0, 240);
  const kind = ["obby", "tycoon", "simulator", "horror", "race", "arena"].includes(genre) ? genre : "obby";
  const header = `-- ${safe}.server.lua
-- STUDForge place script. Paste into ServerScriptService as a Script.
-- Prompt: ${note}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local TITLE = "${safe}"
local GENRE = "${kind}"

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

`;
  const bodies = {
    obby: `local map = clearMap()
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
`,
    tycoon: `local map = clearMap()
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
`,
    simulator: `local map = clearMap()
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
`,
    horror: `local map = clearMap()
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
`,
    race: `local map = clearMap()
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
`,
    arena: `local map = clearMap()
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
`,
  };
  return header + bodies[kind] + `\nprint("[STUDForge] " .. TITLE .. " (" .. GENRE .. ") loaded")\n`;
}

function clientBannerScript() {
  return `-- StatusBanner.client.lua
-- Paste into StarterPlayerScripts as a LocalScript.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("StudForgeRemotes")
local stateEvent = remotes:WaitForChild("State")

local gui = Instance.new("ScreenGui")
gui.Name = "StudForgeStatus"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.Size = UDim2.new(0, 420, 0, 36)
label.Position = UDim2.new(0.5, -210, 0, 16)
label.BackgroundColor3 = Color3.fromRGB(16, 18, 24)
label.TextColor3 = Color3.fromRGB(255, 176, 60)
label.Font = Enum.Font.GothamMedium
label.TextSize = 16
label.Text = "STUDForge ready"
label.Parent = gui

stateEvent.OnClientEvent:Connect(function(message)
	label.Text = tostring(message)
end)
`;
}

const REQUIRED = ["Players", "leaderstats", "StudForgeMap", "SpawnPad", "State", "print("];

function checkScript(source, genre) {
  const errors = [];
  const code = source.replace(/--.*$/gm, "");
  if (!source.startsWith("--")) errors.push("missing header");
  for (const token of REQUIRED) {
    if (!source.includes(token)) errors.push("missing " + token);
  }
  if (!source.includes('GENRE = "' + genre + '"')) errors.push("genre stamp mismatch");
  const opens = (code.match(/\b(function|if|while|for)\b/g) || []).length;
  const ends = (code.match(/\bend\b/g) || []).length;
  if (ends !== opens) errors.push("end count " + ends + " != open count " + opens);
  if (code.includes("Humanoid.Touched")) errors.push("invalid Humanoid.Touched");
  return errors;
}

if (typeof module !== "undefined") {
  module.exports = { buildPlaceScript, clientBannerScript, checkScript };
}
