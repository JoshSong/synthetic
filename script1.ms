"Start"

outputSize = point2 640 480
matLib

stamp =  timeStamp()
seed stamp
outputDir = maxFilePath + "output\\" + stamp as string
makeDir outputDir

tableHeight = 60

matLibPath = maxFilePath + "\\mylib.mat"

-- Load logo images
logoDir = maxFilePath + "flickr47\\*"
logoPaths = getFiles logoDir
logoBmps = #()
for i in logoPaths do
(
	bmt = bitmapTexture filename:i
	bmt.coords.realWorldScale = true
	bmt.coords.mapping = 2
	bmt.coords.U_Tile = false
	bmt.coords.V_Tile = false
	append logoBmps bmt
)

-- The texture/material for the logo object
comp = compositeTexture()
comp.add()
logoMat = standardMaterial()
$Logo.material = logoMat

function randCam =
(
	logo = $Logo.pos
	
	x = logo[1] + (random 10 40)
	y = logo[2]
	z = logo[3] + (random 10 40)
	dist = random 50 100
	theta = random -45 45
	x = x + dist * cos(theta)
	y = y + dist * sin(theta)
	$PhysCamera001.pos = [x, y, z]
	
	x = logo[1] + (random -10 10)
	y = logo[2] + (random -10 10)
	z = logo[3] + (random -5 10)
	$PhysCamera001.Target.pos = [x, y, z]
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
	)
	all[2].enabled = random 0 3 > 0
)

function randBackground = 
(
	$Table.mat = currentMaterialLibrary[random 1 currentMaterialLibrary.count]
	mat2 = currentMaterialLibrary[random 1 currentMaterialLibrary.count]
	$Wall1.mat = mat2
	$Wall2.mat = mat2
	$Wall3.mat = mat2
	$Wall4.mat = mat2
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
	-- Choose shape
	shapeType = ""
	rand = random 0 100
	if rand < 100 then
	(
		shapeType = "plane"
		$Logo.baseObject = $Plane001.baseObject
	)
	else
	(
		shapeType = "box"
		$Logo.baseObject = $Box001.baseObject
	)
	
	-- Randomize size
	$Logo.width = random 18 25.0 -- x to the right of camera
	$Logo.length = random 15 25.0 -- y upwards
	if shapeType == "box" then $Logo.height = random 2 20.0 -- z towards camera

	-- Move so it rests on table
	pos = $Logo.pos
	pos[3] = tableHeight + $Logo.length/2
	$Logo.pos = pos

	-- Randomize rotation
	$Logo.rotation.z_rotation = random 80 100

	-- Choose a random logo bitmap texture and get its aspect ratio
	logoIndex = random 1 logoBmps.count
	bmt = logoBmps[logoIndex]
	ratio = bmt.bitmap.width as float / bmt.bitmap.height

	-- Randomize logo size
	minHeight = 6.0
	maxHeight = $Logo.length - 0.01
	if $Logo.width / ratio < maxHeight then maxHeight = $Logo.width / ratio
	if maxHeight > minHeight then 
		bmt.coords.realWorldHeight = random minHeight maxHeight
	else
		bmt.coords.realWorldHeight = minHeight
	bmt.coords.realWorldWidth = ratio * bmt.coords.realWorldHeight

	-- Random logo position
	maxU = $Logo.width/2 - bmt.coords.realWorldWidth - 0.01
	minU = -$Logo.width/2 + 0.01
	maxV = $Logo.length/2 - bmt.coords.realWorldHeight - 0.01
	minV = -$Logo.length/2 + 0.01
	bmt.coords.U_offset = random minU maxU
	bmt.coords.V_offset = random minV maxV

	-- Put material together
	-- If plane, then chance for transparent background
	rand = random 0 0
	if shapeType == "plane" and rand == 0 then
		logoMat.diffusemap = bmt
	else
	(
		-- Random background color
		color1 = getRandColor()
		comp.mapList[1] = colorMap solidcolor:color1
		comp.mapList[2] = bmt
		logoMat.diffusemap = comp
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

fn mapWorldToScreen thePoint camTf =
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
	format "% % % %\n%" out[1] out[2] out[3] out[4] logoPath to:fstream
	
	close fstream
)

function main =
(
	
	if getActiveCamera()!=$PhysCamera001 then
	(
		messagebox "Active viewport must use camera"
		return -1
	)

	-- Load material library into currentMaterialLibrary global
	if getMatLibFileName() != matLibPath then loadMaterialLibrary matLibPath
	
	i=0
	while 1 do
	(
		if (keyboard.escPressed) do ( throw "ESCAPE PRESSED" )
		randCam()
		randLights()
		randBackground()
		logoInfo = randLogo()
		outputTxt = outputDir + "\\" + i as string + "_bb.txt"
		saveLogoInfo logoInfo outputTxt
		outputImg = outputDir + "\\" + i as string + ".jpg"
		render camera:$PhysCamera001 outputfile:outputImg vfb:off outputSize:outputSize
		i = i + 1
	)
)

main()
"Done"
