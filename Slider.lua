local GuiElement = dofile_once("GUSGUI_PATHGuiElement.lua")
dofile_once("GUSGUI_PATHclass.lua")

local Slider = class(GuiElement, function(o, config)
    GuiElement.init(o, config)
    o.type = "Slider"
    o.allowsChildren = false
    if config.width == nil then
        error("GUI: Invalid construction of Slider element (length paramater is required)", 2)
    end
    o.width = config.width
    if config.min == nil then
        error("GUI: Invalid construction of Slider element (min paramater is required)", 2)
    end
    o.min = config.min
    if config.max == nil then
        error("GUI: Invalid construction of Slider element (max paramater is required)", 2)
    end
    o.max = config.max
    if config.defaultValue == nil then 
        error("GUI: Invalid construction of Slider element (defaultValue paramater is required)", 2)
    end
    o.defaultValue = config.defaultValue
    if config.onChange == nil then 
        error("GUI: Invalid construction of Slider element (onChange paramater is required)", 2)
    end
    o.onChange = config.onChange
end)

function Slider:GetBaseElementSize()
  return math.max(25, self.width), 8
end

function Slider:Draw()
    self.value = self.value or self.defaultValue
    self.renderID = self.renderID or self.gui.nextID()
    self.z = self:GetDepthInTree() * -100
    local elementSize = self:GetElementSize()
    local paddingLeft = self.config.padding.left
    local paddingTop = self.config.padding.top
    local x = self.config.margin.left
    local y = self.config.margin.top
    local c = self.config.colour
    local border = self.config.drawBorder and 1 or 0
    if self.parent then
        x, y = self.parent:GetManagedXY(self)
    end
    if self.config.drawBorder then
        self:RenderBorder(x, y, elementSize.baseW, elementSize.baseH)
    end
    if self.config.drawBackground then 
        self:RenderBackground(x, y, elementSize.baseW, elementSize.baseH)
    end
    local old = self.value
    GamePrint("min" .. tostring(self.min))
    GamePrint("max" .. tostring(self.max))
    local nv = GuiSlider(self.gui.guiobj, self.renderID, x + elementSize.offsetX + paddingLeft + border, y + elementSize.offsetY + border + paddingTop, "", self.value, self.min, self.max, self.defaultValue, 1, " ", self.width)
    self.value = math.floor(nv)
    if nv ~= old then
        self.onChange(self)
    end 
end

return Slider