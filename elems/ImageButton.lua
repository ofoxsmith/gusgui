--- @module "GuiElement"
local GuiElement = dofile_once("GUSGUI_PATHGuiElement.lua")
dofile_once("GUSGUI_PATHclass.lua")
local ImageButtonConf = {scaleX = {
    required = false,
    default = 1,
    fromString = function(s)
        return tonumber(s)
    end,
    validate = function(o)
        if type(o) == "number" then
            return o
        end
    end
}, scaleY = {
    required = false,
    default = 1,
    fromString = function(s)
        return tonumber(s)
    end,
    validate = function(o)
        if type(o) == "number" then
            return o
        end
    end
}, src = {
    required = true,
    fromString = function (s)
        return s
    end,
    validate = function(o)
        if type(o) == "string" then
            return o
        end
    end
}, onClick = {
    required = true,
    fromString = function (s, funcs)
        if funcs[s] then return funcs[s] end
        error("GUSGUI: Unknown function name" .. s)
        end,
    validate = function(o)
        if type(o) == "function" then
            return o
        end
        return nil, "Invalid value for onHover on element \"%s\""
    end
}}
--- @class ImageButton: GuiElement
--- @field maskID number
--- @field imageID number
--- @field buttonID number
--- @operator call: ImageButton
local ImageButton = class(GuiElement, function(o, config)
    config = config or {}
    GuiElement.init(o, config, ImageButtonConf)
    o.type = "ImageButton"
    o.allowsChildren = false
end)

function ImageButton:GetBaseElementSize()
    local w, h = GuiGetImageDimensions(self.gui.guiobj, self._config.src)
    return w * self._config.scaleX, h * self._config.scaleY
end

function ImageButton:Draw(x, y)
    self.imageID = self.imageID or self.gui.nextID()
    self.buttonID = self.buttonID or self.gui.nextID()
    local elementSize = self:GetElementSize()
    local c = self._config.colour
    GuiZSetForNextWidget(self.gui.guiobj, self.z - 1)
    GuiImageNinePiece(self.gui.guiobj, self.buttonID, x, y, elementSize.paddingW,
    elementSize.paddingH, 0, "data/ui_gfx/decorations/9piece0_gray.png")
    local clicked, right_clicked, hovered = GuiGetPreviousWidgetInfo(self.gui.guiobj)
    if clicked then
        self._config.onClick(self, self.gui.state)
    end
    if hovered and self._config.onHover then
        self._config.onHover(self, self.gui.state)
    end
    GuiZSetForNextWidget(self.gui.guiobj, self.z)
    if self._config.colour then
        GuiColorSetForNextWidget(self.gui.guiobj, c[1] / 255, c[2] / 255, c[3] / 255, 1)
    end
    GuiImage(self.gui.guiobj, self.imageID, x + elementSize.offsetX + self._config.padding.left,
        y + elementSize.offsetY + self._config.padding.top, self._config.src, 1, self._config.scaleX, self._config.scaleY)
    if hovered then self.useHoverConfigForNextFrame = true 
    else self.useHoverConfigForNextFrame = false end
end

ImageButton.extConf = ImageButtonConf
return ImageButton