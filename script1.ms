"Start"

outputSize = point2 640 480	-- can change during runtime

-- Create output dir
stamp =  timeStamp()
outputDir = maxFilePath + "output\\" + stamp as string
makeDir outputDir

-- RNG seed
--startSeed = 123456
--startSeed = 3123456
--startSeed = 5161
--startSeed = 2113
startSeed = 3673
--startSeed = 4221
seed startSeed

-- Create log file
logPath = outputDir + "\\log.txt"
logStream = openFile logPath mode:"w"

tableHeight = 60 -- must match true table height

rendererName = "scanline"

if rendererName == "scanline" then
	matLibPath = maxFilePath + "mylib_scanline.mat"
else if rendererName == "art" then
	matLibPath = maxFilePath + "mylib.mat"
else
	throw "Unrecognized renderer"

artRenderer = RendererClass.classes[5]()
artRenderer.quality_db = 27
scanlineRenderer = RendererClass.classes[1]()

-- Load logo images
print "Loading logo images"
logoDir = ""
logoPaths = #()
logoInds = #() -- Arrays within this array indicate groups, needed for v2
logoIndexing = "v1"

-- V1: Simple pngs in folder
if logoIndexing == "v1" do
(
	logoDir = maxFilePath + "flickr32\\*"
	--logoDir = maxFilePath + "dettol_pringles\\*"
	logoPaths = getFiles logoDir
	for i = 1 to logoPaths.count do append logoInds i
)

-- V2: Similar images grouped in folders, mix of json and png
if logoIndexing == "v2" do
(
	--dirname = "drinks_v0"
	dirname = "robo_v0"
	logoDir = maxFilePath + dirname + "\\*"
	dirs = getDirectories logoDir
	for d in dirs do
	(
		append logoInds #()
		files = getFiles (d + "*.png")
		for f in files do
		(
			append logoPaths f
			append logoInds[logoInds.count] logoPaths.count
		)
	)
	logoDirPng = maxFilePath + dirname + "\\*.png"
	files = getFiles logoDirPng
	for f in files do
	(
		append logoPaths f
		append logoInds logoPaths.count
	)
)

-- Read pngs
logoPngs = #()
for i in logoPaths do
(
	print i
	bmt = bitmapTexture filename:i
	bmt.monoOutput = 1 -- output alpha for opacity maps
	bmt.coords.realWorldScale = true
	bmt.coords.U_Tile = false
	bmt.coords.V_Tile = false
	append logoPngs bmt
) 

-- Load line images
print "Loading line images"
linesDir = maxFilePath + "lines\\output0\\*"
linesPaths = getFiles linesDir
linesImgs0 = #()
for i in linesPaths do
(
	bmt = bitmapTexture filename:i
	bmt.coords.realWorldScale = true
	bmt.coords.realWorldHeight = 20
	ratio = bmt.bitmap.width as float / bmt.bitmap.height
	bmt.coords.realWorldWidth = ratio * bmt.coords.realWorldHeight
	append linesImgs0 bmt
)
linesDir = maxFilePath + "lines\\output1\\*"
linesPaths = getFiles linesDir
linesImgs1 = #()
for i in linesPaths do
(
	bmt = bitmapTexture filename:i
	bmt.coords.realWorldScale = true
	bmt.coords.realWorldHeight = 20
	ratio = bmt.bitmap.width as float / bmt.bitmap.height
	bmt.coords.realWorldWidth = ratio * bmt.coords.realWorldHeight
	append linesImgs1 bmt
)

-- Load bump texture images
print "Loading bump images"
bumpDir = maxFilePath + "bump\\*"
bumpPaths = getFiles bumpDir
bumpImgs = #()
for i in bumpPaths do
(
	bmt = bitmapTexture filename:i
	bmt.coords.realWorldScale = true
	bmt.coords.realWorldHeight = 20
	ratio = bmt.bitmap.width as float / bmt.bitmap.height
	bmt.coords.realWorldWidth = ratio * bmt.coords.realWorldHeight
	bmt.coords.blur = 0.5
	append bumpImgs bmt
)

-- The texture/material for the logo object
logoObjs = #($Logo, $Logo2, $Logo3)
bmtCache = #()
maxLogos = 3
for i = 1 to maxLogos do
(
	append bmtCache 0
)

-- Prepare render effects
blurEffect = blur()
colorEffect = colorBalance()
grainEffect = filmGrain()

function deleteEffects =
(
	for i = 1 to numEffects do
		deleteEffect 1
)

function randEffects =
(
	useBlur = random 0 100 < 20
	useColor = random 0 100 < 30
	useGrain = random 0 100 < 15
	format "useBlur % useColor % useGrain %\n" useBlur useColor useGrain to:logStream
	if useBlur then
	(
		blurEffect.blur_type = random 1 2 --random 0 2
		if blurEffect.blur_type == 0 then -- Uniform
		(
			blurEffect.bUnifPixRad = 1
			format "bUnifPixRad %\n" blurEffect.bUnifPixRad to:logStream
		)
		else if blurEffect.blur_type == 1 then -- Directional
		(
			blurEffect.bDirUPixRad = 1
			blurEffect.bDirVPixRad = 0
			blurEffect.bDirRotation = random 0 89
			blurEffect.bDirUTrail = random 0 20
			format "bDirUPixRad % bDirVPixRad %\n" blurEffect.bDirUPixRad blurEffect.bDirVPixRad to:logStream
			format "bDirRotation % bDirUTrail %\n" blurEffect.bDirRotation blurEffect.bDirUTrail to:logStream
		)
		else if blurEffect.blur_type == 2 then -- Radial
		(
			blurEffect.bRadialPixRad = 1
			blurEffect.bRadialXOrig = random 0 500
			blurEffect.bRadialYOrig = random 0 500
			format "bRadialPixRad % bRadialXOrig % bRadialYOrig %\n" blurEffect.bRadialPixRad blurEffect.bRadialXOrig blurEffect.bRadialYOrig to:logStream
		)
	)
	if useColor then
	(
		colorEffect.red = random -10 20
		colorEffect.green = random -10 20
		colorEffect.blue = random -10 20
		format "red % green % blue %\n" colorEffect.red colorEffect.green colorEffect.blue to:logStream
	)
	if useGrain then
	(
		grainEffect.Grain = random 0.1 0.5
		format "Grain %\n" grainEffect.Grain to:logStream
	)
	if useColor then
		addEffect colorEffect
	if useBlur and useGrain then
	(
		if random 0 1 == 0 then
		(
			addEffect blurEffect
			addEffect grainEffect
		)
		else
		(
			addEffect grainEffect
			addEffect blurEffect
		)
	)
	else if useBlur then
		addEffect blurEffect
	else if useGrain then
		addEffect grainEffect
)

function randCam numLogos =
(
	pos = point3 0 0 0
	distBetweenLogos = 0
	for i = 1 to numLogos do
	(
		pos += logoObjs[i].pos
		for j = 1 to numLogos do
		(
			d = distance logoObjs[i].pos logoObjs[j].pos
			d = abs d
			if d > distBetweenLogos then distBetweenLogos = d
		)
	)
	if numLogos > 0 then pos /= numLogos
	
	x = pos[1] + (random 12 25)
	y = pos[2]
	z = pos[3] + (random 10 30)
	dist = random 50 70
	dist += distBetweenLogos * 0.8
	theta = random -25 25
	x = x + dist * cos(theta)
	y = y + dist * sin(theta)
	$PhysCamera001.pos = [x, y, z]
	
	x = pos[1] + (random -5 5)
	y = pos[2] + (random -5 5)
	z = pos[3] + (random -3 3)
	$PhysCamera001.Target.pos = [x, y, z]
	format "Cam pos % target %\n" $PhysCamera001.pos $PhysCamera001.Target.pos to:logStream
)

function randLights =
(
	all = #($PhotometricLight001, $PhotometricLight002)
	for i in all do
	(
		x = random -200 200
		y = random -200 200
		z = random 180 220
		i.pos = [x, y, z]
		i.intensity = random 400 800
		i.kelvin = random 3000 10000
		format "Light %: pos % intensity % kelvin %\n" i i.pos i.intensity i.kelvin to:logStream
	)
	-- Hardcode one light to be in front
	all[1].pos[1] = random 0 200
	
	all[2].enabled = random 0 3 > 0
	format "Light 2 enabled %\n" all[2].enabled to:logStream
)

function randBackground = 
(
	$Table.mat = currentMaterialLibrary[random 1 currentMaterialLibrary.count]
	mat2 = currentMaterialLibrary[random 1 currentMaterialLibrary.count]
	$Wall1.mat = mat2
	$Wall2.mat = mat2
	$Wall3.mat = mat2
	$Wall4.mat = mat2
	format "Table mat: %. Wall mat: %\n" $Table.mat mat2 to:logStream
)

function getRandColor = 
(
	r = random 30 255
	g = random 30 255
	b = random 30 255
	color r g b
)

function createMaterial logoBitmap matIndex =
(
	comp = compositeTexture()

	-- Background texture/color
	if matIndex == undefined then
		matIndex = random 1 currentMaterialLibrary.count
	randTexture = currentMaterialLibrary[matIndex]

	if hasProperty randTexture "Generic_Image" and randTexture.Generic_Image != undefined then
	(
		comp.mapList[1] = randTexture.Generic_Image
		format "Logo background texture % %\n" matIndex randTexture to:logStream
	)
	else
	(
		-- Random background color
		color1 = getRandColor()
		comp.mapList[1] = colorMap solidcolor:color1
		format "Logo background color %\n" color1 to:logStream
	)
	
	-- Lines underlay
	if random 0 100 < 5 then
	(
		comp.add()
		comp.mapList[2] = linesImgs0[random 1 linesImgs0.count]
	)
	
	-- Insert logo if needed
	if logoBitmap != undefined then
	(
		comp.add()
		comp.mapList[comp.mapList.count] = logoBitmap
	)

	-- Lines overlay
	if random 0 100 < 5 then
	(
		comp.add()
		comp.mapList[comp.mapList.count] = linesImgs1[random 1 linesImgs1.count]
	)	

	logoMat = physicalMaterial()
	logoMat.base_color_map = comp

	-- Random bump map
	if random 0 100 < 10 then
	(
		logoMat.bump_map_amt = random 0.5 1.0
		logoMat.bump_map = bumpImgs[random 1 bumpImgs.count]
		format "Bump map % amount %\n" logoMat.bump_map.fileName logoMat.bump_map_amt to:logStream
	)
	else logoMat.bump_map = undefined
	
	-- Randomize other material properties
	if random 0 2 == 0 then logoMat.metalness = random 0.1 1.0
	else logoMat.metalness = 0.0
	logoMat.roughness = random 0.0 1.0
	format "Metalness % roughness %\n" logoMat.metalness logoMat.roughness to:logStream
	logoMat
)

function randLogo objIndex logoIndex matIndex seeder numLogos =
(
	seed (startSeed + seeder * 41769)
	-- Choose a random logo bitmap texture and get its aspect ratio
	--logoIndex = random 1 logoPngs.count
	bmtCache[objIndex] = copy logoPngs[logoIndex]
	bmt = bmtCache[objIndex]
	ratio = bmt.bitmap.width as float / bmt.bitmap.height
	format "Logo path %\n" bmt.fileName to:logStream

	-- Logo image size limits
	minHeight = 9.0
	maxHeight = maxHeight2 = maxU = minU = maxV = minV = minC = maxC = -1

	-- Choose shape
	shapeTypes = #("plane", "box", "cylinder")
	shapeType = shapeTypes[random 1 shapeTypes.count]
	format "shapeType %\n" shapeType to:logStream
	
	logoObj = logoObjs[objIndex]
	logoObj.visibility = true
	logoObj.pos.x = 0
	logoObj.pos.y = 0
	logoObj.scale = point3 1 1 1
	logoObj.rotation.x_rotation = 0
	logoObj.rotation.y_rotation = 0
	logoObj.rotation.z_rotation = 90
	if objIndex == 2 then
	(
		logoObj.pos.x = random 0 10
		logoObj.pos.y = random 20 30
	)
	else if objIndex == 3 then
	(
		logoObj.pos.x = random 0 10
		logoObj.pos.y = random -30 -20
	)
	format "logo pos %\n" logoObj.pos to:logStream

	if shapeType == "plane" then
	(
		logoObj.baseObject = copy $Plane001.baseObject
		logoObj.rotation.x_rotation = 90 -- rotate to align material
		logoObj.width = random 18 25.0 -- x to the right of camera
		logoObj.length = random 15 25.0 -- y upwards
		
		logoObj.modifiers[1].mapType = 0 -- Planar uvw map
		logoObj.modifiers[1].u_tile = 1
		
		logoObj.pos.z = tableHeight + logoObj.length/2
		maxHeight = logoObj.length - 0.2
		maxHeight2 =  (logoObj.width / ratio) - 0.2
		format "Width % length %\n" logoObj.width logoObj.length to:logStream
	)
	else if shapeType == "box" then
	(
		logoObj.baseObject = copy $Box001.baseObject
		logoObj.rotation.x_rotation = 90 -- rotate to align material
		logoObj.width = random 18 25.0 -- x to the right of camera
		logoObj.length = random 15 25.0 -- y upwards
		logoObj.height = random 2 20.0 -- z towards camera
		
		logoObj.modifiers[1].mapType = 0 -- Planar uvw map
		logoObj.modifiers[1].u_tile = 1
		
		logoObj.pos.z = tableHeight + logoObj.length/2
		maxHeight = logoObj.length - 0.2
		maxHeight2 =  (logoObj.width / ratio) - 0.2
		format "Width % length % height %\n" logoObj.width logoObj.length logoObj.height to:logStream
	)
	else if shapeType == "cylinder" then
	(
		logoObj.baseObject = copy $Cylinder001.baseObject
		logoObj.rotation.x_rotation = 0
		logoObj.radius = random 10 17
		logoObj.height = random 15 27
		logoObj.pos.z = tableHeight
		
		circumference = 2 * pi * logoObj.radius
		logoObj.modifiers[1].mapType = 1 -- Cylindrical uvw map
		logoObj.modifiers[1].cap = true
		logoObj.modifiers[1].u_tile = circumference
		
		maxHeight = logoObj.height - 0.2
		
		-- Position logo randomly between 40% and 60% of circumference
		maxC = 0.6 * circumference
		minC = 0.4 * circumference
		maxHeight2 =  (maxC - minC) / ratio
		format "Radius % height %\n" logoObj.radius logoObj.height to:logStream
	)
	else if shapeType == "bottle" then
	(
		logoObj.baseObject = copy $Bottle001.baseObject
		logoObj.rotation.x_rotation = 0
		logoObj.pos.z = tableHeight
		
		radius = 3.5
		
		circumference = 2 * pi * radius
		logoObj.modifiers[1].mapType = 1 -- Cylindrical uvw map
		logoObj.modifiers[1].cap = true
		logoObj.modifiers[1].u_tile = circumference
		
		maxHeight = 20
		
		-- Position logo randomly between 35% and 65% of circumference
		maxC = 0.65 * circumference
		minC = 0.35 * circumference
		maxHeight2 =  (maxC - minC) / ratio
		
		logoObj.scale = point3 2 2 2
	)
	
	-- Set UV map gizmo to origin
	logoObj.modifiers[1].gizmo.pos = point3 0 0 0
	logoObj.modifiers[1].gizmo.rotation = quat 0 0 -1 0

	-- Randomize rotation using world frame
	-- Do not randomize too much if there are other logos, can cause occlusion
	if (random 0 100) < 70 then
	(
		if numLogos == 1 then
			rotate logoObj (eulerangles (random -90 90) (random -10 10) (random -10 10))
		else
			rotate logoObj (eulerangles (random -10 10) (random -10 10) (random -10 10))
	)
	
	-- Ensure object is still above table after rotation
	move logoObj [0, 0, tableHeight - logoObj.min.z]
	format "Rotation x % y % z %\n" logoObj.rotation.x_rotation logoObj.rotation.y_rotation logoObj.rotation.z_rotation to:logStream

	-- Randomize logo size	
	if maxHeight2 < maxHeight then maxHeight = maxHeight2
	if maxHeight > minHeight then 
		bmt.coords.realWorldHeight = random minHeight maxHeight
	else
		bmt.coords.realWorldHeight = maxHeight
	bmt.coords.realWorldWidth = ratio * bmt.coords.realWorldHeight
	format "Logo bitmap height % width %\n" bmt.coords.realWorldHeight bmt.coords.realWorldWidth to:logStream

	-- Calculate bounds then randomize logo position
	if shapeType == "box" or shapeType == "plane" then
	(
		maxU = logoObj.width/2 - bmt.coords.realWorldWidth - 0.2
		minU = -logoObj.width/2 + 0.2
		maxV = logoObj.length/2 - bmt.coords.realWorldHeight - 0.2
		minV = -logoObj.length/2 + 0.2
	)
	else if shapeType == "cylinder" then
	(
		maxU = maxC - bmt.coords.realWorldWidth
		minU = minC
		maxV = logoObj.height - bmt.coords.realWorldHeight - 0.2
		minV = 0
	)
	else if shapeType == "bottle" then
	(
		maxU = maxC - bmt.coords.realWorldWidth
		minU = minC
		maxV = 15 - bmt.coords.realWorldHeight
		minV = 3
	)
	bmt.coords.U_offset = random minU maxU
	bmt.coords.V_offset = random minV maxV
	format "Logo bitmap U_offset % V_offset %\n" bmt.coords.U_offset bmt.coords.V_offset to:logStream

	-- Put material together
	-- If plane, then chance for transparent background
	seed (startSeed + seeder * 206731)
	rand = random 0 2
	if shapeType == "plane" and rand == 0 then
	(
		logoStandardMat = standardMaterial()
		logoStandardMat.diffuseMap = bmt
		logoStandardMat.opacityMap = bmt
		logoObj.material = logoStandardMat
		format "Transparent plane\n" to:logStream
	)
	else
	(
		logoObj.material = createMaterial bmt matIndex
	)
	
	-- Return coordinates of logo corners and logo index
	z = 0
	if shapeType == "box" then z = logoObj.height
	p1 = point3 bmt.coords.U_offset bmt.coords.V_offset z
	p2 = point3 (bmt.coords.U_offset + bmt.coords.realWorldWidth) bmt.coords.V_offset z
	p3 = point3 bmt.coords.U_offset (bmt.coords.V_offset + bmt.coords.realWorldHeight) z
	p4 = point3 (bmt.coords.U_offset + bmt.coords.realWorldWidth) (bmt.coords.V_offset + bmt.coords.realWorldHeight) z
	p1 = p1 *  logoObj.transform
	p2 = p2 * logoObj.transform
	p3 = p3 * logoObj.transform
	p4 = p4 * logoObj.transform
	#(p1, p2, p3, p4, logoIndex)
)

function removeObj obj =
(
	obj.pos = point3 -500 -500 0
	obj.visibility = false
)

function distPointLine x0 y0 x1 y1 x2 y2 =
(
	-- Return distance from point 0 to line between points 1 and 2
	num = (y2 - y1) * x0 - (x2 - x1) * y0 + x2 * y1 - y2 * x1
	den = sqrt((pow (y2 - y1) 2) + (pow (x2 - x1) 2))
	abs(num) / den
)

function randDistractor obj numLogos = 
(
	obj.visibility = true
	shapeTypes = #("box", "cone", "cylinder", "pyramid", "sphere", "teapot", "tube")

	-- Choose shape
	shapeType = shapeTypes[random 1 shapeTypes.count]
	
	z = tableHeight
	if shapeType == "box" then
	(
		obj.baseObject = copy $Box001.baseObject
		obj.width = random 4.0 20.0
		obj.length = random 4.0 20.0
		obj.height = random 4.0 20.0
	)
	if shapeType == "cone" then
	(
		obj.baseObject = copy $Cone001.baseObject
		obj.radius1 = random 2.0 10.0
		obj.radius2 = random 2.0 10.0
		obj.height = random 4.0 30.0
	)
	if shapeType == "cylinder" then
	(
		obj.baseObject = copy $Cylinder001.baseObject
		obj.radius = random 2.0 10.0
		obj.height = random 4.0 30.0
	)
	--if shapeType == "plane" then
	--(
	--	obj.baseObject = copy $Plane001.baseObject
	--	obj.length = random 4.0 25.0
	--	obj.width = random 4.0 25.0
	--	z = obj.length / 2
	--)
	if shapeType == "pyramid" then
	(
		obj.baseObject = copy $Pyramid001.baseObject
		obj.width = random 4.0 40.0
		obj.depth = random 4.0 40.0
		obj.height = random 4.0 40.0
	)
	if shapeType == "sphere" then
	(
		obj.baseObject = copy $Sphere001.baseObject
		obj.radius = random 4.0 20.0
		z = obj.radius / 2
	)
	if shapeType == "teapot" then
	(
		obj.baseObject = copy $Teapot001.baseObject
		obj.radius = random 10.0 20.0
	)
	if shapeType == "tube" then
	(
		obj.baseObject = copy $Tube001.baseObject
		obj.radius1 = random 2.0 10.0
		obj.radius2 = random 2.0 10.0
		obj.height = random 4.0 30.0
	)

	-- Random material
	obj.mat = createMaterial undefined undefined
	
	-- Random position on table. Ensure not between camera and logo
	x = 0
	y = 0
	loop = true
	while loop do
	(
		x = random -50 30
		y = random -40 40
		isOk = true
		if x > -30 then
		(
			for i = 1 to numLogos do
			(
				logoObj = logoObjs[i]
				d = distPointLine x y $PhysCamera001.pos[1] $PhysCamera001.pos[2] logoObj.pos[1] logoObj.pos[2]
				if d < 25 then isOk = false
			)
		)
		if isOk then loop = false
	)
	obj.pos = point3 x y z
	
	-- Random rotation
	obj.rotation.x_rotation = random -10 10
	obj.rotation.y_rotation = random -10 10
	obj.rotation.z_rotation = random -10 10
	format "randDistractor pos % shape % mat % rot \n" obj.pos shapeType obj.mat obj.rotation to:logStream
)

function randDistractors numLogos =
(
	numObjs = 0
	rand = random 0 100
	if rand < 40 then numObjs = 1
	else if rand < 70 then numObjs = 2
	
	format "Number of distractor objects: %\n" numObjs to:logStream
	if numObjs > 0 then randDistractor $Obj001 numLogos
	else removeObj $Obj001
	if numObjs > 1 then randDistractor $Obj002 numLogos
	else removeObj $Obj002
)

function mapWorldToScreen thePoint camTf =
(
	local thePos = thePoint * camTf -- viewport.getTM()
	local screenSize = outputSize
	local screen_origin = mapScreenToView [0,0] (thePos.z) screenSize
	local end_screen = mapScreenToView screenSize (thePos.z) screenSize
	local world_size = screen_origin-end_screen
	local x_aspect = screenSize.x/(abs world_size.x)
	local y_aspect = screenSize.y/(abs world_size.y)
	point3 (x_aspect*(thePos.x-screen_origin.x)) (-(y_aspect*(thePos.y-screen_origin.y))) 0
)

function saveLogoInfo logoInfos fname =
(
	--m = Inverse($PhysCamera001.transform) -- left handed rotation?
	--f = $PhysCamera001.focal_length_mm
	
	camTf = Inverse($PhysCamera001.transform)
	print fname
	fstream = openFile fname mode:"w"
	for logoInfo in logoInfos do
	(
		corners = #(logoInfo[1], logoInfo[2], logoInfo[3], logoInfo[4])
		out = #()
		for c in corners do
		(
			p = mapWorldToScreen c camTf
			append out p
		)
		logoPath = logoPaths[logoInfo[5]]
		split = filterString logoPath "\\"
		format "% % % %\n%\n" out[1] out[2] out[3] out[4] split[split.count] to:fstream
	)
	
	close fstream
)

function renderMask i objIndex =
(
	-- Render masks
	-- Enable elements and set output path
	outObjIndex = objIndex - 1
	outputPath = outputDir + "\\" + i as string + "_" + outObjIndex as string + "_scanline.jpg"
	renderers.current = scanlineRenderer
	re = maxOps.GetCurRenderElementMgr()
	elem = re.GetRenderElement 0
	elemPath = outputDir + "\\" + i as string + "_" + outObjIndex as string + "_mask.bmp"
	re.SetRenderElementFilename 0 elemPath
	re.SetElementsActive true
	
	-- Render only logo object
	logoObj = logoObjs[objIndex]
	select logoObj
	
	-- Set to opacityMap, render alpha element
	tempMat = standardMaterial opacityMap:bmtCache[objIndex]
	prevMat = logoObj.material
	logoObj.material = tempMat
	render camera:$PhysCamera001 outputfile:outputPath vfb:off outputSize:outputSize renderElement:true renderType:#selected
	logoObj.material = prevMat
)

function renderRgb i =
(
	outputPath = outputDir + "\\" + i as string + ".jpg"
	format "Renderer name: %\n" rendererName to:logStream
	if rendererName == "art" then renderers.current = artRenderer
	else if rendererName == "scanline" then renderers.current = scanlineRenderer
	else print "ERROR: Invalid rendererName."
	re = maxOps.GetCurRenderElementMgr()
	re.SetElementsActive false
	render camera:$PhysCamera001 outputfile:outputPath vfb:off outputSize:outputSize renderElement:false renderType:#view
)

function main =
(
	
	if getActiveCamera()!=$PhysCamera001 then
	(
		messagebox "Active viewport must use camera"
		return -1
	)
	if artRenderer as string != "ART_Renderer:ART_Renderer" or scanlineRenderer as string != "Default_Scanline_Renderer:Default_Scanline_Renderer" then
	(
		messagebox "Check renderer index"
		return -1
	)

	-- Load material library into currentMaterialLibrary global
	if getMatLibFileName() != matLibPath then
	(
		print "Loading material library"
		loadMaterialLibrary matLibPath
	)

	samplesPerLogo = 50

	inds = #()
	for i = 1 to samplesPerLogo do
	(
		for j = 1 to logoInds.count do
		(
			append inds j
		)
	)
	
	i=0
	while inds.count > 0 do
	(
		seed (startSeed + i * 3421)
		format "\n\nIteration %\n" i to:logStream
		if keyboard.escPressed do exit
		numLogos = random 1 (amin 3 inds.count)
 		format "numLogos: %\n" numLogos to:logStream
		print "randLights"
		seed (startSeed + i * 1243)
		randLights()
		print "randBackground"
		seed (startSeed + i * 472)
		randBackground()
		print "randOutputSize"
		seed (startSeed + i * 691)
		widths = #(500, 650, 800)
		heights = #(400, 500, 600)
		outputSize = point2 widths[random 1 widths.count] heights[random 1 heights.count]
		format "Output size: %\n" outputSize to:logStream
		print "randLogo"
		logoInfos = #()
		for j = 1 to numLogos do
		(
			seeder = i * 211 + j * 317
			seed (startSeed + seeder * 941)
			r = random 1 inds.count
			ind = logoInds[inds[r]]
			if classOf ind == Array do
			(
				ind = ind[random 1 ind.count]
			)
			logoInfo = randLogo j ind undefined seeder numLogos
			deleteItem inds r
			append logoInfos logoInfo
		)
		
		--if i < 990 then
		--(
		--	i += 1
		--	continue
		--)
		
		print "randCam"
		seed (startSeed + i * 31212)
		randCam numLogos
		print "saveLogoInfo"
		outputTxt = outputDir + "\\" + i as string + "_bb.txt"
		saveLogoInfo logoInfos outputTxt
		for j = (numLogos + 1) to maxLogos do
		(
			removeObj logoObjs[j]
		)
		print "randDistractors"
		seed (startSeed + i * 94761)
		randDistractors numLogos
		print "deleteEffects"
		seed (startSeed + i * 231215)
		deleteEffects()
		print "renderCam"
		for j = 1 to numLogos do
		(
			renderMask i j
		)
		print "randEffects"
		seed (startSeed + i * 794631)
		randEffects()
		renderRgb i
		i = i + 1
	)

	close logStream
)

main()
"Done"
