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

-- Get x coordinate
local function getX(coordinate)
  if type(coordinate) == 'userdata' then
    return coordinate:getX()
  else
    return coordinate
  end
end

-- Make a profile into polylies
local function profileToPolylines(
  profile,
  closed,
  spaceBetweenPoints,
  offsetX,
  offsetY)
  -- If there is no profile, return nothing
  if not profile then
    return {}
  end

  -- Set offset and closed
  offsetX = offsetX or 0
  offsetX = offsetX + getX(Profile.getCoordinate(profile, 0))
  offsetY = offsetY or 0
  closed = closed or false

  -- Calculate the space between two profiles' points
  if not spaceBetweenPoints then
    if Profile.getSize(profile) > 1 then
      spaceBetweenPoints =
        getX(Profile.getCoordinate(profile, 1)) -
        getX(Profile.getCoordinate(profile, 0))
    else
      spaceBetweenPoints = 1
    end
  end

  -- Profile into vector
  local values,
    _,
    validFlags = profile:toVector()

  -- Create arrays
  local polylines = {}
  local pointBuff = {}

  if Profile.getValidFlagsEnabled(profile) then
    for i, value in pairs(values) do
      value = value + offsetY

      if validFlags[i] == 0 then
        -- Commulate Buffer to polyline
        if #pointBuff > 0 then
          polylines[#polylines + 1] = Shape.createPolyline(pointBuff, closed)
          pointBuff = {} -- Clear buffer
        end
      else
        local x = offsetX + i * spaceBetweenPoints
        pointBuff[#pointBuff + 1] = Point.create(x, value)
      end
    end
  else -- Don't care about valid flags
    for i, value in pairs(values) do
      local x = offsetX + i * spaceBetweenPoints
      pointBuff[#pointBuff + 1] = Point.create(x, value)
    end
  end

  if #pointBuff > 0 then
    polylines[#polylines + 1] = Shape.createPolyline(pointBuff, closed)
  end

  return polylines
end

-- Round integers
local function round(n)
  return math.floor(n * 100) / 100
end

local helper = {}
helper.getDeco = getDeco
helper.getTextDeco = getTextDeco
helper.profileToPolylines = profileToPolylines
helper.round = round

return helper
