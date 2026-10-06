-- StatusBanner.client.lua
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
