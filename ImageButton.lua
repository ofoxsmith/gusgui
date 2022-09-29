local GuiElement = dofile_once("GUSGUI_PATHGuiElement.lua")
dofile_once("GUSGUI_PATHclass.lua")

local ImageButton = class(GuiElement, function(o, config)
    GuiElement.init(o, config, extendedValid)
    o.type = "ImageButton"
    o.allowsChildren = false
end)

function ImageButton:GetBaseElementSize()
    local w, h = GuiGetImageDimensions(self.gui.guiobj, self._config.path)
    return w * self._config.scaleX, h * self._config.scaleY  
end

function ImageButton:Draw()
    if self._config.hidden then return end
    self.imageID = self.imageID or self.gui.nextID()
    self.buttonID = self.buttonID or self.gui.nextID()
    self.z = self:GetDepthInTree() * -100
    local elementSize = self:GetElementSize()
    local paddingLeft = self._config.padding.left
    local paddingTop = self._config.padding.top
    local x = self._config.margin.left
    local y = self._config.margin.top
    local c = self._config.colour
    local border = (self._config.drawBorder and 1 or 0)
    if self.parent then
        x, y = self.parent:GetManagedXY(self)
    end
    if border > 0 then
        self:RenderBorder(x, y, elementSize.baseW, elementSize.baseH)
    end
    if self._config.drawBackground then 
        self:RenderBackground(x, y, elementSize.baseW, elementSize.baseH)
    end
    GuiZSetForNextWidget(self.gui.guiobj, self.z - 1)
    GuiImageNinePiece(self.gui.guiobj, self.buttonID, x + border, y + border, elementSize.width - border - border, elementSize.height - border - border, 0, "data/ui_gfx/decorations/9piece0_gray.png")
    local clicked, right_clicked, hovered = GuiGetPreviousWidgetInfo(self.gui.guiobj)
    if clicked then
        self._config.onClick(self)
    end
    if hovered and self._config.onHover then self._config.onHover(self) end
    GuiZSetForNextWidget(self.gui.guiobj, self.z)
    if self._config.colour then
        GuiColorSetForNextWidget(self.gui.guiobj, c[1] / 255, c[2] / 255, c[3] / 255, 1)
    end
    GuiImage(self.gui.guiobj, self.imageID, x + elementSize.offsetX + paddingLeft + border, y + elementSize.offsetY + paddingTop + border, self._config.path, 1, self._config.scaleX, self._config.scaleY)
end

extendedValid = {
    {
        name = "scaleX",
        fromString = function(s) 
            return tonumber(s)
        end,
        validate = function(o)
            if o == nil then return true, 1, nil end
            local t = type(o)
            if t == "table" and o["_type"] ~= nil and o["value"] then
                return true, nil, nil
            end
            if t == "number" then return true, nil, nil end
        end    
    },
    {
        name = "scaleY",
        fromString = function(s) 
            return tonumber(s)
        end,
        validate = function(o)
            if o == nil then return true, 1, nil end
            local t = type(o)
            if t == "table" and o["_type"] ~= nil and o["value"] then
                return true, nil, nil
            end
            if t == "number" then return true, nil, nil end
        end    
    },
    {
        name = "src",
        fromString = function(s) return s end,
        validate = function(o)
            if o == nil then return false, nil, "GUI: Invalid value for src on element \"%s\" (src paramater is required)" end
            local t = type(o)
            if t == "table" and o["_type"] ~= nil and o["value"] then
                return true, nil, nil
            end
            if t == "string" then return true, nil, nil end
        end
    }, {
        name = "onClick",
        validate = function(o)
            if o == nil then
                return false, nil,  "GUI: Invalid value for onClick on element \"%s\" (onClick is required)"
            end
            if type(o) == "function" then return true, nil, nil end
            return false, nil, "GUI: Invalid value for onHover on element \"%s\""
        end    
    }
}


return ImageButton