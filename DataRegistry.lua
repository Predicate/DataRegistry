do
	local addon, namespace = ...
	_G[addon] = _G[addon] or {}
	setfenv(1, setmetatable(namespace, { __index = _G }))
end
local callbacks = LibStub:GetLibrary("CallbackHandler-1.0"):New(DataRegistry)

local attributestorage, namestorage, proxystorage = {}, {}, {}

local domt = {
	__metatable = "access denied",
	__index = function(self, key) return attributestorage[self] and attributestorage[self][key] end,
	__newindex = function(self, key, value)
		if not attributestorage[self] then attributestorage[self] = {} end
		if attributestorage[self][key] == value then return end
		attributestorage[self][key] = value
		local name = namestorage[self]
		if not name then return end
		callbacks:Fire("DataRegistry_AttributeChanged", name, key, value, self)
		callbacks:Fire("DataRegistry_AttributeChanged_"..name, name, key, value, self)
		callbacks:Fire("DataRegistry_AttributeChanged_"..name.."_"..key, name, key, value, self)
		callbacks:Fire("DataRegistry_AttributeChanged__"..key, name, key, value, self)
	end
}


function DataRegistry:NewDataObject(name, dataobj)
	if proxystorage[name] then return end

	if dataobj then
		assert(type(dataobj) == "table", "Invalid dataobj, must be nil or a table")
		attributestorage[dataobj] = {}
		for i,v in pairs(dataobj) do
			attributestorage[dataobj][i] = v
			dataobj[i] = nil
		end
	end
	dataobj = setmetatable(dataobj or {}, domt)
	proxystorage[name], namestorage[dataobj] = dataobj, name
	callbacks:Fire("DataRegistry_DataObjectCreated", name, dataobj)
	return dataobj
end

function DataRegistry:DataObjectIterator()
	return pairs(proxystorage)
end

function DataRegistry:GetDataObjectByName(dataobjectname)
	return proxystorage[dataobjectname]
end

function DataRegistry:GetNameByDataObject(dataobject)
	return namestorage[dataobject]
end

function DataRegistry:DestroyDataObject(dataobject_or_name)
	local t = type(dataobject_or_name)
	assert(t == "string" or t == "table", "Usage: DataRegistry:pairs('dataobjectname') or DataRegistry:pairs(dataobject)")
	local dataobj = proxystorage[dataobject_or_name] or dataobject_or_name
	assert(attributestorage[dataobj], "Data object not found")
	local name = namestorage[dataobj]
	attributestorage[dataobj] = nil
	namestorage[dataobj] = nil
	proxystorage[name] = nil
	callbacks:Fire("DataRegistry_DataObjectDestroyed", name, dataobj)
end


local next = pairs(attributestorage)
function DataRegistry:pairs(dataobject_or_name)
	local t = type(dataobject_or_name)
	assert(t == "string" or t == "table", "Usage: DataRegistry:pairs('dataobjectname') or DataRegistry:pairs(dataobject)")
	local dataobj = proxystorage[dataobject_or_name] or dataobject_or_name
	assert(attributestorage[dataobj], "Data object not found")
	return next, attributestorage[dataobj], nil
end

local ipairs_iter = ipairs(attributestorage)
function DataRegistry:ipairs(dataobject_or_name)
	local t = type(dataobject_or_name)
	assert(t == "string" or t == "table", "Usage: DataRegistry:ipairs('dataobjectname') or DataRegistry:ipairs(dataobject)")
	local dataobj = proxystorage[dataobject_or_name] or dataobject_or_name
	assert(attributestorage[dataobj], "Data object not found")
	return ipairs_iter, attributestorage[dataobj], 0
end
