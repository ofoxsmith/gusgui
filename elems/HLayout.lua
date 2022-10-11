local GuiElement = dofile_once("GUSGUI_PATHGuiElement.lua")
dofile_once("GUSGUI_PATHclass.lua")

local HLayout = class(GuiElement, function(o, config)
    GuiElement.init(o, config, {{
        name = "alignChildren",
        fromString = function(s)
            return tonumber(s)
        end,
        validate = function(o)
            local t = type(o)
            if o == nil then
                return true, 0, nil, true
            end
            if t == "table" and o["_type"] ~= nil and o["value"] then
                return true, nil, nil
            end
            if t == "number" then
                if not (0 <= o and o <= 1) then
                    return false, nil,
                        "GUSGUI: Invalid value for alignChildren on element \"%s\" (value did not match 0 ≤ value ≤ 1)"
                end
                return true, nil, nil
            end
            return false, nil, "GUSGUI: Invalid value for alignChildren on element \"%s\""
        end
    }})
    o.type = "HLayout"
    o.allowsChildren = true
    o.childrenResolved = false
    o._rawchildren = config.children or {}
end)

function HLayout:GetBaseElementSize()
    if self.type == "HLayoutForEach" then 
        if self.lastUpdate == self.gui.framenum then
        elseif ((self.gui.framenum % self._config.calculateEveryNFrames) ~= 0) and self.hasInit == true then
        else self:CreateElements() end
    end 
    local totalW = 0
    local totalH = 0
    for i = 1, #self.children do
        local child = self.children[i]
        local size = child:GetElementSize()
        local w = math.max(size.width + child._config.margin.left + child._config.margin.right)
        local h = math.max(size.height + child._config.margin.top + child._config.margin.bottom)
        totalW = totalW + w
        totalH = math.max(totalH, h)
    end
    return totalW, totalH
end

function HLayout:GetManagedXY(elem)
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
    GuiImageNinePiece(self.gui.guiobj, self.maskID, x, y, elementSize.paddingW,
    elementSize.paddingH, 0, "data/ui_gfx/decorations/9piece0_gray.png")
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

return HLayout
