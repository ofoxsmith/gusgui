-- Thanks Horscht for letting me use EZMouse in GUSGUI
-- https://github.com/TheHorscht/EZMouse
dofile_once("data/scripts/lib/utilities.lua")

local world_x, world_y, sx, sy, dx, dy, left_down, left_pressed, right_down, right_pressed, left_down_last_frame,
    right_down_last_frame
local drag_start_sx, drag_start_sy = 0, 0
local resize_start_x, resize_start_y = 0, 0
local resize_start_sx, resize_start_sy = 0, 0
local resize_start_width, resize_start_height = 0, 0
local resize_last_width_fired, resize_last_height_fired = 0, 0
local current_widget_id = 1
local do_draw_resize_cursor = false
local resize_handle_size = 8

local function clamp(value, min, max)
	value = math.max(value, min)
	value = math.min(value, max)
	return value
end

-- Returns the value if it's not nil, otherwise returns val_if_nan
local function safe_divide(val, val_if_nan)
  local is_nan = val ~= val
  return is_nan and val_if_nan or val
end

-- float equals
local function feq(v1, v2)
  return math.abs(v1 - v2) < 0.001
end

function resize(props, change_left, change_top, change_right, change_bottom, corner, test)
  local function print(...)
    if test then
      _G.print(...)
    end
  end
  props.min_width = props.min_width or 1
  props.min_height = props.min_height or 1
  props.max_width = props.max_width or 999999
  props.max_height = props.max_height or 999999
  props.symmetrical = not not props.symmetrical
  props.constraints = props.constraints or {}
  props.constraints.left = props.constraints.left or -999999
  props.constraints.top = props.constraints.top or -999999
  props.constraints.right = props.constraints.right or 999999
  props.constraints.bottom = props.constraints.bottom or 999999

  -- Constrain to boundary constraints
  -- local change_left_min = props.constraints.left - props.x
  -- local change_top_min = props.constraints.top - props.y
  -- local change_right_max = props.constraints.right - (props.x + props.width)
  -- local change_bottom_max = props.constraints.bottom - (props.y + props.height)

  -- Constrain to max sizes
  local change_left_min = props.width - props.max_width
  local change_top_min = props.height - props.max_height
  local change_right_max = props.max_width - props.width
  local change_bottom_max = props.max_height - props.height

  -- Constrain to min sizes
  local change_left_max = props.width - props.min_width
  local change_top_max = props.height - props.min_height
  local change_right_min = props.min_width - props.width
  local change_bottom_min = props.min_height - props.height

  if props.symmetrical then
    change_left_max = change_left_max / 2
    change_top_max = change_top_max / 2
    change_right_min = change_right_min / 2
    change_bottom_min = change_bottom_min / 2
    change_left_min = change_left_min / 2
    change_top_min = change_top_min / 2
    change_right_max = change_right_max / 2
    change_bottom_max = change_bottom_max / 2
  end

  local min_scale_left = (props.width - change_left_max) / props.width
  local max_scale_left = (props.width - change_left_min) / props.width
  local min_scale_right = (props.width + change_right_min) / props.width
  local max_scale_right = (props.width + change_right_max) / props.width
  local min_scale_top = (props.height - change_top_max) / props.height
  local max_scale_top = (props.height - change_top_min) / props.height
  local min_scale_bottom = (props.height + change_bottom_min) / props.height
  local max_scale_bottom = (props.height + change_bottom_max) / props.height

  local aspect_ratio = props.width / props.height
  local origin_of_scaling_x, origin_of_scaling_y = props.width / 2, props.height / 2

  if corner == 1 then
    origin_of_scaling_x = props.width
    origin_of_scaling_y = props.height
  elseif corner == 2 then
    origin_of_scaling_x = props.width / 2
    origin_of_scaling_y = props.height
  elseif corner == 3 then
    origin_of_scaling_x = 0
    origin_of_scaling_y = props.height
  elseif corner == 4 then
    origin_of_scaling_x = 0
    origin_of_scaling_y = props.height / 2
  elseif corner == 5 then
    origin_of_scaling_x = 0
    origin_of_scaling_y = 0
  elseif corner == 6 then
    origin_of_scaling_x = props.width / 2
    origin_of_scaling_y = 0
  elseif corner == 7 then
    origin_of_scaling_x = props.width
    origin_of_scaling_y = 0
  elseif corner == 8 then
    origin_of_scaling_x = props.width
    origin_of_scaling_y = props.height / 2
  end

  local function get_new_width(change_left, change_right)
    return props.width - change_left + change_right
  end

  local function get_new_height(change_top, change_bottom)
    return props.height - change_top + change_bottom
  end

  local desired_scale_x = get_new_width(change_left, change_right) / props.width
  local desired_scale_y = get_new_height(change_top, change_bottom) / props.height

  -- Determine which scales need to be taken into account
  -- Get min and max scales of all into account taken scales
  -- Clamp desired scale between those min maxes
  local secondary = { left = false, top = false, right = false, bottom = false }
  local resize_left = corner == 1 or corner == 8 or corner == 7
  local resize_top = corner == 1 or corner == 2 or corner == 3
  local resize_right = corner == 3 or corner == 4 or corner == 5
  local resize_bottom = corner == 5 or corner == 6 or corner == 7

  if resize_left then
    if props.symmetrical then
      secondary.right = true
    end
    if props.aspect and not resize_top and not resize_bottom then
      secondary.top = true
      secondary.bottom = true
    end
  end

  if resize_top then
    if props.symmetrical then
      secondary.bottom = true
    end
    if props.aspect and not resize_left and not resize_right then
      secondary.left = true
      secondary.right = true
    end
  end

  if resize_right then
    if props.symmetrical then
      secondary.left = true
    end
    if props.aspect and not resize_top and not resize_bottom then
      secondary.top = true
      secondary.bottom = true
    end
  end

  if resize_bottom then
    if props.symmetrical then
      secondary.top = true
    end
    if props.aspect and not resize_left and not resize_right then
      secondary.left = true
      secondary.right = true
    end
  end

  if resize_left or resize_right then
    if secondary.top then
      desired_scale_x = math.min(desired_scale_x, max_scale_top)
    end
    if secondary.bottom then
      desired_scale_x = math.min(desired_scale_x, max_scale_bottom)
    end
  end

  if resize_top or resize_bottom then
    if secondary.left then
      desired_scale_y = math.min(desired_scale_y, max_scale_left)
    end
    if secondary.right then
      desired_scale_y = math.min(desired_scale_y, max_scale_right)
    end
  end

  if resize_left then
    desired_scale_x = clamp(desired_scale_x, min_scale_left, max_scale_left)
    desired_scale_x = math.max(desired_scale_x, 0)
  end

  if resize_top then
    desired_scale_y = clamp(desired_scale_y, min_scale_top, max_scale_top)
    desired_scale_y = math.max(desired_scale_y, 0)
  end

  if resize_right then
    desired_scale_x = clamp(desired_scale_x, min_scale_right, max_scale_right)
    desired_scale_x = math.max(desired_scale_x, 0)
  end

  if resize_bottom then
    desired_scale_y = clamp(desired_scale_y, min_scale_bottom, max_scale_bottom)
    desired_scale_y = math.max(desired_scale_y, 0)
  end

  if secondary.left then
    if props.symmetrical then
      max_scale_left = (max_scale_left - 1) * 2 + 1
    end
    desired_scale_x = clamp(desired_scale_x, min_scale_left, max_scale_left)
  end
  if secondary.right then
    if props.symmetrical then
      max_scale_right = (max_scale_right - 1) * 2 + 1
    end
    desired_scale_x = clamp(desired_scale_x, min_scale_right, max_scale_right)
  end
  if secondary.top then
    if props.symmetrical then
      max_scale_top = (max_scale_top - 1) * 2 + 1
    end
    desired_scale_y = clamp(desired_scale_y, min_scale_top, max_scale_top)
  end
  if secondary.bottom then
    if props.symmetrical then
      max_scale_bottom = (max_scale_bottom - 1) * 2 + 1
    end
    desired_scale_y = clamp(desired_scale_y, min_scale_bottom, max_scale_bottom)
  end

  local scale_x_percent = origin_of_scaling_x / props.width
  local scale_y_percent = origin_of_scaling_y / props.height

  local symmetry_multiplier = 1
  if props.symmetrical then
    scale_x_percent = 0.5
    scale_y_percent = 0.5
    symmetry_multiplier = 2
  end

  if props.aspect then
    local scale = 1
    if corner % 2 == 1 then
      scale = math.max(desired_scale_y, desired_scale_x)
    elseif corner == 2 or corner == 6 then
      scale = desired_scale_y
    elseif corner == 8 or corner == 4 then
      scale = desired_scale_x
    end
    if secondary.left then
      local s = max_scale_left
      if secondary.right then
        s = ((s - 1) * 2) + 1
      end
      scale = clamp(scale, min_scale_left, s)
    end
    if secondary.right then
      local s = max_scale_right
      if secondary.left then
        s = ((s - 1) * 2) + 1
      end
      scale = clamp(scale, min_scale_right, s)
    end
    if secondary.top then
      local s = max_scale_top
      if secondary.bottom then
        s = ((s - 1) * 2) + 1
      end
      scale = clamp(scale, min_scale_top, s)
    end
    if secondary.bottom then
      local s = max_scale_bottom
      if secondary.top then
        s = ((s - 1) * 2) + 1
      end
      scale = clamp(scale, min_scale_bottom, s)
    end

    if resize_left then
      local s = max_scale_left
      if secondary.right then
        s = ((s - 1) * 2) + 1
      end
      scale = clamp(scale, min_scale_left, s)
    end
    if resize_top then
      local s = max_scale_top
      if secondary.bottom then
        s = ((s - 1) * 2) + 1
      end
      scale = clamp(scale, min_scale_top, s)
    end
    if resize_right then
      local s = max_scale_right
      if secondary.left then
        s = ((s - 1) * 2) + 1
      end
      scale = clamp(scale, min_scale_right, s)
    end
    if resize_bottom then
      local s = max_scale_bottom
      if secondary.top then
        s = ((s - 1) * 2) + 1
      end
      scale = clamp(scale, min_scale_bottom, s)
    end

    desired_scale_x = scale
    desired_scale_y = scale
  end

  change_left = scale_x_percent * props.width * (1 - desired_scale_x)
  change_top = scale_y_percent * props.height * (1 - desired_scale_y)
  change_right = (1 - scale_x_percent) * -props.width * (1 - desired_scale_x)
  change_bottom = (1 - scale_y_percent) * -props.height * (1 - desired_scale_y)

  change_left = change_left * symmetry_multiplier
  change_top = change_top * symmetry_multiplier
  change_right = change_right * symmetry_multiplier
  change_bottom = change_bottom * symmetry_multiplier

  -- Now handle outside constraints

  -- Calculate by how much we overshot the constraints, then shrink all related sides equally
  local overshoot_left = math.max(0, props.constraints.left - (props.x + change_left))
  local overshoot_top = math.max(0, props.constraints.top - (props.y + change_top))
  local overshoot_right = math.max(0, (props.x + props.width + change_right) - props.constraints.right)
  local overshoot_bottom = math.max(0, (props.y + props.height + change_bottom) - props.constraints.bottom)

  local function safe_division(val, value_if_nan)
    local is_nan = val ~= val
    return is_nan and value_if_nan or val
  end
  -- if this is 0.1 it means it overshoots by 10% of its change_left
  local overshoot_scale_left = math.abs(safe_division(overshoot_left / change_left, 0))
  local overshoot_scale_top = math.abs(safe_division(overshoot_top / change_top, 0))
  local overshoot_scale_right = math.abs(safe_division(overshoot_right / change_right, 0))
  local overshoot_scale_bottom = math.abs(safe_division(overshoot_bottom / change_bottom, 0))

  -- Find the biggest overshoot scale and shrink all related sides by that
  local biggest_overshoot_scale = math.max(overshoot_scale_left, overshoot_scale_top, overshoot_scale_right, overshoot_scale_bottom)
  local scale = 0
  if props.aspect then
    scale = biggest_overshoot_scale
  end
  if resize_left or secondary.left then
    local scale = math.max(scale, overshoot_scale_left)
    if props.symmetrical then
      scale = math.max(scale, overshoot_scale_left, overshoot_scale_right)
    end

    change_left = change_left * (1 - scale)
  end
  if resize_right or secondary.right then
    local scale = math.max(scale, overshoot_scale_right)
    if props.symmetrical then
      scale = math.max(scale, overshoot_scale_left, overshoot_scale_right)
    end
    change_right = change_right * (1 - scale)
  end
  if resize_bottom or secondary.bottom then
    local scale = math.max(scale, overshoot_scale_bottom)
    if props.symmetrical then
      scale = math.max(scale, overshoot_scale_top, overshoot_scale_bottom)
    end
    change_bottom = change_bottom * (1 - scale)
  end
  if resize_top or secondary.top then
    local scale = math.max(scale, overshoot_scale_top)
    if props.symmetrical then
      scale = math.max(scale, overshoot_scale_top, overshoot_scale_bottom)
    end
    change_top = change_top * (1 - scale)
  end

  -- If very very close to the constraints, just "round up" to them and also adjust related sides by the same amount
  local left = props.x + change_left
  if left - props.constraints.left >= 0 and left - props.constraints.left < 0.00001 then
    local new_change_left = props.constraints.left - props.x
    change_right = change_right + (change_left - new_change_left)
    change_left = new_change_left
  end
  local top = props.y + change_top
  if top - props.constraints.top >= 0 and top - props.constraints.top < 0.00001 then
    local new_change_top = props.constraints.top - props.y
    change_bottom = change_bottom + (change_top - new_change_top)
    change_top = new_change_top
  end
  local right = props.x + props.width + change_right
  if props.constraints.right - right >= 0 and props.constraints.right - right < 0.00001 then
    local new_change_right = props.constraints.right - (props.x + props.width)
    change_left = change_left + (change_right - new_change_right)
    change_right = new_change_right
  end
  local bottom = props.y + props.height + change_bottom
  if props.constraints.bottom - bottom >= 0 and props.constraints.bottom - bottom < 0.00001 then
    local new_change_bottom = props.constraints.bottom - (props.y + props.height)
    change_top = change_top + (change_bottom - new_change_bottom)
    change_bottom = new_change_bottom
  end

  if props.quantization then
    local function round(v)
      if v > 0 then
        return math.floor(v)
      else
        return math.ceil(v)
      end
    end
    if props.aspect then
      -- This could probably be done better but I don't wanna think about it anymore...
      local new_change_left = round(change_left / props.quantization) * props.quantization
      local new_change_top = round(change_top / props.quantization) * props.quantization
      local new_change_right = round(change_right / props.quantization) * props.quantization
      local new_change_bottom = round(change_bottom / props.quantization) * props.quantization
      local scale_increase_left = (props.width - new_change_left) / props.width
      local scale_increase_top = (props.height - new_change_top) / props.height
      local scale_increase_right = (props.width + new_change_right) / props.width
      local scale_increase_bottom = (props.height + new_change_bottom) / props.height

      local new_scale = 1
      -- Take the dimension scale increase of the smaller size
      if props.width < props.height then
        local width_increase = -change_left + change_right
        local quantized_width_increase = round(width_increase / props.quantization) * props.quantization
        new_scale = (props.width + quantized_width_increase) / props.width
      else
        local height_increase = -change_top + change_bottom
        local quantized_height_increase = round(height_increase / props.quantization) * props.quantization
        new_scale = (props.height + quantized_height_increase) / props.height
      end
      
      change_left = scale_x_percent * props.width * (1 - new_scale)     
      change_top = scale_y_percent * props.height * (1 - new_scale)
      change_right = (1 - scale_x_percent) * -props.width * (1 - new_scale)
      change_bottom = (1 - scale_y_percent) * -props.height * (1 - new_scale)
    else
      change_left = round(change_left / props.quantization) * props.quantization
      change_top = round(change_top / props.quantization) * props.quantization
      change_right = round(change_right / props.quantization) * props.quantization
      change_bottom = round(change_bottom / props.quantization) * props.quantization
    end
  end

  return change_left, change_top, change_right, change_bottom
end

local function is_inside_rect(x, y, rect_x, rect_y, width, height)
    return not ((x < rect_x) or (x > rect_x + width) or (y < rect_y) or (y > rect_y + height))
end

local dragging_widget = {
    last_frame_ran = 0
}
-- Renders a widget at the mouse potion and returns the change in position from being dragged
local function render_dragging_widget_at_mouse_pos(current_x, current_y)
    local pos_x, pos_y = sx - 50 / 2, sy - 50 / 2
    if dragging_widget.last_frame_ran >= GameGetFrameNum() then
        -- We only need to render it once, it it has already been rendered this frame, return the last result
        return dragging_widget.result
    end
    dragging_widget.last_frame_ran = GameGetFrameNum()
    dragging_widget.result = dragging_widget.result or {}
    dragging_widget.result.dx = 0
    dragging_widget.result.dy = 0
    dragging_widget.result.was_dragged = false
    dragging_widget.result.drag_start = false
    dragging_widget.result.drag_end = false
    GuiIdPushString(EZMouse_gui, "boo")
    GuiOptionsAddForNextWidget(EZMouse_gui, GUI_OPTION.NoPositionTween)
    GuiOptionsAddForNextWidget(EZMouse_gui, GUI_OPTION.ClickCancelsDoubleClick)
    GuiOptionsAddForNextWidget(EZMouse_gui, GUI_OPTION.DrawNoHoverAnimation)
    GuiOptionsAddForNextWidget(EZMouse_gui, GUI_OPTION.NoSound)
    GuiOptionsAddForNextWidget(EZMouse_gui, GUI_OPTION.IsExtraDraggable)
    GuiZSetForNextWidget(EZMouse_gui, -999999)
    -- Draw an invisible image button that catches the native dragging
    GuiImageButton(EZMouse_gui, 3, pos_x, pos_y, "", "GUSGUI_PATHdrag_mask.png")
    local _, _, _, _, _, _, _, dx, dy = GuiGetPreviousWidgetInfo(EZMouse_gui)
    if (not feq(dx, pos_x) or not feq(dy, pos_y)) and dx ~= 0 and dy ~= 0 then
        if not dragging_widget.last_x then
            dragging_widget.last_x = dx
            dragging_widget.last_y = dy
            dragging_widget.result.drag_start = true
            dragging_widget.result.start_x = current_x
            dragging_widget.result.start_y = current_y
            dragging_widget.result.drag_offset_x = sx - current_x
            dragging_widget.result.drag_offset_y = sy - current_y
            dragging_widget.result.drag_start_x = sx
            dragging_widget.result.drag_start_y = sy
        end
        dragging_widget.result.dx = dx - dragging_widget.last_x
        dragging_widget.result.dy = dy - dragging_widget.last_y
        dragging_widget.last_x = dx
        dragging_widget.last_y = dy
        if dragging_widget.result.dx ~= 0 or dragging_widget.result.dy ~= 0 then
            dragging_widget.result.was_dragged = true
        end
    elseif dragging_widget.last_x then
        dragging_widget.last_x = nil
        dragging_widget.last_y = nil
        dragging_widget.result.drag_end = true
    end
    GuiIdPop(EZMouse_gui)
    return dragging_widget.result
end

local function draw_resize_cursor(gui, handle_index, x, y)
    local sprite = handle_index % 2 == 0 and "horizontal" or "diagonal"
    local rotations = {{
        x = -(25 / 2) + 0.5,
        y = (25 / 2) + 0.5,
        rot = math.rad(90)
    }, {
        x = -(25 / 2) + 0.5,
        y = (25 / 2) + 0.5,
        rot = math.rad(90)
    }, {
        x = (25 / 2) + 0.5,
        y = (25 / 2) + 0.5,
        rot = 0
    }, {
        x = (25 / 2) + 0.5,
        y = (25 / 2) + 0.5,
        rot = 0
    }, {
        x = -(25 / 2) + 0.5,
        y = (25 / 2) + 0.5,
        rot = math.rad(90)
    }, {
        x = -(25 / 2) + 0.5,
        y = (25 / 2) + 0.5,
        rot = math.rad(90)
    }, {
        x = (25 / 2) + 0.5,
        y = (25 / 2) + 0.5,
        rot = 0
    }, {
        x = (25 / 2) + 0.5,
        y = (25 / 2) + 0.5,
        rot = 0
    }}
    GuiImage(gui, 87878, sx - rotations[handle_index].x, sy - rotations[handle_index].y,
        "GUSGUI_PATHcursor_resize_" .. sprite .. ".png", 1, 1, 1, rotations[handle_index].rot)
end

local function calculate_handle_props(self, resize_handle_size)
    return {{
        x = self.x - (resize_handle_size / 2),
        y = self.y - (resize_handle_size / 2),
        width = resize_handle_size,
        height = resize_handle_size,
        move = {-1, -1}
    }, -- top left
    {
        x = self.x + (resize_handle_size / 2),
        y = self.y - (resize_handle_size / 2),
        width = self.width - resize_handle_size,
        height = resize_handle_size,
        move = {0, -1}
    }, -- top
    {
        x = self.x + self.width - (resize_handle_size / 2),
        y = self.y - (resize_handle_size / 2),
        width = resize_handle_size,
        height = resize_handle_size,
        move = {1, -1}
    }, -- top right
    {
        x = self.x + self.width - (resize_handle_size / 2),
        y = self.y + (resize_handle_size / 2),
        width = resize_handle_size,
        height = self.height - resize_handle_size,
        move = {1, 0}
    }, -- right
    {
        x = self.x + self.width - (resize_handle_size / 2),
        y = self.y + self.height - (resize_handle_size / 2),
        width = resize_handle_size,
        height = resize_handle_size,
        move = {1, 1}
    }, -- bottom right
    {
        x = self.x + (resize_handle_size / 2),
        y = self.y + self.height - (resize_handle_size / 2),
        width = self.width - resize_handle_size,
        height = resize_handle_size,
        move = {0, 1}
    }, -- bottom
    {
        x = self.x - (resize_handle_size / 2),
        y = self.y + self.height - (resize_handle_size / 2),
        width = resize_handle_size,
        height = resize_handle_size,
        move = {-1, 1}
    }, -- bottom left
    {
        x = self.x - (resize_handle_size / 2),
        y = self.y + (resize_handle_size / 2),
        width = resize_handle_size,
        height = self.height - resize_handle_size,
        move = {-1, 0}
    } -- left
    }
end

local function fire_event(self, name, ...)
    for i, listener in ipairs(self.event_listeners[name]) do
        listener(self, ...)
    end
end

local widget_instances = setmetatable({}, {
    __mode = "v"
})
-- The privates should be read-only from outside
local widget_privates = setmetatable({}, {
    __mode = "k"
})
local Widget = {}
function Widget:__index(key)
    if key == "_members" then
        error("Don't touch the internals :)", 2)
    end
    -- Private getter (read-only)
    if widget_privates[self][key] ~= nil then
        return widget_privates[self][key]
    end
    -- Static getter
    if rawget(Widget, key) ~= nil then
        return rawget(Widget, key)
    end
    -- Public getter
    return self._members[key]
end
function Widget:__newindex(key, value)
    if widget_privates[self][key] ~= nil then
        error("'" .. key .. "' is read-only.", 2)
    end
    self._members[key] = value
end
local function validate_constraints(c)
    c = c or {}
    if type(c) ~= "table" then
        error("'constraints' must be a table", 3)
    end
    for k, v in pairs(c) do
        if k ~= "left" and k ~= "top" and k ~= "right" and k ~= "bottom" then
            error(("'%s' is not a valid constraint type"):format(k), 3)
        end
        if type(v) ~= "number" then
            error(("Value for constraints.'%s' must be of type 'number'."):format(k), 3)
        end
    end
    return c
end
-- Constructor
function Widget:__call(props)
    if type(props) ~= "table" then
        error("'props' needs to be a table.", 2)
    end

    -- This could probably be done better
    local instance = setmetatable({
        _members = {
            x = props.x or 0,
            y = props.y or 0,
            z = props.z or 0,
            width = props.width or 100,
            height = props.height or 100,
            min_width = props.min_width or 1,
            min_height = props.min_height or 1,
            max_width = props.max_width or 999999,
            max_height = props.max_height or 999999,
            draggable = props.draggable == nil and true or not not props.draggable,
            drag_anchor = props.drag_anchor or nil, -- either "center" or nil
            drag_granularity = props.drag_granularity or 0.1, -- NOT IMPLEMENTED
            resizable = not not props.resizable,
            resize_granularity = props.resize_granularity or 0.1,
            resize_symmetrical = not not props.resize_symmetrical,
            resize_keep_aspect_ratio = not not props.resize_keep_aspect_ratio,
            enabled = props.enabled == nil and true or not not props.enabled,
            hoverable = props.hoverable == nil and true or not not props.hoverable,
            constraints = validate_constraints(props.constraints),
            event_listeners = {
                -- mouse_down = {}, -- Doesn't work anymore with the new method
                drag = {},
                drag_start = {},
                drag_end = {},
                resize = {},
                resize_start = {},
                resize_end = {}
            }
        }
    }, Widget)
    widget_privates[instance] = {
        resizing = false,
        dragging = false,
        hovered = false,
        id = current_widget_id
    }
    current_widget_id = current_widget_id + 1

    if instance.min_width > instance.width then
        error(string.format("min_width(%d) needs to be smaller than width(%d).", instance.min_width, instance.width), 2)
    end
    if instance.min_height > instance.height then
        error(
            string.format("min_height(%d) needs to be smaller than height(%d).", instance.min_height, instance.height),
            2)
    end

    table.insert(widget_instances, instance)
    table.sort(widget_instances, function(a, b)
        return a.z < b.z
    end)

    return instance
end

function Widget:AddEventListener(event_name, listener)
    if not self.event_listeners[event_name] then
        error("No event by the name of '" .. event_name .. "'", 2)
    end
    table.insert(self.event_listeners[event_name], listener)
    return listener
end

function Widget:RemoveEventListener(event_name, listener)
    if not self.event_listeners[event_name] then
        error("No event by the name of '" .. event_name .. "'", 2)
    end
    for i, v in ipairs(self.event_listeners[event_name]) do
        if v == listener then
            table.remove(self.event_listeners[event_name], i)
            return
        end
    end
    error("Cannot remove a listener that was never registered.", 2)
end

function Widget:DebugDraw(gui, sprite)
    GuiIdPushString(gui, "EZMouse_debug_draw_" .. tostring(widget_privates[self].id))
    GuiOptionsAddForNextWidget(gui, GUI_OPTION.NonInteractive)
    GuiZSetForNextWidget(gui, self.z)
    GuiImage(gui, 2, self.x, self.y, "GUSGUI_PATH" ..
        (widget_privates[self].hovered and "green_square_10x10.png" or (sprite or "red") .. "_square_10x10.png"), 0.5,
        self.width / 10, self.height / 10)
    if widget_privates[self].resize_handle_hovered or widget_privates[self].resize_handle_index then
        GuiOptionsAddForNextWidget(gui, GUI_OPTION.NonInteractive)
        GuiZSetForNextWidget(gui, self.z - 0.5)
        GuiImage(gui, 3, widget_privates[self].resize_handle.x, widget_privates[self].resize_handle.y,
            "GUSGUI_PATH" .. "green_square_10x10.png", 1, widget_privates[self].resize_handle.width / 10,
            widget_privates[self].resize_handle.height / 10)
    end
    GuiIdPop(gui)
end

function Widget:Destroy()
    for i = #widget_instances, 1, -1 do
        if widget_instances[i] == self then
            table.remove(widget_instances, i)
        end
    end
end

setmetatable(Widget, Widget)

local function update(gui)
    EZMouse_gui = gui
    if not controls_component then
        local entity_name = "EZMouse_controls_entity"
        local controls_entity = EntityGetWithName(entity_name)
        if controls_entity == 0 then
            controls_entity = EntityCreateNew(entity_name)
        end
        controls_component = EntityAddComponent2(controls_entity, "ControlsComponent")
    end

    mouse_loop_last_sx = mouse_loop_last_sx or 0
    mouse_loop_last_sy = mouse_loop_last_sy or 0
    -- Get whatever state we can directly from the component
    if controls_component and GameGetFrameNum() > 10 then
        left_down = ComponentGetValue2(controls_component, "mButtonDownFire")
        left_pressed = ComponentGetValue2(controls_component, "mButtonFrameFire") == GameGetFrameNum()
        right_down = ComponentGetValue2(controls_component, "mButtonDownRightClick")
        right_pressed = ComponentGetValue2(controls_component, "mButtonFrameRightClick") == GameGetFrameNum()

        local screen_width, screen_height = GuiGetScreenDimensions(EZMouse_gui)
        local mouse_raw_x, mouse_raw_y = ComponentGetValue2(controls_component, "mMousePositionRaw")
        sx, sy = mouse_raw_x * screen_width / 1280, mouse_raw_y * screen_height / 720

        -- Calculate mMouseDelta ourselves because the native one isn't consistent across all window sizes
        dx, dy = sx - mouse_loop_last_sx, sy - mouse_loop_last_sy
        -- If a widget is being hovered, saves a reference to the instance, otherwise stays nil
        local hovered_draggable
        -- If one of a widget's resize handle is being hovered, saves a reference to the widget instance and the hovered resize handle, otherwise stays nil
        local resize_handle_hovered_draggable
        if not dragging_draggable and not resizing_draggable then
            -- Reset hover status of all widgets at the beginning of every loop
            for i, draggable in ipairs(widget_instances) do
                widget_privates[draggable].hovered = false
                widget_privates[draggable].resize_handle_hovered = nil
            end
            -- Check current hover status of all widgets, main area and resize handles
            for i, draggable in ipairs(widget_instances) do
                if draggable.enabled then
                    local resize_handle_size_ = draggable.resizable and resize_handle_size or 0
                    widget_privates[draggable].hovered = is_inside_rect(sx, sy, draggable.x + resize_handle_size_ / 2,
                        draggable.y + resize_handle_size_ / 2, draggable.width - resize_handle_size_,
                        draggable.height - resize_handle_size_)
                    widget_privates[draggable].hovered = draggable.hoverable and widget_privates[draggable].hovered
                    if widget_privates[draggable].hovered then
                        hovered_draggable = draggable
                        -- Only one should be able to be hovered at a time, so no need to continue
                        break
                    else
                        local resize_handles = calculate_handle_props(draggable, resize_handle_size_)
                        for i, handle in ipairs(resize_handles) do
                            if is_inside_rect(sx, sy, handle.x, handle.y, handle.width, handle.height) then
                                widget_privates[draggable].resize_handle_hovered = i
                                widget_privates[draggable].resize_handle = resize_handles[i]
                                resize_handle_hovered_draggable = {
                                    draggable = draggable,
                                    hovered_handle = resize_handles[i],
                                    handle_index = i
                                }
                                break
                            end
                        end
                        if resize_handle_hovered_draggable then
                            break
                        end
                    end
                end
            end
        end

        if hovered_draggable and hovered_draggable.draggable then
            local draggable = hovered_draggable
            local result = render_dragging_widget_at_mouse_pos(draggable.x, draggable.y)
            if result.drag_start then
                widget_privates[draggable].dragging = true
                dragging_draggable = draggable
                fire_event(draggable, "drag_start")
                drag_start_sx = sx
                drag_start_sy = sy
            end
        end
        if resize_handle_hovered_draggable then
            local draggable = resize_handle_hovered_draggable.draggable
            local result = render_dragging_widget_at_mouse_pos(draggable.x, draggable.y)
            if do_draw_resize_cursor then
                draw_resize_cursor(gui, resize_handle_hovered_draggable.handle_index, sx, sy)
            end
            if result.drag_start then
                resizing_draggable = draggable
                widget_privates[draggable].resize_handle_index = resize_handle_hovered_draggable.handle_index
                widget_privates[draggable].resize_handle = resize_handle_hovered_draggable.hovered_handle
                fire_event(draggable, "resize_start", {
                    handle_index = resize_handle_hovered_draggable.handle_index
                })
                resize_start_sx = resize_handle_hovered_draggable.hovered_handle.x + (resize_handle_size / 2)
                resize_start_sy = resize_handle_hovered_draggable.hovered_handle.y + (resize_handle_size / 2)
                resize_start_x = draggable.x
                resize_start_y = draggable.y
                resize_start_width = draggable.width
                resize_start_height = draggable.height
                resize_last_width_fired = draggable.width -- For detecting whether it was resized or not (especially when quantized)
                resize_last_height_fired = draggable.height
                aspect_ratio = draggable.width / draggable.height
            end
        end

        if dragging_draggable then
            -- Here happens the dragging
            local draggable = dragging_draggable
            local result = render_dragging_widget_at_mouse_pos(draggable.x, draggable.y)
            if result.was_dragged then
                local drag_offset_x = result.drag_offset_x
                local drag_offset_y = result.drag_offset_y
                if draggable.drag_anchor == "center" then
                    drag_offset_x = draggable.width / 2
                    drag_offset_y = draggable.height / 2
                end
                draggable.x = math.min((draggable.constraints.right or 99999) - draggable.width,
                    math.max(draggable.constraints.left or 0, sx - drag_offset_x))
                draggable.y = math.min((draggable.constraints.bottom or 99999) - draggable.height,
                    math.max(draggable.constraints.top or 0, sy - drag_offset_y))
                fire_event(draggable, "drag", {
                    dx = result.dx,
                    dy = result.dy
                })
            end
            if result.drag_end then
                widget_privates[draggable].dragging = false
                dragging_draggable = nil
                fire_event(draggable, "drag_end", {
                    start_x = result.start_x,
                    start_y = result.start_y
                })
            end
        elseif resizing_draggable then
            -- Here happens the resizing
            local draggable = resizing_draggable
            local result = render_dragging_widget_at_mouse_pos(draggable.x, draggable.y)
            if do_draw_resize_cursor then
                draw_resize_cursor(gui, widget_privates[draggable].resize_handle_index, sx, sy)
            end
            if result.was_dragged then
                local dx = sx - resize_start_sx
                local dy = sy - resize_start_sy
                local change_left = dx * -math.min(widget_privates[draggable].resize_handle.move[1], 0)
                local change_right = dx * math.max(widget_privates[draggable].resize_handle.move[1], 0)
                local change_top = dy * -math.min(widget_privates[draggable].resize_handle.move[2], 0)
                local change_bottom = dy * math.max(widget_privates[draggable].resize_handle.move[2], 0)
                change_left, change_top, change_right, change_bottom = resize({
                    x = resize_start_x,
                    y = resize_start_y,
                    width = resize_start_width,
                    height = resize_start_height,
                    min_width = draggable.min_width,
                    min_height = draggable.min_height,
                    max_width = draggable.max_width,
                    max_height = draggable.max_height,
                    constraints = draggable.constraints,
                    quantization = draggable.resize_granularity,
                    symmetrical = draggable.resize_symmetrical,
                    aspect = draggable.resize_keep_aspect_ratio
                }, change_left, change_top, change_right, change_bottom, widget_privates[draggable].resize_handle_index)

                draggable.x = resize_start_x + change_left
                draggable.y = resize_start_y + change_top
                draggable.width = resize_start_width - change_left + change_right
                draggable.height = resize_start_height - change_top + change_bottom

                -- Recalculate the values
                local resize_handles = calculate_handle_props(draggable, resize_handle_size)
                widget_privates[draggable].resize_handle =
                    resize_handles[widget_privates[draggable].resize_handle_index]
                local has_moved = resize_last_width_fired ~= draggable.width or resize_last_height_fired ~=
                                      draggable.height
                if has_moved then
                    fire_event(draggable, "resize", {
                        handle_index = widget_privates[draggable].resize_handle_index
                    })
                    resize_last_width_fired = draggable.width
                    resize_last_height_fired = draggable.height
                end
            end
            if result.drag_end then
                fire_event(draggable, "resize_end", {
                    handle_index = widget_privates[draggable].resize_handle_index
                })
                widget_privates[draggable].resize_handle_index = nil
                resizing_draggable = nil
            end
        end

        world_x, world_y = ComponentGetValue2(controls_component, "mMousePosition")
        local movement_tolerance = 0.5
        local vx = sx - mouse_loop_last_sx
        local vy = sy - mouse_loop_last_sy
        mouse_loop_last_sx = sx
        mouse_loop_last_sy = sy
        left_down_last_frame = left_down
        right_down_last_frame = right_down
    end
end

return {
    Widget = Widget,
    Update = update
}