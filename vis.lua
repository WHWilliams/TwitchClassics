function wait(seconds)
	local _start = os.time()
	local _end = _start+seconds
	while (_end >= os.time()) do
	end
end

function table.empty (self)
    for _, _ in pairs(self) do
        return false
    end
    return true
end

turnPeriod = 0
mainCamX = 0
semPath = "C:/Users/veryc/OneDrive/Documents/emus/Miyamoto/semaphore"
state = savestate.object(1)

bBoxes = {}
bCount = 0
blankScreen = false
emu.setrenderplanes(true,false)
-- hitbox coordinate offsets (x1,y1,x2,y2)
local mario_hb = 0x04AC; -- 1x4
local enemy_hb = 0x04B0; -- 5x4
local coin_hb  = 0x04E0; -- 3x4
local fiery_hb = 0x04C8; -- 2x4
local hammer_hb= 0x04D0; -- 9x4
local power_hb = 0x04C4; -- 1x4

-- addresses to check, to see whether the hitboxes should be drawn at all
local mario_ch = 0x000E;
local enemy_ch = 0x000F;
local coin_ch  = 0x0030;
local fiery_ch = 0x0024;
local hammer_ch= 0x002A;
local power_ch = 0x0014;

function box(x1,y1,x2,y2)
	bCount = bCount + 1
	bBoxes[bCount] = {["x1"] = x1, ["x2"] = x2, ["y1"] = y1, ["y2"] = y2}	
end


function renderShift()
	-- grey out screen
	gui.box(0,0,256,240,{116,116,116,255})
	if(blankScreen) then return end
	for k,b in pairs(bBoxes) do		
		if b.x1 > 0 and b.x2 > 0 and b.y1 > 0 and b.y2 > 0 and b.x1 < 255 and b.x2 < 255 and b.y1 < 240 and b.y2 < 240 then
			xMax = b.x2
			if b.x2 + getCamXShift() > 255 then xMax = 255 - getCamXShift() end			
			for i = b.x1,xMax do
				for j = b.y1,b.y2 do
					red,green,blue = emu.getscreenpixel(i,j,true)
					gui.pixel(i+getCamXShift(),j,{red,green,blue,255})
				end
			end
		end	
	end
end

gui.register(renderShift)

function getCamXShift()
	local camx = memory.readbyte(0x071D)
	if camx < mainCamX then camx = camx + 255 end	
	return camx - mainCamX
end

function waitOnInput()
	oTable = {}
	joyFile = io.open('joypad','r')
	line = joyFile:read()
	while line == nil do
		line = joyFile:read()
	end
	while line ~= nil and tonumber(line) == nil do
		oTable[line] = true
		line = joyFile:read()
	end
	turnPeriod = tonumber(line)
	mainCamX = tonumber(joyFile:read())
	joyFile:close()
	joyFile = io.open('joypad','w+')
	joyFile:write('')
	joyFile:close()
	return oTable
end

function deathCheck()
	if memory.readbyte(0x00B5) > 1 then return true end 
	if memory.readbyte(0x000E) == 11 then return true end

end

-- hitbox values from https://github.com/origamirobot/HyperSpin/blob/master/Emulators/Fceux/v2.2.2/luaScripts/SMB-HitBoxes.lua
function buildBoxes()
		bCount = 0
		bBoxes = {}
		
		-- mario
		if (memory.readbyte(mario_hb) > 0) then 
			a,b,c,d = memory.readbyte(mario_hb)-3,memory.readbyte(mario_hb+1)-20,memory.readbyte(mario_hb+2)+2,memory.readbyte(mario_hb+3);
			box(a,b,c,d ); 			
		end;
		
		-- enemies
		if (memory.readbyte(enemy_ch  ) > 0) then 
			a,b,c,d = memory.readbyte(enemy_hb)-4,   memory.readbyte(enemy_hb+1)-16, memory.readbyte(enemy_hb+2)+4, memory.readbyte(enemy_hb+3)+6;
			box(a,b,c,d );		
		end;
		if (memory.readbyte(enemy_ch+1) > 0) then 
			a,b,c,d = memory.readbyte(enemy_hb+4)-4, memory.readbyte(enemy_hb+5)-16, memory.readbyte(enemy_hb+6)+4, memory.readbyte(enemy_hb+7)+6;
			box(a,b,c,d );		
		end;
		if (memory.readbyte(enemy_ch+2) > 0) then 
			a,b,c,d = memory.readbyte(enemy_hb+8)-4, memory.readbyte(enemy_hb+9)-16, memory.readbyte(enemy_hb+10)+4,memory.readbyte(enemy_hb+11)+6;
			box(a,b,c,d );		
		end;
		if (memory.readbyte(enemy_ch+3) > 0) then 
			a,b,c,d = memory.readbyte(enemy_hb+12)-4,memory.readbyte(enemy_hb+13)-16,memory.readbyte(enemy_hb+14)+4,memory.readbyte(enemy_hb+15)+6;
			box(a,b,c,d );		
		end;
		if (memory.readbyte(enemy_ch+4) > 0) then 
			a,b,c,d = memory.readbyte(enemy_hb+16)-4,memory.readbyte(enemy_hb+17)-16,memory.readbyte(enemy_hb+18)+4,memory.readbyte(enemy_hb+19)+6
			box(a,b,c,d );		
		end;
		
		-- coins
		if (memory.readbyte(coin_ch  ) > 0) then box(memory.readbyte(coin_hb),   memory.readbyte(coin_hb+1), memory.readbyte(coin_hb+2),  memory.readbyte(coin_hb+3)); end;
		if (memory.readbyte(coin_ch+1) > 0) then box(memory.readbyte(coin_hb+4), memory.readbyte(coin_hb+5), memory.readbyte(coin_hb+6),  memory.readbyte(coin_hb+7)); end;
		if (memory.readbyte(coin_ch+2) > 0) then box(memory.readbyte(coin_hb+8), memory.readbyte(coin_hb+9), memory.readbyte(coin_hb+10), memory.readbyte(coin_hb+11) ); end;
		
		-- (mario's) fireballs
		if (memory.readbyte(fiery_ch  ) > 0) then box(memory.readbyte(fiery_hb),   memory.readbyte(fiery_hb+1), memory.readbyte(fiery_hb+2), memory.readbyte(fiery_hb+3)); end;
		if (memory.readbyte(fiery_ch+1) > 0) then box(memory.readbyte(fiery_hb+4), memory.readbyte(fiery_hb+5), memory.readbyte(fiery_hb+6),memory.readbyte(fiery_hb+7) ); end;
		
		-- hammers
		if (memory.readbyte(hammer_ch  ) > 0) then box(memory.readbyte(hammer_hb),   memory.readbyte(hammer_hb+1), memory.readbyte(hammer_hb+2), memory.readbyte(hammer_hb+3)); end;
		if (memory.readbyte(hammer_ch+1) > 0) then box(memory.readbyte(hammer_hb+4), memory.readbyte(hammer_hb+5), memory.readbyte(hammer_hb+6), memory.readbyte(hammer_hb+7)); end;
		if (memory.readbyte(hammer_ch+2) > 0) then box(memory.readbyte(hammer_hb+8), memory.readbyte(hammer_hb+9), memory.readbyte(hammer_hb+10),memory.readbyte(hammer_hb+11) ); end;
		if (memory.readbyte(hammer_ch+3) > 0) then box(memory.readbyte(hammer_hb+12),memory.readbyte(hammer_hb+13),memory.readbyte(hammer_hb+14),memory.readbyte(hammer_hb+15) ); end;
		if (memory.readbyte(hammer_ch+4) > 0) then box(memory.readbyte(hammer_hb+16),memory.readbyte(hammer_hb+17),memory.readbyte(hammer_hb+18),memory.readbyte(hammer_hb+19) ); end;
		if (memory.readbyte(hammer_ch+5) > 0) then box(memory.readbyte(hammer_hb+20),memory.readbyte(hammer_hb+21),memory.readbyte(hammer_hb+22),memory.readbyte(hammer_hb+23) ); end;
		if (memory.readbyte(hammer_ch+6) > 0) then box(memory.readbyte(hammer_hb+24),memory.readbyte(hammer_hb+25),memory.readbyte(hammer_hb+26),memory.readbyte(hammer_hb+27) ); end;
		if (memory.readbyte(hammer_ch+7) > 0) then box(memory.readbyte(hammer_hb+28),memory.readbyte(hammer_hb+29),memory.readbyte(hammer_hb+30),memory.readbyte(hammer_hb+31) ); end;
		if (memory.readbyte(hammer_ch+8) > 0) then box(memory.readbyte(hammer_hb+32),memory.readbyte(hammer_hb+33),memory.readbyte(hammer_hb+34),memory.readbyte(hammer_hb+35) ); end;

		-- powerup
		if (memory.readbyte(power_ch) > 0) then box(memory.readbyte(power_hb)-4,memory.readbyte(power_hb+1)-4,memory.readbyte(power_hb+2)+4,memory.readbyte(power_hb+3)+4 ); end;

end

panicCount = 0
panicLimit = 5

function panic()
	
	doPanic = false
	
	if memory.readbyte(0x000E) == 11 then doPanic = true end 
	fallingToDoom = memory.readbyte(0x00B5) > 1 and memory.readbyte(0x000E) == 8
	
	doPanic = doPanic or fallingToDoom
	panicCount = panicCount + 1
	if doPanic and panicCount > panicLimit then 
		panicCount = 0
		local panicFile = io.open('panic','w+')
		panicFile:write('PANIC')
		panicFile:close()	
	end
	
	
end



while true do
	local padInput = waitOnInput()
	
	savestate.load(savestate.object(1))
	for frameCount=0,(turnPeriod*60) do
		joypad.write(1,padInput)
		joypad.write(2,padInput)
		buildBoxes()
		emu.frameadvance()
	end
	blankScreen = true
	emu.frameadvance()
	panic()
	-- wait for at least one second
	for frameCount=0,((1-turnPeriod)*60) do
		emu.frameadvance()
	end
	blankScreen = false
	
	
	
	-- hit semaphore
	local sf = io.open('semaphore','w+')
	sf:write('1')
	sf:close()
end