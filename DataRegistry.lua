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

---Creates a new data object with the given name.
--Fires a callback to inform listeners of the new data object.
--If a table is passed as the second arg, its values are stored in the new data object before the callback is fired.
--@param name Name of the new data object.
--@param dataobj Optional table containing initial state for the data object.
--@return The newly created object.
function DataRegistry.NewDataObject(name, dataobj)
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

---Iterates over registered data objects.
--@return An iterator for registered data objects.
--@usage for name, dataobj in DataRegistry.DataObjectIterator() do ... end
function DataRegistry.DataObjectIterator()
	return pairs(proxystorage)
end

---Retrieves a data object by name.
--@param dataobjectname The name of the object.
--@return The data object registered by the given name, if found.
function DataRegistry.GetDataObjectByName(dataobjectname)
	return proxystorage[dataobjectname]
end

---Looks up the name of a data object.
--@param dataobject A data object to look up.
--@return The name of the data object, if found.
function DataRegistry.GetNameByDataObject(dataobject)
	return namestorage[dataobject]
end

---Destroys a registered data object.
--Fires a callback to inform listeners of the data object's destruction.
--@param dataobject_or_name The data object to be destroyed, or its registered name.
function DataRegistry.DestroyDataObject(dataobject_or_name)
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
---Iterates over the keys stored in a given data object.
--Use this instead of pairs() on registered data objects.
--@param dataobject_or_name The data object to iterate, or its registered name.
--@return An iterator for keys in the given data object.
function DataRegistry.pairs(dataobject_or_name)
	local t = type(dataobject_or_name)
	assert(t == "string" or t == "table", "Usage: DataRegistry:pairs('dataobjectname') or DataRegistry:pairs(dataobject)")
	local dataobj = proxystorage[dataobject_or_name] or dataobject_or_name
	assert(attributestorage[dataobj], "Data object not found")
	return next, attributestorage[dataobj], nil
end

local ipairs_iter = ipairs(attributestorage)
---Iterates over the integer keys stored in a given data object.
--Use this instead of ipairs() on registered data objects.
--@param dataobject_or_name The data object to iterate, or its registered name.
--@return An iterator for integer keys in the given data object.
function DataRegistry.ipairs(dataobject_or_name)
	local t = type(dataobject_or_name)
	assert(t == "string" or t == "table", "Usage: DataRegistry:ipairs('dataobjectname') or DataRegistry:ipairs(dataobject)")
	local dataobj = proxystorage[dataobject_or_name] or dataobject_or_name
	assert(attributestorage[dataobj], "Data object not found")
	return ipairs_iter, attributestorage[dataobj], 0
end
