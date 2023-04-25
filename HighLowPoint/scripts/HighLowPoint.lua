--Start of Global Scope---------------------------------------------------------

local helper = require('helpers')

local DELAY = 1500 -- Delay time for demonstration

-- Colors
local BLACK = {0, 0, 0}
local GREEN = {0, 200, 0}
local RED = {200, 0, 0}
local ORANGE = {242, 148, 0}

local MM_TO_PROCESS = 13 -- 13mm slices

-- Offsets to get plot position correct relative to heightmap

local v2D = View.create()
local v2D2 = View.create('v2D2')

--End of Global Scope-----------------------------------------------------------

--Start of Function and Event Scope---------------------------------------------

local function main()
  -- Load image and extract heightmap information
  local heightMap = Object.load('resources/image_4.json')
  local minZ, maxZ = heightMap[1]:getMinMax()
  local zRange = maxZ - minZ
  local pixelSizeX, pixelSizeY = heightMap[1]:getPixelSize()
  local heightMapW, heightMapH = heightMap[1]:getSize()
  local origin = heightMap[1]:getOrigin()

  -- Correct the heightMaps origin, so it is centered on the x-axis
  local stepsize = math.ceil(MM_TO_PROCESS / pixelSizeY) -- convert mm to pixel steps

  -- ROI Rectangle
  local scanBox = Shape.createRectangle(Point.create(0, MM_TO_PROCESS/2),
                                                     heightMapW * pixelSizeX, MM_TO_PROCESS)

  -- Process data
  for i = 87, heightMapH - 80, stepsize do
    -- Aggregate a number of profiles together
    local profilesToAggregate = {}
    for j = 0, stepsize - 1 do -- stepsize = MM_TO_PROCESS / pixelSizeY
      if i + j < heightMapH then
        profilesToAggregate[#profilesToAggregate + 1] = heightMap[1]:extractRowProfile(i + j)
      end
    end

    -- Combine profiles to one mean profile
    local frameProfile = Profile.aggregate(profilesToAggregate, 'MEAN')
    frameProfile = Profile.convertCoordinateType(frameProfile, 'IMPLICIT_1D')
    local _, delta = Profile.getImplicitCoordinates(frameProfile)
    Profile.setImplicitCoordinates(frameProfile, origin:getX(), delta)
    
    -- Get max and min value from the mean profile
    local max, indexMax = frameProfile:getMax()
    local min, indexMin = frameProfile:getMin()

    -- Get the coordinates for max and min
    local coord = frameProfile:getCoordinate(indexMax)
    local coord2 = frameProfile:getCoordinate(indexMin)

    -- Remove noise from profile
    frameProfile = frameProfile:median(3)
    
    -- Create points and lines for max, min, distance and height
    local maxPoint = Point.create(coord, max)
    local minPoint = Point.create(coord2, min)
    local heightPoint = Point.create(coord, min)
    local distLine = Shape.createLineSegment(maxPoint, minPoint)
    local distance = maxPoint:getDistance(minPoint)
    local heightLine = Shape.createLineSegment(maxPoint, heightPoint)
    local height = maxPoint:getDistance(heightPoint)

    -- Create a box to move along the object
    local scannedFrame = scanBox:translate(0, i * pixelSizeY)

    -- Clear viewer
    v2D:clear()
    v2D2:clear()

    -- Add heightmap and scan box
    local id = View.ImageDecoration.create()
    id:setRange(minZ, maxZ)
    v2D:addHeightmap(heightMap[1], id)
    v2D:addShape(scannedFrame, helper.getDeco(BLACK, 0.5, nil, 1.0))
    v2D:present()

    -- Add the profile to the viewer
    v2D2:addProfile(frameProfile)
    v2D2:present()
    Script.sleep(DELAY)

    -- Add the max/min points and text to the viewer
    v2D2:addShape(maxPoint, helper.getDeco(ORANGE, nil, 2))
    v2D2:addShape(minPoint, helper.getDeco(ORANGE, nil, 2))
    v2D2:addText('Max: x= ' .. helper.round(coord) .. ' y= ' ..
                helper.round(max), helper.getTextDeco(ORANGE, 3, coord+3, max))
    v2D2:addText('Min: x= ' .. helper.round(coord2) .. ' y= ' ..
                helper.round(min), helper.getTextDeco(ORANGE, 3, coord2+3, min))
    v2D2:present()
    Script.sleep(DELAY)

    -- Add distance line and text to the viewer
    v2D2:addShape(distLine, helper.getDeco(RED, 0.1))
    v2D2:addText('Dist: ' .. helper.round(distance) .. ' mm',
                helper.getTextDeco(RED, 3, (coord+coord2)/2+13, (min+max)/2))
    v2D2:present()
    Script.sleep(DELAY)

    -- Add height point, line and text to the viewer
    v2D2:addShape(heightPoint, helper.getDeco(ORANGE, nil, 2))
    v2D2:addShape(heightLine, helper.getDeco(GREEN, 0.5))
    v2D2:addText('Height diff: \n' .. helper.round(height) .. ' mm',
                helper.getTextDeco(GREEN, 3, coord+3, (min+max)/2-2))
    v2D2:present()
    Script.sleep(DELAY)
  end
  print('App finished.')
end
--The following registration is part of the global scope which runs once after startup
--Registration of the 'main' function to the 'Engine.OnStarted' event
Script.register('Engine.OnStarted', main)
-- serve API in global scope
