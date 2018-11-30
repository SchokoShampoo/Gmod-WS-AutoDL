local old_addons = {}
local new_addons = {}
local collections = {}


--Creating or reading addons.txt
if not file.Exists("workshop\\addons.txt", "DATA") then
	file.CreateDir("workshop")
	file.Write("workshop\\addons.txt", "0")
else
	local addonList = file.Read("workshop\\addons.txt", "DATA")
	for i in string.gmatch(addonList, "%S+") do
		table.insert(old_addons, i)
	end
end

--Creating workshop.txt if it doesn't exists
if not file.Exists("workshop\\workshop.txt", "DATA") then
	file.CreateDir("workshop")
	file.Write("workshop\\workshop.txt", "0")
end

--running resource.AddWorkshop for every addon in the addons.txt
local function AddWorkshopAddons()
	local addons = file.Read("workshop\\addons.txt", "DATA")
	for a in string.gmatch(addons, "%S+") do
		resource.AddWorkshop(a)
	end
end

--adding addon to addon.txt
local function addAddon(id)
	if not table.HasValue(new_addons, id) then
		table.insert(new_addons, id)
	end
end

--comparing new and old addon lists and overwritting old list if necassary
local function checkDifferences()
	local diff = {}
	for _, k in ipairs(new_addons) do
		diff[k] = true
	end

	for _, k in ipairs(old_addons) do
		if diff[k] == nil then
			diff[k] = true
		else
			diff[k] = nil
		end
	end

	if diff ~= {} then
		local addons = file.Open("workshop\\addons.txt", "w", "DATA")
		for _, k in ipairs(new_addons) do
			addons:Write(k.."\n")
		end
		old_addons = new_addons
	end
end

--Adding a whole collection to addons.txt
function resource.AddWorkshopCollection(id)
	http.Fetch("http://steamcommunity.com/sharedfiles/filedetails/?id=" .. id, function(page)
		for k in page:gmatch([[<div id="sharedfile_(.-)" class="collectionItem">]]) do
			addAddon(k)
		end
	end)
end

--Adding all recursive collections to addons.txt
function resource.GetWorkshopCollection(id)
	table.insert(collections, id)
	http.Fetch("http://steamcommunity.com/sharedfiles/filedetails/?id=" .. id, function(page)
		for cpage in page:gmatch("childrenTitle(.*)") do
			for k in cpage:gmatch([[<div id="sharedfile_(.-)" class="workshopItemPreviewHolder  ">]]) do
				if not table.HasValue(collections, k) then
					resource.GetWorkshopCollection (k)
				end
			end
		end
	end)
	resource.AddWorkshopCollection(id)
end

--Adding all Addons from the Server to addons.txt
function resource.AddServerWorkshop()
	for _, addonData in ipairs(engine.GetAddons()) do
		addAddon(addonData.wsid)
	end
end

--Checking the collection every new Round and updating the needed addons
hook.Add("TTTBeginRound", "LoadWorkshop", function()
	local workshop = file.Read("workshop\\workshop.txt", "DATA")
	for i in string.gmatch(workshop, "%S+") do
		if i == "0" then
			resource.AddServerWorkshop()
			break
		end
		resource.GetWorkshopCollection(i)
	end
	checkDifferences()
	collections = {}
	AddWorkshopAddons()
	new_addons = {}
end)

hook.Add("Initialize", "LoadWorkshopInit", AddWorkshopAddons())
