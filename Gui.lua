dofile_once("GUSGUI_PATHclass.lua")
dofile_once("GUSGUI_PATHGuiElement.lua")
--- @return function
local function getIdCounter()
    local id = 1
    --- @return number
    return function()
        id = id + 1
        return id
    end
end

local GuiElements = {}
do
    local Text = dofile_once("GUSGUI_PATHelems/Text.lua")
    local Button = dofile_once("GUSGUI_PATHelems/Button.lua")
    local Image = dofile_once("GUSGUI_PATHelems/Image.lua")
    local ImageButton = dofile_once("GUSGUI_PATHelems/ImageButton.lua")
    local HLayout = dofile_once("GUSGUI_PATHelems/HLayout.lua")
    local HLayoutForEach = dofile_once("GUSGUI_PATHelems/HLayoutForEach.lua")
    local VLayoutForEach = dofile_once("GUSGUI_PATHelems/VLayoutForEach.lua")
    local VLayout = dofile_once("GUSGUI_PATHelems/VLayout.lua")
    local Slider = dofile_once("GUSGUI_PATHelems/Slider.lua")
    local TextInput = dofile_once("GUSGUI_PATHelems/TextInput.lua")
    local ProgressBar = dofile_once("GUSGUI_PATHelems/ProgressBar.lua")
    local Checkbox = dofile_once("GUSGUI_PATHelems/Checkbox.lua")
    GuiElements = {
        Text = Text,
        Button = Button,
        Image = Image,
        ImageButton = ImageButton,
        HLayout = HLayout,
        HLayoutForEach = HLayoutForEach,
        VLayout = VLayout,
        VLayoutForEach = VLayoutForEach,
        Slider = Slider,
        TextInput = TextInput,
        ProgressBar = ProgressBar,
        Checkbox = Checkbox,
    }
end


--- @class Gui
--- @field classOverrides table
--- @field guiobj unknown
--- @field state table
--- @field tree GuiElement[]
--- @operator call: Gui
local Gui = class(function(newGUI, state)
    state = state or {}
    newGUI.ids = {}
    newGUI.nextID = getIdCounter()
    newGUI.stateID = getIdCounter()
    newGUI.guiobj = GuiCreate()
    newGUI.tree = {}
    newGUI.cachedData = {}
    newGUI.state = state
    newGUI._state = {}
    newGUI.classOverrides = {}
    newGUI.screenW, newGUI.screenH = GuiGetScreenDimensions(newGUI.guiobj)
    newGUI.screenW, newGUI.screenH = math.floor(newGUI.screenW), math.floor(newGUI.screenH)
end)

--- @param s string
--- @return any
function Gui:GetState(s)
    local init = nil
    local a = {}
    local item = {}
    for i in s:gmatch("[^/]+") do
        if not init then
            init = i
        else
            table.insert(a, i)
        end
    end
    item = init and self._state[init] or self._state
    for k, v in pairs(a) do
        if (type(item) ~= "table") then
            error("GUSGUI: Cannot access property of non-table value in state", 2)
        end
        item = item[v];
    end
    return item
end

--- @param data GuiElement
--- @return GuiElement data The element added.
function Gui:AddElement(data)
    if data["is_a"] and data["Draw"] and data["GetBaseElementSize"] then
        if data.type ~= "HLayout" and data.type ~= "HLayoutForEach" and data.type ~= "VLayout" and data.type ~=
            "VLayoutForEach" then
            error("GUSGUI: Gui root nodes must be a Layout element.", 2)
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
    local configobj = {}
    for k, v in pairs(config) do
        local validator = BaseValidator[k]
        local t = type(v)
        if validator.allowsState == true then
            if t == "table" and v["_type"] ~= nil and v["value"] then
                configobj[k] = {
                    value = v,
                    isDF = false
                }
            end
        end
        if v == nil then
            configobj[k] = {
                value = validator.default,
                isDF = true
            }
        end
        local newValue, err = validator.validate(v)
        if type(err) == "string" then
            error(err:format(classname .. " CLASS CONFIG"))
        end
        configobj[k] = {
            value = newValue,
            isDF = false
        }
    end
    self.classOverrides[classname] = configobj
end

local function searchTree(element, id)
    for k = 1, #element.children do
        local v = element.children[k]
        if id and v.id == id then
            return v
        else
            local search = searchTree(v, id)
            if search ~= nil then
                return search
            end
        end
    end
    return nil
end

--- @param id string
--- @return GuiElement|nil
function Gui:GetElementById(id)
    for k = 1, #self.tree do
        local v = self.tree[k]
        if v.id == id then
            return v
        else
            local search = searchTree(v, id)
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

function Gui:Render()
    if (self.destroyed == true) then
        return
    end
    self.cachedData = {}
    self._state = self.state
    self.framenum = GameGetFrameNum()
    self.screenW, self.screenH = GuiGetScreenDimensions(self.guiobj)
    self.screenW, self.screenH = math.floor(self.screenW), math.floor(self.screenH)
    self.screenWorldX, self.screenWorldY = GameGetCameraBounds()
    GuiStartFrame(self.guiobj)
    for k = 1, #self.tree do
        local v = self.tree[k]
        v:Render()
    end
end

--- @param elem GuiElement
--- @return number x, number y
function Gui:GetRootElemXY(elem)
    local x, y = 0, 0
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

--- @return number, number, boolean
function Gui:GetMouseData()
    local component = EntityGetComponent(EntityGetWithTag("player_unit")[1], "ControlsComponent")[1]
    local mx, my = ComponentGetValue2(component, "mMousePosition")
    local screen_w, screen_h = GuiGetScreenDimensions(self.guiobj)
    local cx, cy = GameGetCameraPos()
    local vx = MagicNumbersGetValue("VIRTUAL_RESOLUTION_X")
    local vy = MagicNumbersGetValue("VIRTUAL_RESOLUTION_Y")
    local gmx = ((mx - cx) * screen_w / vx + screen_w / 2)
    local gmy = ((my - cy) * screen_h / vy + screen_h / 2)
    return math.floor(gmx), math.floor(gmy), ComponentGetValue2(component, "mButtonDownLeftClick")
end

--- @param state table
--- @return Gui
--- @nodiscard
function CreateGUI(state)
    return Gui(state)
end

--- @param filename string
--- @param funcs table
--- @return Gui
--- @nodiscard
function CreateGUIFromXML(filename, funcs)
    nxml = GUSGUI_NXML()
    if not ModTextFileGetContent then
        error("GUSGUI: Loading GUI XML files can only be done in init.lua", 2)
    end
    local parser = dofile_once("GUSGUI_PATHconfigParser.lua")
    -- read inline config options
    local function createConfigTable(elem)
        local conf = {}
        if elem.name == "Text" then
            conf.value = elem:text()
        end
        if elem.name == "Button" then
            conf.text = elem:text()
        end
        if elem.name == "Image" then
            conf.src = elem:text()
        end
        if elem.name == "ImageButton" then
            conf.src = elem:text()
        end
        for key, value in pairs(elem.attr) do
            parser(elem.name, key, value, conf, funcs)
        end
        return conf
    end

    local gui = Gui()
    local xml = nxml.parse(ModTextFileGetContent(filename))
    local function parseTree(elem, parent)
        for element in elem:each_child() do
            if GuiElements[element.name] == nil then
                error(("GUSGUI XML: Failed to parse xml file %s (Element with name %s does not exist."):format(filename,
                    element.name))
            end
            local addTo = parent:AddChild(GuiElements[element.name](createConfigTable(element)))
            parseTree(element, addTo)
        end
    end

    local configElem = nil
    for element in xml:each_child() do
        if element.name == "Style" then
            configElem = element
        else
            if GuiElements[element.name] == nil then
                error(("GUSGUI: Failed to parse xml file %s (Element with name %s does not exist."):format(filename,
                    element.name))
            end
            local addTo = gui:AddElement(GuiElements[element.name](createConfigTable(element)))
            parseTree(element, addTo)
        end
    end
    if configElem ~= nil then
        --- Parse config manually, as nxml mangles newlines and other spacing
        local content = ModTextFileGetContent(filename)
        local _, openingTag = content:find("<Style>")
        local closingTag = content:find("</Style>")
        local parser = dofile_once("GUSGUI_PATHconfigParser.lua")
        content = content:sub(openingTag + 1, closingTag - 1)
        local stringLookup = {}
        content = content:gsub('"([^"]+)"', function(string)
            table.insert(stringLookup, string)
            return "&&&" .. #stringLookup
        end)
        content = content:gsub("%s", "")
        local configToApply = {}
        while true do
            if content == "" then
                break;
            end
            local s, e = content:find("^[^{}]+")
            local key = content:sub(s, e)
            content = content:sub(e + 1)
            local vs, ve = content:find("^{[^{}]+}")
            local value = content:sub(vs, ve)
            content = content:sub(ve + 1)
            configToApply[key] = value:sub(vs + 1, ve - 1)
        end
        for key, value in pairs(configToApply) do
            local isClass = false
            local applyTo
            ---@cast key string
            ---@cast value string
            if key:sub(1, 1) == "." then
                isClass = true
                applyTo = stringLookup[tonumber(key:sub(5))]
            else
                applyTo = stringLookup[tonumber(key:sub(4))]
            end
            local config = {}
            value = value:gsub("&&&[0-9]+", function(e)
                return stringLookup[tonumber(e:sub(4))]
            end)
            while true do
                if value == "" then break end
                local keyS, keyE = value:find("^([a-zA-Z%-]+):")
                local configOpt = value:sub(keyS, keyE - 1)
                value = value:sub(keyE + 1)
                local configS, configE = value:find("^([^;]+);")
                local configVal = value:sub(configS, configE - 1)
                value = value:sub(configE + 1)
                -- use a string with the name of every element, to trigger the config parsers for every single element type
                local eachElement = "LayoutForEachButtonImageCheckboxProgressBarSliderTextInput"
                parser(eachElement, configOpt, configVal, config, funcs)
            end
            if isClass then
                gui:RegisterConfigForClass(applyTo, config)
            else
                local elem = gui:GetElementById(applyTo)
                elem.config = config
            end
        end

    end
    return gui
end

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
function Gui:GlobalValue(s)
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

--- @param type "inner"|"total"
--- @return State
function Gui:ParentWidth(type)
    if type == "inner" then
        return {
            _type = "p_innerW",
            value = ""
        }
    else
        return {
            _type = "p_totalW",
            value = ""
        }
    end
end

--- @param type "inner"|"total"
--- @return State
function Gui:ParentHeight(type)
    if type == "inner" then
        return {
            _type = "p_innerH",
            value = ""
        }
    else
        return {
            _type = "p_totalH",
            value = ""
        }
    end
end

--- @param type "inner"|"total"
--- @return State
function Gui:ElemWidth(type)
    if type == "inner" then
        return {
            _type = "innerW",
            value = ""
        }
    else
        return {
            _type = "totalW",
            value = ""
        }
    end
end

--- @param type "inner"|"total"
--- @return State
function Gui:ElemHeight(type)
    if type == "inner" then
        return {
            _type = "innerH",
            value = ""
        }
    else
        return {
            _type = "totalH",
            value = ""
        }
    end
end

--#region NXML
---------------- NXML  ----------------
GUSGUI_NXML = function()
    --[[
    * The following is a Lua port of the NXML parser:
    * https://github.com/xwitchproject/nxml
    * The NXML Parser is heavily based on code from poro
    * https://github.com/gummikana/poro
    * The poro project is licensed under the Zlib license:
    * --------------------------------------------------------------------------
    * Copyright (c) 2010-2019 Petri Purho, Dennis Belfrage
    * Contributors: Martin Jonasson, Olli Harjola
    * This software is provided 'as-is', without any express or implied
    * warranty.  In no event will the authors be held liable for any damages
    * arising from the use of this software.
    * Permission is granted to anyone to use this software for any purpose,
    * including commercial applications, and to alter it and redistribute it
    * freely, subject to the following restrictions:
    * 1. The origin of this software must not be misrepresented; you must not
    *    claim that you wrote the original software. If you use this software
    *    in a product, an acknowledgment in the product documentation would be
    *    appreciated but is not required.
    * 2. Altered source versions must be plainly marked as such, and must not be
    *    misrepresented as being the original software.
    * 3. This notice may not be removed or altered from any source distribution.
    * --------------------------------------------------------------------------
    ]]
    local nxml = {}
    local TOKENIZER_FUNCS = {}
    local TOKENIZER_MT = {
        __index = TOKENIZER_FUNCS,
    }
    local function new_tokenizer(cstring, len)
        return setmetatable({
            data = cstring,
            cur_idx = 0,
            cur_row = 1,
            cur_col = 1,
            prev_row = 1,
            prev_col = 1,
            len = len
        }, TOKENIZER_MT)
    end

    local ws = {
        [string.byte(" ")] = true,
        [string.byte("\t")] = true,
        [string.byte("\n")] = true,
        [string.byte("\r")] = true
    }
    local punct = {
        [string.byte("<")] = true,
        [string.byte(">")] = true,
        [string.byte("=")] = true,
        [string.byte("/")] = true,
    }
    function TOKENIZER_FUNCS:move(n)
        n = n or 1
        local prev_idx = self.cur_idx
        self.cur_idx = self.cur_idx + n
        if self.cur_idx >= self.len then
            self.cur_idx = self.len
            return
        end
        for i = prev_idx, self.cur_idx - 1 do
            if string.byte(self.data:sub(i + 1, i + 1)) == string.byte("\n") then
                self.cur_row = self.cur_row + 1
                self.cur_col = 1
            else
                self.cur_col = self.cur_col + 1
            end
        end
    end

    function TOKENIZER_FUNCS:peek(n)
        n = n or 1
        local idx = self.cur_idx + n
        if idx >= self.len then return 0 end
        return string.byte(self.data:sub(idx + 1, idx + 1))
    end

    function TOKENIZER_FUNCS:match_string(str)
        local len = #str
        for i = 0, len - 1 do
            if self:peek(i) ~= string.byte(str:sub(i + 1, i + 1)) then return false end
        end
        return true
    end

    function TOKENIZER_FUNCS:cur_char()
        if (self.cur_idx >= self.len) then return 0 end
        return tonumber(string.byte(self.data:sub(self.cur_idx + 1, self.cur_idx + 1)))
    end

    function TOKENIZER_FUNCS:skip_whitespace()
        while not (self.cur_idx >= self.len) do
            if (ws[tonumber(self:cur_char())] or false) then
                self:move()
            elseif self:match_string("<!--") then
                self:move(4)
                while not (self.cur_idx >= self.len) and not self:match_string("-->") do
                    self:move()
                end
                if self:match_string("-->") then
                    self:move(3)
                end
            elseif self:cur_char() == string.byte("<") and self:peek(1) == string.byte("!") then
                self:move(2)
                while not (self.cur_idx >= self.len) and self:cur_char() ~= string.byte(">") do
                    self:move()
                end
                if self:cur_char() == string.byte(">") then
                    self:move()
                end
            elseif self:match_string("<?") then
                self:move(2)
                while not (self.cur_idx >= self.len) and not self:match_string("?>") do
                    self:move()
                end
                if self:match_string("?>") then
                    self:move(2)
                end
            else
                break
            end
        end
    end

    function TOKENIZER_FUNCS:read_quoted_string()
        local start_idx = self.cur_idx
        local len = 0
        while not (self.cur_idx >= self.len) and self:cur_char() ~= string.byte("\"") do
            len = len + 1
            self:move()
        end
        self:move() -- skip "
        return self.data:sub(start_idx + 1, start_idx + len)
    end

    function TOKENIZER_FUNCS:read_unquoted_string()
        local start_idx = self.cur_idx - 1 -- first char is move()d
        local len = 1
        while not (self.cur_idx >= self.len) and not (ws[tonumber(self:cur_char())] or false) or
            punct[tonumber(self:cur_char())] or false do
            len = len + 1
            self:move()
        end
        return self.data:sub(start_idx + 1, start_idx + len)
    end

    local C_NULL = 0
    local C_LT = string.byte("<")
    local C_GT = string.byte(">")
    local C_SLASH = string.byte("/")
    local C_EQ = string.byte("=")
    local C_QUOTE = string.byte("\"")
    function TOKENIZER_FUNCS:next_token()
        self:skip_whitespace()
        self.prev_row = self.cur_row
        self.prev_col = self.cur_col
        if (self.cur_idx >= self.len) then return nil end
        local c = self:cur_char()
        self:move()
        if c == C_NULL then return nil
        elseif c == C_LT then return { type = "<" }
        elseif c == C_GT then return { type = ">" }
        elseif c == C_SLASH then return { type = "/" }
        elseif c == C_EQ then return { type = "=" }
        elseif c == C_QUOTE then return { type = "string", value = self:read_quoted_string() }
        else return { type = "string", value = self:read_unquoted_string() } end
    end

    local PARSER_FUNCS = {}
    local PARSER_MT = {
        __index = PARSER_FUNCS,
    }
    local function new_parser(tokenizer, error_reporter)
        return setmetatable({
            tok = tokenizer,
            errors = {},
            error_reporter = error_reporter or function(type, msg) print("parser error: [" .. type .. "] " .. msg) end
        }, PARSER_MT)
    end

    local XML_ELEMENT_FUNCS = {}
    local XML_ELEMENT_MT = {
        __index = XML_ELEMENT_FUNCS,
    }
    function PARSER_FUNCS:report_error(type, msg)
        self.error_reporter(type, msg)
        table.insert(self.errors, { type = type, msg = msg, row = self.tok.prev_row, col = self.tok.prev_col })
    end

    function PARSER_FUNCS:parse_attr(attr_table, name)
        local tok = self.tok:next_token()
        if tok.type == "=" then
            tok = self.tok:next_token()
            if tok.type == "string" then
                attr_table[name] = tok.value
            else
                self:report_error("missing_attribute_value",
                    string.format("parsing attribute '%s' - expected a string after =, but did not find one", name))
            end
        else
            self:report_error("missing_equals_sign",
                string.format("parsing attribute '%s' - did not find equals sign after attribute name", name))
        end
    end

    function PARSER_FUNCS:parse_element(skip_opening_tag)
        local tok
        if not skip_opening_tag then
            tok = self.tok:next_token()
            if tok.type ~= "<" then
                self:report_error("missing_tag_open", "couldn't find a '<' to start parsing with")
            end
        end
        tok = self.tok:next_token()
        if tok.type ~= "string" then
            self:report_error("missing_element_name", "expected an element name after '<'")
        end
        local elem_name = tok.value
        local elem = nxml.new_element(elem_name)
        local content_idx = 0
        local self_closing = false
        while true do
            tok = self.tok:next_token()
            if tok == nil then
                return elem
            elseif tok.type == "/" then
                if self.tok:cur_char() == C_GT then
                    self.tok:move()
                    self_closing = true
                end
                break
            elseif tok.type == ">" then
                break
            elseif tok.type == "string" then
                self:parse_attr(elem.attr, tok.value)
            end
        end
        if self_closing then return elem end
        while true do
            tok = self.tok:next_token()
            if tok == nil then
                return elem
            elseif tok.type == "<" then
                if self.tok:cur_char() == C_SLASH then
                    self.tok:move()
                    local end_name = self.tok:next_token()
                    if end_name.type == "string" and end_name.value == elem_name then
                        local close_greater = self.tok:next_token()
                        if close_greater.type == ">" then
                            return elem
                        else
                            self:report_error("missing_element_close",
                                string.format("no closing '>' found for element '%s'", elem_name))
                        end
                    else
                        self:report_error("mismatched_closing_tag",
                            string.format("closing element is in wrong order - expected '</%s>', but instead got '%s'",
                                elem_name, tostring(end_name.value)))
                    end
                    return elem
                else
                    local child = self:parse_element(elem)
                    table.insert(elem.children, child)
                end
            else
                if not elem.content then
                    elem.content = {}
                end
                content_idx = content_idx + 1
                elem.content[content_idx] = tok.value or tok.type
            end
        end
    end

    function PARSER_FUNCS:parse_elements()
        local tok = self.tok:next_token()
        local elems = {}
        local elems_i = 1
        while tok and tok.type == "<" do
            elems[elems_i] = self:parse_element(true)
            elems_i = elems_i + 1
            tok = self.tok:next_token()
        end
        return elems
    end

    function XML_ELEMENT_FUNCS:text()
        local content_count = #self.content
        if self.content == nil or content_count == 0 then
            return ""
        end
        local text = self.content[1]
        for i = 2, content_count do
            local elem = self.content[i]
            local prev = self.content[i - 1]
            if (elem == "/" or elem == "<" or elem == ">" or elem == "=") or
                (prev == "/" or prev == "<" or prev == ">" or prev == "=") then
                text = text .. elem
            else
                text = text .. " " .. elem
            end
        end
        return text
    end

    function XML_ELEMENT_FUNCS:each_child()
        local i = 0
        return function()
            while i <= #self.children do
                i = i + 1
                return self.children[i]
            end
        end
    end

    function nxml.parse(data)
        local data_len = #data
        local tok = new_tokenizer(data, data_len)
        local parser = new_parser(tok)
        local elem = parser:parse_element(false)
        if not elem or (elem.errors and #elem.errors > 0) then
            error("parser encountered errors")
        end
        return elem
    end

    function nxml.new_element(name, attrs)
        return setmetatable({
            name = name,
            attr = attrs or {},
            children = {},
            content = nil
        }, XML_ELEMENT_MT)
    end

    return nxml
end
--#endregion

return {
    Create = CreateGUI,
    CreateGUIFromXML = CreateGUIFromXML,
    Elements = GuiElements
}
