do
	local addon, namespace = ...
	_G[addon] = _G[addon] or {}
	setfenv(1, setmetatable(namespace, { __index = _G }))
end

--Wait until one frame after PLAYER_LOGIN to look for LDB.
--Hopefully someone embedding it has loaded by then.
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function() f:SetScript("OnUpdate", function()
		f:SetScript("OnUpdate", nil)
		local ldb = LibStub("LibDataBroker-1.1", true)
		if ldb then
			for name, dobj in ldb:DataObjectIterator() do
				callbacks:Fire("DataRegistry_DataObjectCreated", name, dobj)
			end
			ldb:RegisterCallback("LibDataBroker_DataObjectCreated", function(_, name, dobj)
				callbacks:Fire("DataRegistry_DataObjectCreated", name, dobj)
			end)

			ldb:RegisterCallback("LibDataBroker_AttributeChanged", function(_, name, attr, value, dobj)
				callbacks:Fire("DataRegistry_AttributeChanged", name, attr, value, dobj)
				callbacks:Fire("DataRegistry_AttributeChanged_"..name, name, attr, value, dobj)
				callbacks:Fire("DataRegistry_AttributeChanged_"..name.."_"..attr, name, attr, value, dobj)
				callbacks:Fire("DataRegistry_AttributeChanged__"..attr, name, attr, value, dobj)
			end)
		end
	end)
end)
