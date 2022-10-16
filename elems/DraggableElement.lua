-- Thanks Horscht for letting me use EZMouse for drag and drop
local GuiElement = dofile_once("GUSGUI_PATHGuiElement.lua")
dofile_once("GUSGUI_PATHclass.lua")
local DraggableElement = class(GuiElement, function(o, config)
    GuiElement.init(o, config, {dragLayer = {
        allowsState = false,
        default = 0,
        fromString = function(s)
            return tonumber(s)
        end,
        validate = function(o)
            local t = type(o)
            if t == "number" then
                return o
            end
            return nil, "GUSGUI: Invalid value for dragLayer on element \"%s\""
        end
    }})
    o.type = "DraggableElement"
    o._rawchildren = {config.element}
    o.selectableAreaExceptions = {}
end)

function DraggableElement:GetBaseElementSize()
    local child = self.children[1]
    local size = child:GetElementSize()
    local w = size.width + child._config.margin.left + child._config.margin.right
    local h = size.height + child._config.margin.top + child._config.margin.bottom
    return w, h
end

function DraggableElement:GetManagedXY(elem)
    return self.currentX, self.currentY
end

function DraggableElement:Draw()
    local x = self._config.margin.left
    local y = self._config.margin.top
    local size = self:GetElementSize()
    if self.parent then
        x, y = self.parent:GetManagedXY(self)
    end
    if self.ezmWidth == nil then
        self.ezmWidget = self.gui.ezm.Widget({
            x = x,
            y = y,
            width = size.width,
            height = size.height,
            z = self.z,
            resizable = false,
            draggable = true,
    
        })    
        self.ezmWidget:AddEventListener("drag", function(_, event)
            self.currentX = event.dx
            self.currentY = event.dy
        end)          
    end
    if self.setPos then 
        self.currentX = x
        self.currentY = y
        self.ezmWidget.x = x
        self.ezmWidget.y = y
        self.setPos = false
    end
    self.enabled = not self.locked
    self.ezmWidget.width = size.width
    self.ezmWidget.height = size.height
    self.currentX = self.currentX or x
    self.currentY = self.currentY or y
    self.children[1]:Draw()
end

function DraggableElement:Lock()
    self.locked = true
end

function DraggableElement:Unlock()
    self.locked = false
end

function DraggableElement:ResetPos()
    self.setPos = true 
end

--- Override OnExitTree to also delete the EZMouse widget
function DraggableElement:OnExitTree()
    self.ezmWidget:Destroy()
    self.ezmWidget = nil
    self.children[1]:OnExitTree()
    for i, v in ipairs(self.parent.children) do
        if (v.uid == self.uid) then
            table.remove(self.parent.children, i)
            break
        end
    end
    self.parent = nil
    self.children = nil
    if self.id then
        self.gui.ids[self.id] = nil
    end
    self.gui = nil
end

return DraggableElement
