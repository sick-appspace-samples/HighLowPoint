--Start of Global Scope---------------------------------------------------------

local helper = require('helpers')

local DELAY = 1500 -- Delay time for demonstration

-- Colors
local BLACK = {0, 0, 0}
local GREEN = {0, 200, 0}
local RED = {200, 0, 0}
local BLUE = {59, 156, 208}
local ORANGE = {242, 148, 0}
local WHITE = {255, 255, 255}

local MM_TO_PROCESS = 13 -- 13mm slices

-- Offsets to get plot position correct relative to heightmap
local OFFSET_X = 40
local OFFSET_Y = -70

local v2D = View.create()

--End of Global Scope-----------------------------------------------------------

--Start of Function and Event Scope---------------------------------------------

local function main()
  -- Load image and extract heightmap information
  local heightMap = Object.load('resources/image_4.json')
  local minZ, maxZ = heightMap[1]:getMinMax()
  local zRange = maxZ - minZ
  local pixelSizeX, pixelSizeY = heightMap[1]:getPixelSize()
  local heightMapW, heightMapH = heightMap[1]:getSize()

  -- Correct the heightMaps origin, so it is centered on the x-axis
  local stepsize = math.ceil(MM_TO_PROCESS / pixelSizeY) -- convert mm to pixel steps

  -- ROI Rectangle
  local scanBox = Shape.createRectangle(Point.create(heightMapW * pixelSizeX / 2 + 2.5, 0),
                                                     heightMapW * pixelSizeX, MM_TO_PROCESS)

  -- Create a 2D white background
  local background = Shape.createRectangle(Point.create(OFFSET_X, OFFSET_Y + (maxZ + minZ) / 2),
                                                        heightMapW * pixelSizeX + 20, zRange + 20)

  -- Get center of the background and its x and y values
  local center = background:getCenterOfGravity()
  local centerX = center:getX()
  local centerY = center:getY()

  -- Process data
  for i = 90, heightMapH - 80, stepsize do
    -- Aggregate a number of profiles together
    local profilesToAggregate = {}
    for j = 0, stepsize - 1 do -- stepsize = MM_TO_PROCESS / pixelSizeY
      if i + j < heightMapH then
        profilesToAggregate[#profilesToAggregate + 1] = heightMap[1]:extractRowProfile(i + j)
      end
    end

    -- Combine profiles to one mean profile
    local frameProfile = Profile.aggregate(profilesToAggregate, 'MEAN')

    -- Get max and min value from the mean profile
    local max, indexMax = frameProfile:getMax()
    local min, indexMin = frameProfile:getMin()

    -- Get the coordinates for max and min
    local coord = frameProfile:getCoordinate(indexMax)
    local coord2 = frameProfile:getCoordinate(indexMin)

    -- Remove noise from profile
    frameProfile = frameProfile:median(3)

    -- Create points and lines for max, min, distance and height
    local maxPoint = Point.create(coord:getX() + OFFSET_X, max + OFFSET_Y)
    local minPoint = Point.create(coord2:getX() + OFFSET_X, min + OFFSET_Y)
    local heightPoint = Point.create(coord:getX() + OFFSET_X, min + OFFSET_Y)
    local distLine = Shape.createLineSegment(maxPoint, minPoint)
    local distance = maxPoint:getDistance(minPoint)
    local heightLine = Shape.createLineSegment(maxPoint, heightPoint)
    local height = maxPoint:getDistance(heightPoint)

    -- Create a box to move along the object
    local scannedFrame = scanBox:translate(0, i * pixelSizeY)

    -- Clear viewer
    v2D:clear()

    -- Add heightmap and scan box
    local id = View.ImageDecoration.create()
    id:setRange(minZ, maxZ)
    v2D:addHeightmap(heightMap[1], id)
    v2D:addShape(scannedFrame, helper.getDeco(BLACK, 0.5, nil, 1.0))

    -- Add the profile to the viewer
    v2D:addShape(background, helper.getDeco(WHITE))
    v2D:addShape(helper.profileToPolylines(frameProfile, false, nil, OFFSET_X, OFFSET_Y), helper.getDeco(BLUE))
    v2D:present()
    Script.sleep(DELAY)

    -- Add the max/min points and text to the viewer
    v2D:addShape(maxPoint, helper.getDeco(ORANGE, nil, 2))
    v2D:addShape(minPoint, helper.getDeco(ORANGE, nil, 2))
    v2D:addText('Max: x= ' .. helper.round(coord:getX()) .. ' y= ' ..
                helper.round(max), helper.getTextDeco(ORANGE, 3, centerX - 40, centerY + 8))
    v2D:addText('Min: x= ' .. helper.round(coord2:getX()) .. ' y= ' ..
                helper.round(min), helper.getTextDeco(ORANGE, 3, centerX + 4, centerY - 11))
    v2D:present()
    Script.sleep(DELAY)

    -- Add distance line and text to the viewer
    v2D:addShape(distLine, helper.getDeco(RED, 0.5))
    v2D:addText('Dist: ' .. helper.round(distance) .. ' mm', helper.getTextDeco(RED, 3, centerX - 16, centerY - 5))
    v2D:present()
    Script.sleep(DELAY)

    -- Add height point, line and text to the viewer
    v2D:addShape(heightPoint, helper.getDeco(ORANGE, nil, 2))
    v2D:addShape(heightLine, helper.getDeco(GREEN, 0.5))
    v2D:addText('Height diff: ' .. helper.round(height) .. ' mm',
                helper.getTextDeco(GREEN, 3, centerX - 40, centerY - 11))
    v2D:present()
    Script.sleep(DELAY)
  end
  print('App finished.')
end
--The following registration is part of the global scope which runs once after startup
--Registration of the 'main' function to the 'Engine.OnStarted' event
Script.register('Engine.OnStarted', main)
-- serve API in global scope
