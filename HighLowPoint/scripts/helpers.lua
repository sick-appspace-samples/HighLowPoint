local function getDeco(rgba, lineWidth, pointSize, fillAlpha)
  -- Alpha is 100% as default
  if not rgba[4] then
    rgba[4] = 255
  end

  -- Create a shape decoration
  local deco = View.ShapeDecoration.create()
  deco:setLineColor(rgba[1], rgba[2], rgba[3], rgba[4])
  deco:setFillColor(rgba[1], rgba[2], rgba[3], fillAlpha)

  -- Set line width and point size
  if lineWidth then
    deco:setLineWidth(lineWidth)
  end
  if pointSize then
    deco:setPointSize(pointSize)
  end

  return deco
end

local function getTextDeco(rgba, size, xPos, yPos)
  -- Set parameters
  size = size or 1
  xPos = xPos or 0
  yPos = yPos or 0
  rgba = rgba or {0, 0, 0}

  -- Alpha is 100% as default
  if #rgba == 3 then
    rgba[4] = 255
  end

  -- Create a text decoration
  local deco = View.TextDecoration.create()
  deco:setSize(size)
  deco:setColor(rgba[1], rgba[2], rgba[3], rgba[4])

  deco:setPosition(xPos, yPos)
  return deco
end

---Round integers
local function round(n)
  return math.floor(n * 100) / 100
end

local helper = {}
helper.getDeco = getDeco
helper.getTextDeco = getTextDeco
helper.round = round

return helper
