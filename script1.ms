"Start"

outputSize = point2 640 480

stamp =  timeStamp()
seed stamp
outputDir = maxFilePath + "output\\" + stamp as string
makeDir outputDir

-- Create log file
logPath = outputDir + "\\log.txt"
logStream = openFile logPath mode:"w"

tableHeight = 60

matLibPath = maxFilePath + "mylib.mat"

artRenderer = RendererClass.classes[5]()
scanlineRenderer = RendererClass.classes[1]()

-- Load logo images
print "Loading logo images"
logoDir = maxFilePath + "flickr47\\*"
logoPaths = getFiles logoDir
logoPngs = #()
for i in logoPaths do
(
	bmt = bitmapTexture filename:i
	bmt.monoOutput = 1 -- output alpha for opacity maps
	bmt.coords.realWorldScale = true
	bmt.coords.U_Tile = false
	bmt.coords.V_Tile = false
	append logoPngs bmt
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
comp = compositeTexture()
comp.add()
logoStandardMat = standardMaterial()
logoMat = physicalMaterial()
$Logo.material = logoMat

function randCam =
(
	logo = $Logo.pos
	
	x = logo[1] + (random 10 40)
	y = logo[2]
	z = logo[3] + (random 10 40)
	dist = random 50 90
	theta = random -35 35
	x = x + dist * cos(theta)
	y = y + dist * sin(theta)
	$PhysCamera001.pos = [x, y, z]
	
	x = logo[1] + (random -10 10)
	y = logo[2] + (random -10 10)
	z = logo[3] + (random -5 5)
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

function randLogo =
(
	-- Choose a random logo bitmap texture and get its aspect ratio
	logoIndex = random 1 logoPngs.count
	bmt = logoPngs[logoIndex]
	ratio = bmt.bitmap.width as float / bmt.bitmap.height
	format "Logo path %\n" bmt.fileName to:logStream

	-- Logo image size limits
	minHeight = 7.0
	maxHeight = maxHeight2 = maxU = minU = maxV = minV = minC = maxC = -1

	-- Choose shape
	shapeTypes = #("plane", "box", "cylinder")
	shapeType = shapeTypes[random 1 shapeTypes.count]
	format "shapeType %\n" shapeType to:logStream

	if shapeType == "plane" then
	(
		$Logo.baseObject = copy $Plane001.baseObject
		$Logo.rotation.x_rotation = 90 -- rotate to align material
		$Logo.width = random 18 25.0 -- x to the right of camera
		$Logo.length = random 15 25.0 -- y upwards
		
		$Logo.modifiers[1].mapType = 0 -- Planar uvw map
		$Logo.modifiers[1].u_tile = 1
		
		$Logo.pos.z = tableHeight + $Logo.length/2
		maxHeight = $Logo.length - 0.2
		maxHeight2 =  ($Logo.width / ratio) - 0.2
		format "Width % length %\n" $Logo.width $Logo.length to:logStream
	)
	else if shapeType == "box" then
	(
		$Logo.baseObject = copy $Box001.baseObject
		$Logo.rotation.x_rotation = 90 -- rotate to align material
		$Logo.width = random 18 25.0 -- x to the right of camera
		$Logo.length = random 15 25.0 -- y upwards
		$Logo.height = random 2 20.0 -- z towards camera
		
		$Logo.modifiers[1].mapType = 0 -- Planar uvw map
		$Logo.modifiers[1].u_tile = 1
		
		$Logo.pos.z = tableHeight + $Logo.length/2
		maxHeight = $Logo.length - 0.2
		maxHeight2 =  ($Logo.width / ratio) - 0.2
		format "Width % length % height %\n" $Logo.width $Logo.length $Logo.height to:logStream
	)
	else if shapeType == "cylinder" then
	(
		$Logo.baseObject = copy $Cylinder001.baseObject
		$Logo.rotation.x_rotation = 0
		$Logo.radius = random 10 20
		$Logo.height = random 15 25
		$Logo.pos.z = tableHeight
		
		circumference = 2 * pi * $Logo.radius
		$Logo.modifiers[1].mapType = 1 -- Cylindrical uvw map
		$Logo.modifiers[1].cap = true
		$Logo.modifiers[1].u_tile = circumference
		
		maxHeight = $Logo.height - 0.2
		
		-- Position logo randomly between 40% and 60% of circumference
		maxC = 0.6 * circumference
		minC = 0.4 * circumference
		maxHeight2 =  (maxC - minC) / ratio
		format "Radius % height %\n" $Logo.radius $Logo.height to:logStream
	)
	
	-- Set UV map gizmo to origin
	$Logo.modifiers[1].gizmo.pos = point3 0 0 0
	$Logo.modifiers[1].gizmo.rotation = quat 0 0 -1 0

	-- Randomize rotation
	$Logo.rotation.z_rotation = random 80 100
	format "z_rotation %\n" $Logo.rotation.z_rotation to:logStream

	-- Randomize logo size	
	if maxHeight2 < maxHeight then maxHeight = maxHeight2
	if maxHeight > minHeight then 
		bmt.coords.realWorldHeight = random minHeight maxHeight
	else
		bmt.coords.realWorldHeight = maxHeight
	bmt.coords.realWorldWidth = ratio * bmt.coords.realWorldHeight
	format "Logo bitmap height % width %\n" bmt.coords.realWorldHeight bmt.coords.realWorldHeight to:logStream

	-- Calculate bounds then randomize logo position
	if shapeType == "box" or shapeType == "plane" then
	(
		maxU = $Logo.width/2 - bmt.coords.realWorldWidth - 0.2
		minU = -$Logo.width/2 + 0.2
		maxV = $Logo.length/2 - bmt.coords.realWorldHeight - 0.2
		minV = -$Logo.length/2 + 0.2
	)
	else if shapeType == "cylinder" then
	(
		maxU = maxC - bmt.coords.realWorldWidth
		minU = minC
		maxV = $Logo.height - bmt.coords.realWorldHeight - 0.2
		minV = 0
	)
	bmt.coords.U_offset = random minU maxU
	bmt.coords.V_offset = random minV maxV
	format "Logo bitmap U_offset % V_offset %\n" bmt.coords.U_offset bmt.coords.V_offset to:logStream

	-- Put material together
	-- If plane, then chance for transparent background
	rand = random 0 2
	if shapeType == "plane" and rand == 0 then
	(
		logoStandardMat.diffuseMap = bmt
		logoStandardMat.opacityMap = bmt
		$Logo.material = logoStandardMat
		format "Transparent plane\n" to:logStream
	)
	else
	(
		-- Random background color
		color1 = getRandColor()
		comp.mapList[1] = colorMap solidcolor:color1
		comp.mapList[2] = bmt
		logoMat.base_color_map = comp
		format "Logo background color %\n" color1 to:logStream
	
		-- Random bump map
		if random 0 1 == 0 then
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
		
		$Logo.material = logoMat
	)

	-- Return coordinates of logo corners and logo index
	z = 0
	if shapeType == "box" then z = $Logo.height
	p1 = point3 bmt.coords.U_offset bmt.coords.V_offset z
	p2 = point3 (bmt.coords.U_offset + bmt.coords.realWorldWidth) bmt.coords.V_offset z
	p3 = point3 bmt.coords.U_offset (bmt.coords.V_offset + bmt.coords.realWorldHeight) z
	p4 = point3 (bmt.coords.U_offset + bmt.coords.realWorldWidth) (bmt.coords.V_offset + bmt.coords.realWorldHeight) z
	p1 = p1 *  $Logo.transform
	p2 = p2 * $Logo.transform
	p3 = p3 * $Logo.transform
	p4 = p4 * $Logo.transform
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

function randObj obj = 
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
	obj.mat = currentMaterialLibrary[random 1 currentMaterialLibrary.count]
	
	-- Random position on table. Ensure not between camera and logo
	x = 0
	y = 0
	loop = true
	while loop do
	(
		x = random -50 30
		y = random -40 40
		d = distPointLine x y $PhysCamera001.pos[1] $PhysCamera001.pos[2] $Logo.pos[1] $Logo.pos[2]
		if x < -30 or d > 25 then loop = false
	)
	obj.pos = point3 x y z
	format "randObj pos % shape % mat %\n" obj.pos shapeType obj.mat to:logStream
)

function randObjs =
(
	numObjs = 0
	rand = random 0 100
	if rand < 40 then numObjs = 1
	else if rand < 70 then numObjs = 2
	
	format "Number of rand objects: %\n" numObjs to:logStream
	if numObjs > 0 then randObj $Obj001
	else removeObj $Obj001
	if numObjs > 1 then randObj $Obj002
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

function saveLogoInfo logoInfo fname =
(
	--m = Inverse($PhysCamera001.transform) -- left handed rotation?
	--f = $PhysCamera001.focal_length_mm
	
	camTf = Inverse($PhysCamera001.transform)
	
	corners = #(logoInfo[1], logoInfo[2], logoInfo[3], logoInfo[4])
	out = #()
	for c in corners do
	(
		p = mapWorldToScreen c camTf
		append out p
	)
	print fname
	fstream = openFile fname mode:"w"
	logoPath = logoPaths[logoInfo[5]]
	split = filterString logoPath "\\"
	format "% % % %\n%" out[1] out[2] out[3] out[4] split[split.count] to:fstream
	
	close fstream
)

function renderCam i logoInfo =
(
	-- Render masks
	-- Enable elements and set output path
	outputPath = outputDir + "\\" + i as string + "_scanline.jpg"
	renderers.current = scanlineRenderer
	re = maxOps.GetCurRenderElementMgr()
	elem = re.GetRenderElement 0
	elemPath = outputDir + "\\" + i as string + "_mask.bmp"
	re.SetRenderElementFilename 0 elemPath
	re.SetElementsActive true
	
	-- Render only logo object
	select $Logo
	
	-- Set to opacityMap, render alpha element
	logoIndex = logoInfo[5]
	tempMat = standardMaterial opacityMap:logoPngs[logoIndex]
	$Logo.material = tempMat
	render camera:$PhysCamera001 outputfile:outputPath vfb:off outputSize:outputSize renderElement:true renderType:#selected
	$Logo.material = logoMat

	-- Render rgb
	outputPath = outputDir + "\\" + i as string + ".jpg"
	renderers.current = artRenderer
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
	
	i=0
	while 1 do
	(
		format "\n\nIteration %\n" i to:logStream
		if keyboard.escPressed do exit
		print "randCam"
		randCam()
		print "randLights"
		randLights()
		print "randBackground"
		randBackground()
		print "randObjs"
		randObjs()
		print "randLogo"
		logoInfo = randLogo()
		print "saveLogoInfo"
		outputTxt = outputDir + "\\" + i as string + "_bb.txt"
		saveLogoInfo logoInfo outputTxt
		print "renderCam"
		renderCam i logoInfo
		i = i + 1
	)

	close logStream
)

main()
"Done"
