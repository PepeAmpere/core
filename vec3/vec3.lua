local moduleInfo = {
	name = "vec3",
	desc = "Vector object and its methods.",
	author = "PepeAmpere", -- inspired by work Gordon MacPherson and Michal Mojzik, wrote from scratch
	date = "2017-09-08",
	license = "MIT",
}

local sin = math.sin
local cos = math.cos
local deg = math.deg
local rad = math.rad
local atan2 = math.atan2
local type = type

-- defining the metatable and access 
local vector = {}
local vectorMeta = {}
vectorMeta.__index = vector
vectorMeta.__metatable = false -- access

local function new(x, y, z)
	return setmetatable(
		{
			x = x or 0,
			y = y or 0, 
			z = z or 0
		},
		vectorMeta
	) 
end

local function is3DVector(vectorOne)
	return type(vectorOne) == "table" and type(vectorOne.x) == "number" and type(vectorOne.y) == "number" and type(vectorOne.z) == "number"
end

local Vec3 = new

-- OPERATORS AND BASIC METHODS --

function vectorMeta:__add(vectorOne)
	return new( 
		self.x + vectorOne.x,
		self.y + vectorOne.y,
		self.z + vectorOne.z 
	)
end

function vectorMeta:__sub(vectorOne)
	return new(
		self.x - vectorOne.x,
		self.y - vectorOne.y,
		self.z - vectorOne.z 
	)
end

function vectorMeta:__mul(vectorOne)
	if (type(vectorOne) == "number") then
		return new(
			self.x * vectorOne,
			self.y * vectorOne,
			self.z * vectorOne
		)
	else
		return new(
			self.x * vectorOne.x,
			self.y * vectorOne.y,
			self.z * vectorOne.z 
		)
	end
end

function vectorMeta:__div(vectorOne)
	if (type(vectorOne) == "number") then
		return new(
			self.x / vectorOne,
			self.y / vectorOne,
			self.z / vectorOne
		)
	else
		return new(
			self.x / vectorOne.x,
			self.y / vectorOne.y,
			self.z / vectorOne.z 
		)
	end
end

function vectorMeta:__eq(vectorOne)
	return self.x == vectorOne.x and self.y == vectorOne.y and self.z == vectorOne.z
end

function vectorMeta:__unm()
	return new(
		-self.x,
		-self.y,
		-self.z
	)
end      

function vector:Add(vectorOne)
	self = self + vectorOne
	return self -- copy
end

function vector:Sub(vectorOne)
	self = self - vectorOne
	return self -- copy
end

function vector:Mul(multiplier)
	self.x = self.x * multiplier
	self.y = self.y * multiplier
	self.z = self.z * multiplier
	return self -- copy(?)
end

function vectorMeta:__tostring()
	return "Vec3(" .. self.x .. "," .. self.y .. "," .. self.z .. ")"
end

function vectorMeta:__concat()
	return "Vec3(" .. self.x .. "," .. self.y .. "," .. self.z .. ")"
end

function vector:Length()
	return self:LengthSQ()^0.5
end

function vector:LengthSQ()
	return ((self.x * self.x) + (self.y * self.y) + (self.z * self.z))
end

function vector:Distance(vectorOne)
	return (self - vectorOne):Length()
end

function vector:DistanceSQ(vectorOne)
	return (self - vectorOne):LengthSQ()
end

function vector:Zero()
	self.x = 0
	self.y = 0
	self.z = 0
	return self -- in place?, otherwise use 'new'
end

function vector:Copy()
	return new(
		self.x,
		self.y,
		self.z
	)
end

function vector:GetNormal()
	local length = self:Length()
	return new(
		self.x / length,
		self.y / length,
		self.z / length
	) -- copy
end

function vector:Normalize()
	local length = self:Length()
	return self:Mul(1 / length) -- in place
end

function vector:DotProduct(angleOne)
	return (self.x * vectorOne.x) + (self.y * vectorOne.y) + (self.z * vectorOne.z)
end

function vector:Cross(vectorOne)
	return new(
		(self.y * vectorOne.z) - (vectorOne.y * self.z),
		(self.z * vectorOne.x) - (vectorOne.z * self.x),
		(self.x * vectorOne.y) - (vectorOne.x * self.y)
	)
end

function vector:Lerp(vectorOne, alpha)
	return self + ((vectorOne - self) * alpha)
end

-- MATRIXES

function vector:CreateEmitMatrix()
	local x = self.x
	local y = self.y
	local z = self.z
	local xz = x*z
	local xy = x*y
	local yz = y*z

	return {
		x*x, xy-z, xz+y,
		xy+z, y*y, yz-x,
		xz-y, yz+x, z*z
	}
end

function vector:MultMatrix(matrix)
	local x = self.x
	local y = self.y
	local z = self.z
	
	return new(
		matrix[1]*x + matrix[2]*y + matrix[3]*z,
		matrix[4]*x + matrix[5]*y + matrix[6]*z,
		matrix[7]*x + matrix[8]*y + matrix[9]*z
	)
end

-- SPRING SPECIFIC -- 

--- Convert vector in 2D heading in degrees between 0-360
function vector:ToHeading() -- azimuth
	local angleInRads = atan2(self.x, self.z)
	-- angleInRads
	-- N (north) = PI
	-- E (east)  = 0.5PI
	-- S (south) = 0
	-- W (west)  = 1.5PI
	return ((deg(-angleInRads) + 180) % 360) -- correction to azimuth values = so 0 degrees is on north and positive increment is clockwise
	-- returned angle
	-- N (north) = 0
	-- E (east)  = 90
	-- S (south) = 180
	-- W (west)  = 270
end

-- Rotates vector around Y axis by given angle in degrees in-place.
-- A mathematically correct variant = negative angle values implies clockwise rotation.
function vector:Rotate2D(angleOne)
	local angleInRads = rad(-angleOne) -- inverted Z axis (it increases in "south" direction in Spring map notation
	return new(
		self.x * cos(angleInRads) - self.z * sin(angleInRads),
		self.y,
		self.x * sin(angleInRads) + self.z * cos(angleInRads)
	) -- copy
end

--- Rotates vector around Y axis by given azimuth
function vector:RotateByHeading(angleOne)
	return self:Rotate2D(-angleOne) -- just rotation in opoosite direction than mathematic Rotate2D
end

function vector:ToMap()
	self.x = math.max(math.min(Game.mapSizeX-1, self.x), 0)
	self.z = math.max(math.min(Game.mapSizeZ-1, self.z), 0)
	return self
end

-- Convert to array with three items, no string keys, as Spring API likes it
function vector:AsSpringVector()
	return {
		self.x, 
		self.y, 
		self.z
	}
end

function vector:GetCoordinates()
	return self.x, self.y, self.z
end

return Vec3
