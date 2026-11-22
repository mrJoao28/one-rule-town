--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetworkService = {}

local remoteNames = {
	"GameState",
	"PlayerState",
	"DataUpdated",
	"PurchaseRequest",
	"CosmeticAction",
	"UseRevive",
}

function NetworkService:Initialize()
	local existing = ReplicatedStorage:FindFirstChild("Remotes")
	if existing then
		existing:Destroy()
	end

	local folder = Instance.new("Folder")
	folder.Name = "Remotes"
	folder.Parent = ReplicatedStorage

	for _, name in remoteNames do
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
	end

	local getSnapshot = Instance.new("RemoteFunction")
	getSnapshot.Name = "GetSnapshot"
	getSnapshot.Parent = folder

	self.Folder = folder
end

function NetworkService:GetEvent(name: string): RemoteEvent
	return self.Folder:WaitForChild(name) :: RemoteEvent
end

function NetworkService:GetFunction(name: string): RemoteFunction
	return self.Folder:WaitForChild(name) :: RemoteFunction
end

return NetworkService
