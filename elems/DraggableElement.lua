local GuiElement = dofile_once("GUSGUI_PATHGuiElement.lua")
dofile_once("GUSGUI_PATHclass.lua")

local DraggableElement = class(GuiElement, function(o, config)
    GuiElement.init(o, config, {{
        name = "type",
        validate = function(o)
            local t = type(o)
            if o == nil then
                return false, nil, "GUI: Invalid value for type on element \"%s\""
            end
            if t == "table" and o["_type"] ~= nil and o["value"] then
                return true, nil, nil
            end
            if t == "string" and o == "area" or o == "bar" then
                return true, nil, nil
            end
            return false, nil, "GUI: Invalid value for type on element \"%s\""
        end    
    }})
    o.type = "DraggableElement"
    o._rawchildren = {config.element}
    o.selectableAreaExceptions = {}
end)

function DraggableElement:GetBaseElementSize()
    local child = self.children[1]
    local size = child:GetElementSize()
    local w = math.max(size.width + child._config.margin.left + child._config.margin.right, child._config.overrideWidth)
    local h = math.max(size.height + child._config.margin.top + child._config.margin.bottom,
        child._config.overrideHeight)
    return w, h
end

function DraggableElement:GetManagedXY(elem)
    return self.currentX, self.currentY
end

function DraggableElement:Draw()
    self.z = self:GetDepthInTree() * -100
    local x = self._config.margin.left
    local y = self._config.margin.top
    local size = self:GetElementSize()
    if self.parent then
        x, y = self.parent:GetManagedXY(self)
    end
    self.currentX = self.currentX or x
    self.currentY = self.currentY or y
    self.children[1]:Draw()
    local elementSize = self:GetElementSize()
    if self._config.type == "area" then
        local mouseX, mouseY, mouseClicked = self.gui:GetMouseData()
        local inException = false
        GamePrint(tostring(mouseClicked))
        GamePrint("w " .. tostring(x) .. " " ..  tostring(x + size.width))
        GamePrint("h " ..tostring(y) .. " " .. tostring(y + size.height))
        GamePrint("m " ..tostring(mouseX) .. " " .. tostring(mouseY))
        if mouseX > x and mouseX < x + size.width and mouseY > y and mouseY < y + size.height then 
            for _=1, #self.selectableAreaExceptions do local v = self.selectableAreaExceptions[_] 
                if mouseX > v[1] and mouseX < v[1] + v[3] and mouseY > v[2] and mouseY < v[2] + v[4] then 
                    inException = true;
                    break;
                end
            end
            if mouseClicked and not inException then 
                local moveX = mouseX - self.mouseLastX
                local moveY = mouseY - self.mouseLastY
                self.currentX = self.currentX + moveX
                self.currentY = self.currentY + moveY
            end 
        else 
            self.mouseLastX = mouseX
            self.mouseLastY = mouseY
        end
    end
end

function DraggableElement:PropagateInteractableBounds(x, y, w, h)
    table.insert(self.selectableAreaExceptions, {x, y, w, h})
    return
end

return DraggableElement
