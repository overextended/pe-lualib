---@diagnostic disable: param-type-mismatch
lib.marker = {}

local defaultRotation = vector3(0, 0, 0)
local defaultDirection = vector3(0, 0, 0)
local defaultColor = { r = 255, g = 255, b = 255, a = 100 }
local defaultSize = { width = 2, height = 1 }
local defaultBobUpAndDown = false
local defaultFaceCamera = true
local defaultRotate = false
local defaultTextureDict = nil
local defaultTextureName = nil

local markerTypesMap = {
  UpsideDownCone = 0,
  VerticalCylinder = 1,
  ThickChevronUp = 2,
  ThinChevronUp = 3,
  CheckeredFlagRect = 4,
  CheckeredFlagCircle = 5,
  VerticleCircle = 6,
  PlaneModel = 7,
  LostMCTransparent = 8,
  LostMC = 9,
  Number0 = 10,
  Number1 = 11,
  Number2 = 12,
  Number3 = 13,
  Number4 = 14,
  Number5 = 15,
  Number6 = 16,
  Number7 = 17,
  Number8 = 18,
  Number9 = 19,
  ChevronUpx1 = 20,
  ChevronUpx2 = 21,
  ChevronUpx3 = 22,
  HorizontalCircleFat = 23,
  ReplayIcon = 24,
  HorizontalCircleSkinny = 25,
  HorizontalCircleSkinny_Arrow = 26,
  HorizontalSplitArrowCircle = 27,
  DebugSphere = 28,
  DollarSign = 29,
  HorizontalBars = 30,
  WolfHead = 31,
  QuestionMark = 32,
  PlaneSymbol = 33,
  HelicopterSymbol = 34,
  BoatSymbol = 35,
  CarSymbol = 36,
  MotorcycleSymbol = 37,
  BikeSymbol = 38,
  TruckSymbol = 39,
  ParachuteSymbol = 40,
  Unknown41 = 41,
  SawbladeSymbol = 42,
  Unknown43 = 43,
}

---@alias MarkerType
---| "UpsideDownCone"
---| "VerticalCylinder"
---| "ThickChevronUp"
---| "ThinChevronUp"
---| "CheckeredFlagRect"
---| "CheckeredFlagCircle"
---| "VerticleCircle"
---| "PlaneModel"
---| "LostMCTransparent"
---| "LostMC"
---| "Number0"
---| "Number1"
---| "Number2"
---| "Number3"
---| "Number4"
---| "Number5"
---| "Number6"
---| "Number7"
---| "Number8"
---| "Number9"
---| "ChevronUpx1"
---| "ChevronUpx2"
---| "ChevronUpx3"
---| "HorizontalCircleFat"
---| "ReplayIcon"
---| "HorizontalCircleSkinny"
---| "HorizontalCircleSkinny_Arrow"
---| "HorizontalSplitArrowCircle"
---| "DebugSphere"
---| "DollarSign"
---| "HorizontalBars"
---| "WolfHead"
---| "QuestionMark"
---| "PlaneSymbol"
---| "HelicopterSymbol"
---| "BoatSymbol"
---| "CarSymbol"
---| "MotorcycleSymbol"
---| "BikeSymbol"
---| "TruckSymbol"
---| "ParachuteSymbol"
---| "Unknown41"
---| "SawbladeSymbol"
---| "Unknown43"

---@class MarkerProps
---@field type MarkerType | number
---@field coords { x: number, y: number, z: number }
---@field width? number
---@field height? number
---@field color? { r: number, g: number, b: number, a: number }
---@field rotation? { x: number, y: number, z: number }
---@field direction? { x: number, y: number, z: number }
---@field bobUpAndDown? boolean
---@field faceCamera? boolean
---@field rotate? boolean
---@field textureDict? string
---@field textureName? string

---@param self MarkerProps
local function drawMarker(self)
  DrawMarker(
    self.type,
    self.coords.x, self.coords.y, self.coords.z,
    self.direction.x, self.direction.y, self.direction.z,
    self.rotation.x, self.rotation.y, self.rotation.z,
    self.width, self.width, self.height,
    self.color.r, self.color.g, self.color.b, self.color.a,
    self.bobUpAndDown, self.faceCamera, 2, self.rotate, self.textureDict, self.textureName, false)
end

---@param options MarkerProps
function lib.marker.new(options)
  local markerType
  if type(options.type) == "string" then
    markerType = markerTypesMap[options.type]
    if markerType == nil then
      error(("unknown marker type '%s'"):format(options.type))
    end
  elseif type(options.type) == "number" then
    markerType = options.type
  else
    error(("expected marker type to have type 'string' or 'number' (received %s)"):format(type(options.type)))
  end

  if type(options.bobUpAndDown) ~= "boolean" then
    options.bobUpAndDown = defaultBobUpAndDown
  end

  if type(options.faceCamera) ~= "boolean" then
    options.faceCamera = defaultFaceCamera
  end

  if type(options.rotate) ~= "boolean" then
    options.rotate = defaultRotate
  end

  local self = {}
  self.type = markerType
  self.coords = options.coords
  self.color = options.color or defaultColor
  self.width = options.width or defaultSize.width
  self.height = options.height or defaultSize.height
  self.rotation = options.rotation or defaultRotation
  self.direction = options.direction or defaultDirection
  self.bobUpAndDown = options.bobUpAndDown
  self.faceCamera = options.faceCamera
  self.rotate = options.rotate
  self.textureDict = options.textureDict or defaultTextureDict
  self.textureName = options.textureName or defaultTextureName
  self.draw = drawMarker

  self.width += 0.0
  self.height += 0.0

  return self
end

return lib.marker
