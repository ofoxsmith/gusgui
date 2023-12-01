--- @module "GuiElement"
local GuiElement = dofile_once("GUSGUI_PATHGuiElement.lua")
dofile_once("GUSGUI_PATHclass.lua")
local HLayoutConf = {
    alignChildren = {
        default = 0,
        fromString = function(s)
            return tonumber(s)
        end,
        validate = function(o)
            local t = type(o)
            if t == "number" then
                if not (0 <= o and o <= 1) then
                    return nil,
                        "Invalid value for alignChildren on element \"%s\" (value must be between 0-1)"
                end
                return o
            end
            return nil, "Invalid value for alignChildren on element \"%s\""
        end
    }
}
--- @class HLayout: GuiElement
--- @field lastUpdate number
--- @field hasInit boolean
--- @field CreateElements function|nil
--- @field baseX number
--- @field baseY number
--- @field maskID number
--- @operator call: HLayout
local HLayout = class(GuiElement, function(o, config, ext)
    config = config or {}
    ext = ext or {}
    ext.alignChildren = HLayoutConf.alignChildren
    GuiElement.init(o, config, ext)
    o.type = "HLayout"
    o.allowsChildren = true
    o.childrenResolved = false
    o._rawchildren = config.children or {}
end)

function HLayout:GetBaseElementSize()
    if self.type == "HLayoutForEach" then
        if not self.hasInit then
            self:CreateElements()
            self.hasInit = true;
        end
        if self.lastUpdate ~= self.gui.framenum and ((self.gui.framenum % self._config.calculateEveryNFrames) ~= 0) and self._config.calculateEveryNFrames ~= -1 then
            self:CreateElements()
        end
    end
    local totalW = 0
    local totalH = 0
    for i = 1, #self.children do
        local child = self.children[i]
        if not child._config.hidden then
            local size = child:GetElementSize()
            local w = math.max(size.width + child._config.margin.left + child._config.margin.right)
            local h = math.max(size.height + child._config.margin.top + child._config.margin.bottom)
            totalW = totalW + w
            totalH = math.max(totalH, h)
        end
    end
    return totalW, totalH
end

function HLayout:GetManagedXY(elem)
    if elem._config.hidden then return 0, 0 end
    local elemsize = elem:GetElementSize()
    local offsets = self:GetElementSize()
    self.nextX = self.nextX or self.baseX + self._config.padding.left + offsets.offsetX
    self.nextY = self.nextY or self.baseY + self._config.padding.top + offsets.offsetY
    local x = self.nextX + elem._config.margin.left
    local y = self.nextY + elem._config.margin.top
    self.nextX = self.nextX + elemsize.width + elem._config.margin.left + elem._config.margin.right
    if elem._config.drawBorder then
        x = x + 2
        y = y + 2
    end
    y = y + ((offsets.baseH - elemsize.height) * self._config.alignChildren)
    return x, y
end

function HLayout:Draw(x, y)
    self.nextX = nil
    self.nextY = nil
    local elementSize = self:GetElementSize()
    local size = self:GetElementSize()
    self.baseX = x
    self.baseY = y
    self.maskID = self.maskID or self.gui.nextID()
    GuiImageNinePiece(self.gui.guiobj, self.maskID, x, y, elementSize.paddingW, elementSize.paddingH, 0,
        "data/ui_gfx/decorations/9piece0_gray.png")
    local clicked, right_clicked, hovered = GuiGetPreviousWidgetInfo(self.gui.guiobj)
    for i = 1, #self.children do
        self.children[i]:Render()
    end
    if hovered then
        if self._config.onHover then
            self._config.onHover(self, self.gui.state)
        end
        self.useHoverConfigForNextFrame = true
    else
        self.useHoverConfigForNextFrame = false
    end
end

HLayout.extConf = HLayoutConf
return HLayout