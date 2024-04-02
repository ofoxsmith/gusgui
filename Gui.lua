local function gusgui(gusgui_path)
GUSGUI_FILEPATH = function (path)
    return gusgui_path:gsub("/$", "") .. "/" .. path
end
dofile_once(GUSGUI_FILEPATH("class.lua"))
dofile_once(GUSGUI_FILEPATH("GuiElement.lua"))
---@module "ElementProps"
local ElementProps = dofile_once(GUSGUI_FILEPATH("ElementProps.lua"))
--- @return function
local function getIdCounter()
    local id = 1
    --- @return number
    return function()
        id = id + 1
        return id
    end
end

local GuiElements = {
    Text = dofile_once(GUSGUI_FILEPATH("elems/Text.lua")),
    Button = dofile_once(GUSGUI_FILEPATH("elems/Button.lua")),
    Image = dofile_once(GUSGUI_FILEPATH("elems/Image.lua")),
    ImageButton = dofile_once(GUSGUI_FILEPATH("elems/ImageButton.lua")),
    HLayout = dofile_once(GUSGUI_FILEPATH("elems/HLayout.lua")),
    VLayout = dofile_once(GUSGUI_FILEPATH("elems/VLayout.lua")),
    Slider = dofile_once(GUSGUI_FILEPATH("elems/Slider.lua")),
    TextInput = dofile_once(GUSGUI_FILEPATH("elems/TextInput.lua")),
    ProgressBar = dofile_once(GUSGUI_FILEPATH("elems/ProgressBar.lua")),
    Checkbox = dofile_once(GUSGUI_FILEPATH("elems/Checkbox.lua")),
}

--- @class Gui
--- @field classOverrides table
--- @field guiobj userdata
--- @field state table
--- @field enableLogging boolean
--- @field baseX integer
--- @field baseY integer
--- @field tree GuiElement[]
--- @field nextID function
--- @field ec integer
--- @field ids table
--- @operator call: Gui
local Gui = class(function(newGUI, config)
    config = config or {}
    config.state = config.state or {}
    config.gui = config.gui or GuiCreate()
    config.enableLogging = config.enableLogging or false
    config.baseX = config.baseX or 0
    config.baseY = config.baseY or 0
    newGUI.ids = {}
    newGUI.nextID = getIdCounter()
    newGUI.stateID = getIdCounter()
    newGUI.guiobj = config.gui
    newGUI.tree = {}
    newGUI.enableLogging = config.enableLogging
    newGUI.baseX = config.baseX
    newGUI.baseY = config.baseY
    newGUI.state = config.state
    newGUI.ec = 0
    newGUI.classOverrides = {}
    newGUI.screenW, newGUI.screenH = GuiGetScreenDimensions(newGUI.guiobj)
    newGUI.screenW, newGUI.screenH = math.floor(newGUI.screenW), math.floor(newGUI.screenH)
    print(("New GUSGUI Instance created (logging = %s)"):format(config.enableLogging))
end)

--- @param s string
--- @return any
function Gui:GetState(s)
    local values = {}
    for i in s:gmatch("[^/]+") do
        table.insert(values, i)
    end
    local item
    for i = 1, #values do
        local k = values[i]
        if i == 1 then
            item = self._state[k]
        else
            item = item[k]
        end
    end
    return item
end

---@param str string
---@return State
function Gui:StateStringToTable(str)
    local StateTypes = {
        Value = Gui.StateValue,
        Add = Gui.StateAdd,
        Subtract = Gui.StateSubtract,
        Divide = Gui.StateDivide,
        Multiply = Gui.StateMultiply,
        Global = Gui.StateGlobal,
    }
    ---@type string[]
    local vals = {}
    if str:find("State[a-zA-Z]+") == 1 then
        while true do
            local c = false
            str = str:gsub("%([a-zA-Z0-9,%% ]+%)", function(s)
                c = true
                ---@cast s string
                table.insert(vals, s:sub(2, -2))
                return "%%" .. #vals
            end)
            if c == false then break end
        end
    end
    ---@param a string
    ---@return State
    local function resolve(a)
        local type = a:match("State([a-zA-Z]+)")
        if StateTypes[type] == nil then error(("GUSGUI: Failed to read state value string")) end
        local val = vals[tonumber(a:match("([0-9]+)"))]
        if type == "Add" or type == "Subtract" or type == "Divide" or type == "Multiply" then
            local val1 = val:match("^[^,]+")
            local val2 = val:match("[^,]+$")
            local res1, res2
            if val1:match("State([a-zA-Z]+)") then
                res1 = resolve(val1)
            end
            if val2:match("State([a-zA-Z]+)") then
                res2 = resolve(val2)
            end
            if tonumber(val1) ~= nil then res1 = tonumber(val1) end
            if tonumber(val2) ~= nil then res2 = tonumber(val2) end
            if res1 == nil or res2 == nil then error("GUSGUI: Failed to parse param to State" .. type) end
            return StateTypes[type](self, res1, res2)
        end
        if type == "Global" or type == "Value" then
            return StateTypes[type](self, val)
        else
            return StateTypes[type](self, val)
        end
    end
    return resolve(str)
end

--- @param data GuiElement
--- @return GuiElement data The element added.
function Gui:AddElement(data)
    if data["is_a"] and data["Draw"] and data["GetBaseElementSize"] then
        if data.type ~= "HLayout" and data.type ~= "VLayout" then
            self:Log(0, "Gui root nodes must be a Layout element.")
        end
        table.insert(self.tree, data)
        data:OnEnterTree(nil, true, self)
        return data
    else
        error("bad argument #1 to AddElement (GuiElement object expected, got invalid value)", 2)
    end
end

--- @param classname string
---@param config table
function Gui:RegisterConfigForClass(classname, config)
    self.classOverrides[classname] = {}
    if config.hover then 
        self.classOverrides[classname].hover = config.hover
        config.hover = nil
    end
    for k, v in pairs(config) do
        local validator = ElementProps.BaseElement[k]
        local t = type(v)
        if t == "table" and v["_type"] ~= nil and v["value"] then
            self.classOverrides[classname][k] = {
                value = v,
                isDF = false
            }
        end

        local value = v
        local err
        if validator.parser then
            value, err = validator.parser(value)
            if err then
                error((("Invalid value for %s on element \"%s\" (%s)"):format(k, classname .. " CLASS CONFIG", err)))
            end
        else
            if validator.type then
                if type(value) ~= validator.type then
                    error((("Invalid value for %s on element \"%s\" (Expected %s got %s)"):format(k, classname .. " CLASS CONFIG", validator.type, type(value))))
                end
            end
            if validator.validate then
                local a, b = validator.validate(value)
                if not a then
                    error((("Invalid value for %s on element \"%s\" (%s)"):format(k, classname .. " CLASS CONFIG", b)))
                end
            end
        end

        self.classOverrides[classname][k] = {
            value = value,
            isDF = false
        }
    end
    return
end

--#region GetElementBy search functions

--- @param id string
--- @return GuiElement|nil
function Gui:GetElementById(id)
    local function searchTree(element)
        for k = 1, #element.children do
            local v = element.children[k]
            if id and v.id == id then
                return v
            else
                local search = searchTree(v)
                if search ~= nil then
                    return search
                end
            end
        end
        return nil
    end

    for k = 1, #self.tree do
        local v = self.tree[k]
        if v.id == id then
            return v
        else
            local search = searchTree(v)
            if search ~= nil then
                return search
            end
        end
    end
    return nil
end

--- @param className string
--- @return GuiElement[]
function Gui:GetElementsByClass(className)
    local elems = {}
    local function searchTreeForClass(elem)
        if elem.class:find(className) then
            table.insert(elems, elem)
        end
        for i = 1, #elem.children do
            searchTreeForClass(elem.children[i])
        end
    end

    for i = 1, #self.tree do
        local root = self.tree[i]
        searchTreeForClass(root)
    end
    return elems
end

--#endregion

---@param level integer
---@param message string
function Gui:Log(level, message)
    --ERROR
    if level == 0 then
        self.ec = self.ec + 1
        -- Hard limit for errors to prevent GUI from printing massive amounts of text to console
        if self.ec > 10 then
            print("GUSGUI [ERR]: " .. message)
            self.destroyed = true
            error("GUSGUI: Stopping execution due to high error count")
        end
        error("GUSGUI [ERR]: " .. message, 2)
        --WARNING
    elseif level == 1 then
        if self.enableLogging then
            print("GUSGUI [WARN]: " .. message)
        end
    end
end

function Gui:Render()
    if (self.destroyed == true) then
        return
    end
    self._state = self.state
    self.framenum = GameGetFrameNum()
    self.screenW, self.screenH = GuiGetScreenDimensions(self.guiobj)
    self.screenW, self.screenH = math.floor(self.screenW), math.floor(self.screenH)
    self.screenWorldX, self.screenWorldY = GameGetCameraPos()
    GuiStartFrame(self.guiobj)
    for k = 1, #self.tree do
        local v = self.tree[k]
        v:PreRender()
    end
    for k = 1, #self.tree do
        local v = self.tree[k]
        v:Render()
    end
end

--- @param elem GuiElement
--- @return number x, number y
function Gui:GetRootElemXY(elem)
    local x, y = self.baseX, self.baseY
    local elemSize = elem:GetElementSize()
    if elem._config.margin.right ~= 0 then
        x = (self.screenW - elemSize.width) - elem._config.margin.right
    end
    if elem._config.margin.left ~= 0 then
        x = elem._config.margin.left
    end
    if elem._config.margin.top ~= 0 then
        y = elem._config.margin.top
    end
    if elem._config.margin.bottom ~= 0 then
        y = (self.screenH - elemSize.height) - elem._config.margin.bottom
    end
    return x, y
end

function Gui:Destroy()
    self.destroyed = true
    self.tree = nil
    self.state = nil
    self._state = nil
    GuiDestroy(self.guiobj)
end

--#region state functions
--- @class State
--- @field _type string
--- @field value any

--- @param s string
--- @return State
function Gui:StateValue(s)
    local o = {
        _type = "state",
        value = s
    }
    return o
end

--- @return State
function Gui:ScreenWidth()
    local o = {
        _type = "screenw",
        value = ""
    }
    return o
end

--- @return State
function Gui:ScreenHeight()
    local o = {
        _type = "screenh",
        value = ""
    }
    return o
end

--- @param s string
--- @return State
function Gui:StateGlobal(s)
    local o = {
        _type = "global",
        value = s,
    }
    return o
end

--- @param a State|number
--- @param b State|number
--- @return State
function Gui:StateAdd(a, b)
    return {
        _type = "add",
        value = {
            a = a,
            b = b
        }
    }
end

--- @param a State|number
--- @param b State|number
--- @return State
function Gui:StateSubtract(a, b)
    return {
        _type = "subtract",
        value = {
            a = a,
            b = b
        }
    }
end

--- @param a State|number
--- @param b State|number
--- @return State
function Gui:StateMultiply(a, b)
    return {
        _type = "multiply",
        value = {
            a = a,
            b = b
        }
    }
end

--- @param a State|number
--- @param b State|number
--- @return State
function Gui:StateDivide(a, b)
    return {
        _type = "divide",
        value = {
            a = a,
            b = b
        }
    }
end

--#endregion

--#region ElementGenerator class
local Generator = {}
do
    ---@class ElementGenerator
    ---@field recalcTrigger function
    ---@field func function
    ---@field neverInit boolean
    ---@operator call: ElementGenerator
    local ElementGenerator = class(function(newGen,  recalc, func)
        newGen.recalcTrigger = recalc
        newGen.func = func
        newGen.neverInit = true
    end)

    function ElementGenerator:GenerateEveryNFrames(num)
        ---@param elem GuiElement
        self.recalcTrigger = function(elem)
            return elem.gui.framenum % num == 0
        end
        return self
    end

    function ElementGenerator:OnlyGenerateOnInit()
        self.recalcTrigger = function()
            return false
        end
        return self
    end

    function ElementGenerator:ForEach(state, func)
        self.func = function (elem)
            local elems = {}
            local data = (elem.gui:GetState(state))
            for i = 1, #data do
                local c = func(data[i])
                table.insert(elems, c)
            end
            return elems
        end
        return self
    end

    function ElementGenerator:GenerateNTimes(times, func)
        self.func = function (elem)
            local tbl = {}
            for index=1,times do
                table.insert(tbl, func(index, elem))
            end
            return tbl
        end
    end

    function Generator.New()
        return ElementGenerator()
    end

    ---@param elem GuiElement
    ---@return GuiElement[]|nil
    function ElementGenerator:Process(elem)
        if self.recalcTrigger(elem) or self.neverInit then
            self.neverInit = false
            elem.generatorLastUpdate = elem.gui.framenum
            return self.func(elem)
        end
        return nil
    end

    Generator.ElementGenerator = ElementGenerator
end
--#endregion
--#region xml parser

---@param filedata string
---@return table DOM
---@nodiscard
local function ParseXML(filedata)
    -- This is a version of https://github.com/manoelcampos/xml2lua combined into one file with unused components removed
    -- Copyright (c) 2016 Manoel Campos da Silva Filho
    -- Licence (MIT) https://github.com/manoelcampos/xml2lua/blob/master/LICENSE
    --@author Paul Chakravarti (paulc@passtheaardvark.com)
    --@author Manoel Campos da Silva Filho
    local function getTree()
        local dom = {
            current = { _children = {}, _type = "ROOT" },
            _stack = {}
        }
        function dom:starttag(tag)
            local node = {
                _type = 'ELEMENT',
                _name = tag.name,
                _attr = tag.attrs,
                _children = {}
            }
            if not self.root then
                self.root = node
            end
            table.insert(self._stack, node)
            table.insert(self.current._children, node)
            self.current = node
        end

        function dom:endtag(tag)
            local prev = self._stack[#self._stack]
            if tag.name ~= prev._name then
                ---@diagnostic disable-next-line: undefined-global
                error("XML Error - Unmatched Tag [" .. s .. ":" .. tag.name .. "]\n")
            end
            table.remove(self._stack)
            self.current = self._stack[#self._stack]
            if not self.current then
                local node = { _children = {}, _type = "ROOT" }
                if self.root then
                    table.insert(node._children, self.root)
                    self.root = node
                end
                self.current = node
            end
        end
        function dom:text(text)
            local node = {
                _type = "TEXT",
                _text = text
            }
            table.insert(self.current._children, node)
        end
        dom.cdata = dom.text
        dom.__index = dom
        return dom
    end
    local function decimalToHtmlChar(code)
        local num = tonumber(code)
        if num >= 0 and num < 256 then
            ---@diagnostic disable-next-line: param-type-mismatch
            return string.char(num)
        end
        return "&#" .. code .. ";"
    end
    local function hexadecimalToHtmlChar(code)
        local num = tonumber(code, 16)
        if num >= 0 and num < 256 then
            return string.char(num)
        end
        return "&#x" .. code .. ";"
    end
    local XmlParser = {
        _XML        = '^([^<]*)<(%/?)([^>]-)(%/?)>',
        _ATTR1      = '([%w-:_]+)%s*=%s*"(.-)"',
        _ATTR2      = '([%w-:_]+)%s*=%s*\'(.-)\'',
        _CDATA      = '<%!%[CDATA%[(.-)%]%]>',
        _COMMENT    = '<!%-%-(.-)%-%->',
        _TAG        = '^(.-)%s.*',
        _LEADINGWS  = '^%s+',
        _TRAILINGWS = '%s+$',
        _WS         = '^%s*$',
        _ATTRERR1   = '=+?%s*"[^"]*$',
        _ATTRERR2   = '=+?%s*\'[^\']*$',
        _TAGEXT     = '(%/?)>',
        _errstr     = {
            xmlErr = "Error Parsing XML",
            cdataErr = "Error Parsing CDATA",
            endTagErr = "End Tag Attributes Invalid",
            unmatchedTagErr = "Unbalanced Tag",
            incompleteXmlErr = "Incomplete XML Document",
        },
        _ENTITIES   = {
            ["&lt;"] = "<",
            ["&gt;"] = ">",
            ["&amp;"] = "&",
            ["&quot;"] = '"',
            ["&apos;"] = "'",
            ["&#(%d+);"] = decimalToHtmlChar,
            ["&#x(%x+);"] = hexadecimalToHtmlChar,
        },
    }

    function XmlParser.new()
        local _handler = getTree()
        local obj = {
            handler = _handler,
            _stack  = {}
        }
        setmetatable(obj, XmlParser)
        obj.__index = XmlParser
        return obj;
    end
    local function fexists(table, elementName)
        if table == nil then
            return false
        end
        if table[elementName] == nil then
            return fexists(getmetatable(table), elementName)
        else
            return true
        end
    end
    local function err(self, errMsg, pos)
        error(string.format("%s [char=%d]\n", errMsg or "Parse Error", pos))
    end
    local function stripWS(self, s)
        s = string.gsub(s, '^%s+', '')
        s = string.gsub(s, '%s+$', '')
        return s
    end
    local function parseEntities(self, s)
        for k, v in pairs(self._ENTITIES) do
            s = string.gsub(s, k, v)
        end
        return s
    end
    local function parseTag(self, s)
        local tag = {
            name = string.gsub(s, self._TAG, '%1'),
            attrs = {}
        }
        local parseFunction = function(k, v)
            tag.attrs[k] = parseEntities(self, v)
            tag.attrs._ = 1
        end
        _ = string.gsub(s, self._ATTR1, parseFunction)
        _ = string.gsub(s, self._ATTR2, parseFunction)
        if tag.attrs._ then
            tag.attrs._ = nil
        else
            tag.attrs = nil
        end
        return tag
    end

    local function parseNormalTag(self, xml, f)
        while 1 do
            f.errStart, f.errEnd = string.find(f.tagstr, self._ATTRERR1)
            if f.errEnd == nil then
                f.errStart, f.errEnd = string.find(f.tagstr, self._ATTRERR2)
                if f.errEnd == nil then
                    break
                end
            end
            f.extStart, f.extEnd, f.endt2 = string.find(xml, self._TAGEXT, f.endMatch + 1)
            f.tagstr = f.tagstr .. string.sub(xml, f.endMatch, f.extEnd - 1)
            if not f.match then
                err(self, self._errstr.xmlErr, f.pos)
            end
            f.endMatch = f.extEnd
        end
        local tag = parseTag(self, f.tagstr)
        if (f.endt1 == "/") then
            if fexists(self.handler, 'endtag') then
                if tag.attrs then
                    err(self, string.format("%s (/%s)", self._errstr.endTagErr, tag.name), f.pos)
                end
                if table.remove(self._stack) ~= tag.name then
                    err(self, string.format("%s (/%s)", self._errstr.unmatchedTagErr, tag.name), f.pos)
                end
                self.handler:endtag(tag, f.match, f.endMatch)
            end
        else
            table.insert(self._stack, tag.name)
            if fexists(self.handler, 'starttag') then
                self.handler:starttag(tag, f.match, f.endMatch)
            end
            if (f.endt2 == "/") then
                table.remove(self._stack)
                if fexists(self.handler, 'endtag') then
                    self.handler:endtag(tag, f.match, f.endMatch)
                end
            end
        end
        return tag
    end

    local function getNextTag(self, xml, f)
        f.match, f.endMatch, f.text, f.endt1, f.tagstr, f.endt2 = string.find(xml, self._XML, f.pos)
        if not f.match then
            if string.find(xml, self._WS, f.pos) then
                if #self._stack ~= 0 then
                    err(self, self._errstr.incompleteXmlErr, f.pos)
                else
                    return false
                end
            else
                err(self, self._errstr.xmlErr, f.pos)
            end
        end
        f.text = f.text or ''
        f.tagstr = f.tagstr or ''
        f.match = f.match or 0
        return f.endMatch ~= nil
    end

    function XmlParser:parse(xml)
        local f = {
            match = 0,
            endMatch = 0,
            pos = 1,
        }
        while f.match do
            if not getNextTag(self, xml, f) then
                break
            end
            f.startText = f.match
            f.endText = f.match + string.len(f.text) - 1
            f.match = f.match + string.len(f.text)
            f.text = parseEntities(self, stripWS(self, f.text))
            if f.text ~= "" and fexists(self.handler, 'text') then
                self.handler:text(f.text, nil, f.match, f.endText)
            end
            if string.sub(f.tagstr, 1, 3) == "!--" then
                f.match, f.endMatch, f.text = string.find(xml, self._COMMENT, f.pos)
                if not f.match then
                    err(self, self._errstr.commentErr, f.pos)
                end
            elseif string.sub(f.tagstr, 1, 8) == "![CDATA[" then
                f.match, f.endMatch, f.text = string.find(xml, self._CDATA, f.pos)
                if not f.match then
                    err(self, self._errstr.cdataErr, f.pos)
                end
                if fexists(self.handler, 'cdata') then
                    self.handler:cdata(f.text, nil, f.match, f.endMatch)
                end
            else
                parseNormalTag(self, xml, f)
            end
            f.pos = f.endMatch + 1
        end
        return self.handler
    end
    XmlParser.__index = XmlParser
    local parser = XmlParser.new()
    return parser:parse(filedata).root
end
--#endregion
--#region exposed API functions

--- @param config table
--- @return Gui
--- @nodiscard
function CreateGUI(config)
    return Gui(config)
end

--- @param filename string
--- @param funcs table?
--- @param config table?
--- @return Gui
--- @nodiscard
function CreateGUIFromXML(filename, funcs, config, g)
    funcs = funcs or {}
    config = config or {}
    local function throwErr(err)
        error(("GUSGUI XML: Parsing %s failed: "):format(filename) .. err, 3)
    end

    if not ModTextFileGetContent then
        throwErr("Loading GUI XML files can only be done when ModTextFileGetContent is available")
    end

    if ModTextFileGetContent(filename) == nil then
        throwErr("File does not exist")
    end
    local gui = g or Gui(config)
    local StyleElem
    local data = ParseXML(ModTextFileGetContent(filename))
    --Main parsing function
    ---@param elem table
    ---@param parent GuiElement?
    local function parseElementAndChildren(elem, parent)
        if GuiElements[elem._name] == nil then
            throwErr("Unrecognised element type: \"" .. elem._name .. "\". Make sure that types use the correct case.")
        end
        elem._attr = elem._attr or {}
        local confTable = {}
        --Read config options and apply them to table
        for k, v in pairs(elem._attr) do
            ---@cast k string
            ---@cast v unknown
            local convert = ElementProps[elem._name][k]
            if convert == nil then
                if k:match("^hover%-") then
                    convert = ElementProps[elem._name][k:gsub("hover%-", "")]
                    local value
                    if v:find("State([a-zA-Z]+)") then
                        value = gui:StateStringToTable(v)
                    else
                        ---@diagnostic disable-next-line: need-check-nil
                        value = convert.fromString(v, funcs)
                    end
                    confTable.hover = confTable.hover or {}
                    confTable.hover[k:gsub("hover%-", "")] = value
                elseif k == "id" then
                    confTable.id = v
                elseif k == "class" then
                    confTable.class = v
                else
                    throwErr("Unrecognised inline config name: \"" .. k .. "\".")
                end
            else
                local value
                if v:find("State([a-zA-Z]+)") then
                    value = gui:StateStringToTable(v)
                else
                    ---@diagnostic disable-next-line: need-check-nil
                    value = convert.fromString(v, funcs)
                end
                confTable[k] = value
            end
        end

        --If element contains a text body, read it
        if #(elem._children) == 1 and elem._children[1]._type == "TEXT" then
            if elem._name == "Text" then
                local v = elem._children[1]._text
                local value
                if v:find("State([a-zA-Z]+)") then
                    value = gui:StateStringToTable(v)
                else
                    value = v
                end
                confTable.text = value
            end
            if elem._name == "Button" then
                local v = elem._children[1]._text
                local value
                if v:find("State([a-zA-Z]+)") then
                    value = gui:StateStringToTable(v)
                else
                    value = v
                end
                confTable.text = value
            end
            if elem._name == "Image" then
                local v = elem._children[1]._text
                local value
                if v:find("State([a-zA-Z]+)") then
                    value = gui:StateStringToTable(v)
                else
                    value = v
                end
                confTable.src = value
            end
            if elem._name == "ImageButton" then
                local v = elem._children[1]._text
                local value
                if v:find("State([a-zA-Z]+)") then
                    value = gui:StateStringToTable(v)
                else
                    value = v
                end
                confTable.src = value
            end
        end

        ---@type GuiElement
        local newElement = GuiElements[elem._name](confTable)
        newElement.gui = gui
        --Parse all children
        for index, value in ipairs(elem._children) do
            if value._type == "ELEMENT" then
                parseElementAndChildren(value, newElement)
            end
        end

        ---Add element to gui tree
        if not parent then
            gui:AddElement(newElement)
        else
            parent:AddChild(newElement)
        end
    end

    --Main parsing loop
    for _, value in ipairs(data) do
        if value._type == "ELEMENT" then
            if value._name == "Style" then
                if StyleElem ~= nil then
                    throwErr(
                        "Only one style element is allowed - combine styles into one tag or convert to inline config")
                end
                StyleElem = value
            else
                parseElementAndChildren(value)
            end
        end
    end

    local function splitString(s, delimiter)
        local result = {}
        local from = 1
        local delim_from, delim_to = string.find(s, delimiter, from)
        while delim_from do
            table.insert(result, string.sub(s, from, delim_from - 1))
            from = delim_to + 1
            delim_from, delim_to = string.find(s, delimiter, from)
        end
        table.insert(result, string.sub(s, from))
        return result
    end

    --#region "CSS" parser
    if StyleElem then
        local StyleText = StyleElem._children[1]._text
        if not StyleText then throwErr("Failed to find text in Style element") end
        local Styles = {}
        for m in StyleText:gmatch("[.#][a-zA-Z0-9]+ *{[^}]+}") do
            local key = m:match("[.#][a-zA-Z0-9]+")
            local values = splitString(
                m:match("{([^}]+)}"):gsub("^%s*", ""):gsub("%s*$", ""):gsub("%s*[a-zA-Z%-]+[ :]+",
                    function(s) return s:gsub("^%s*", "") end), ";")
            values[#values] = nil
            local conf = {}
            for _, value in ipairs(values) do
                local t = value:match("^[^:]*")
                local k = value:match("%s+([^:]*)$")
                conf[t] = k
            end
            Styles[key] = conf
        end

        for id, conf in pairs(Styles) do
            ---@cast id string
            local resolvedTable = {}
            for k, v in pairs(conf) do
                ---@cast k string
                ---@cast v unknown
                local convert
                do
                    convert = ElementProps.AllProperties[k:gsub("hover%-", "")]
                    if convert == nil then throwErr("Unrecognised inline config name: \"" .. k .. "\".") end
                    if k:match("^hover%-") then
                        local value
                        if v:find("State([a-zA-Z]+)") then
                            value = gui:StateStringToTable(v)
                        else
                            ---@diagnostic disable-next-line: need-check-nil
                            value = convert.fromString(v, funcs)
                        end
                        resolvedTable.hover = resolvedTable.hover or {}
                        resolvedTable.hover[k:gsub("hover%-", "")] = value
                    else
                        local value
                        if v:find("State([a-zA-Z]+)") then
                            value = gui:StateStringToTable(v)
                        else
                            ---@diagnostic disable-next-line: need-check-nil
                            value = convert.fromString(v, funcs)
                        end
                        resolvedTable[k] = value
                    end
                end
            end
            if id:sub(1, 1) == "." then
                gui:RegisterConfigForClass(id:sub(2), resolvedTable)
            else
                local elem = gui:GetElementById(id:sub(2))
                if elem then
                    for key, value in pairs(resolvedTable) do
                        ---@diagnostic disable-next-line: need-check-nil
                        elem:ApplyConfig(key, value)
                    end
                else
                    gui:Log("GUSGUI XML: Style element contains config for non-existent element id; config ignored.")
                end
            end
        end
    end
    --#endregion
    return gui
end

--#endregion
return {
    Create = CreateGUI,
    CreateGUIFromXML = CreateGUIFromXML,
    Elements = GuiElements,
    ElementGenerator = Generator
}
end

return {
    gusgui = gusgui
}