emulatorCount = 3
AIMode = true

waitForElected = False
emuPaths = {[1] = "C:/Users/veryc/OneDrive/Documents/emus/Mario/", [2] = "C:/Users/veryc/OneDrive/Documents/emus/Luigi/",[3] = "C:/Users/veryc/OneDrive/Documents/emus/Jumpman/"}
semPath = "C:/Users/veryc/OneDrive/Documents/emus/Miyamoto/semaphore"
dumpPath = "C:/Users/veryc/OneDrive/Documents/emus/GUI2/data"

killersPath = "C:/Users/veryc/OneDrive/Documents/emus/GUI2/killers"

lifeDepositPath = "C:/Users/veryc/OneDrive/Documents/emus/GUI2/lifeDeposits"


voteEndPath = "C:/Program Files/HexChat/data"
lifeCountDumpPath = "C:/Users/veryc/OneDrive/Documents/emus/GUI2/lifeCountDump"
boostFile = io.open("C:/Users/veryc/OneDrive/Documents/emus/Miyamoto/boost",'r')
state = savestate.object(1)



pullQ = 2
pushQ = 5
repeatCount = 22

function getRepeatCount()
	local fff = io.open('repeatCount')
	local n = fff:read()
	if tonumber(n) then
		return n
	else
		return repeatCount
	end
end



turnPeriod = 1
tallies = {}
NNTallies = 0
moves = {}
votesToSupporters = {}
progress = 0
votesThisTurn = 0
turnDurationSoFar = 0
turnDurationMileStone = 0
timeArray = {[1]=turnPeriod,[2]=turnPeriod,[3]=turnPeriod}

pattern = '([ab]?[ab]?[AB]?[AB]?[udlr]?[udlr]?[UDLR]?[UDLR]?[ab]?[ab]?[AB]?[AB]?[udlr]?[udlr]?[UDLR]?[UDLR]?[ab]?[ab]?[AB]?[AB]?)'
translationTable = {["time"] = "time", ["a"] = "A",["b"] = "B", ["A"] = "A",["B"] = "B", ["u"] = "up", ["l"] = "left", ["r"] = "right", ["d"] = "down", ["U"] = "up", ["L"] = "left", ["R"] = "right", ["D"] = "down"}
reverseTranslation = {["time"] = "", ["start"] = "start", ["select"] = "select", ["A"] = "a", ["B"] = "b", ["up"] = "u", ["left"] = "l", ["right"] = "r", ["down"] = "d"}



function isMarioTransitioning()
	if memory.readbyte(0x00B5) > 1 then return true end 
	if memory.readbyte(0x000E) ~= 8 then return true end 
	if memory.readbyte(0x000E) ~= 1 then return true end
	return false
end

function isMarioNormal()
	if memory.readbyte(0x00B5) > 1 then return false end 
	if memory.readbyte(0x000E) == 8 then return true end
	if memory.readbyte(0x000E) == 1 then return true end
	return false
end


getmetatable('').__index = function(str,i)
  if type(i) == 'number' then
    return string.sub(str,i,i)
  else
    return string[i]
  end
end

function table.empty (self)
    for _, _ in pairs(self) do
        return false
    end
    return true
end

function spairs(t,order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

function split(inputstr, sep)
        if sep == nil then
                sep = "%s"
        end
        local t={} ; i=1
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                t[i] = str
                i = i + 1
        end
        return t
end

function getVotesPerSecond()
	-- calculate votes per second
	local currentMileStone = os.clock()
		
	turnDurationSoFar = turnDurationSoFar + (currentMileStone - turnDurationMileStone)

	turnDurationMileStone = currentMileStone
	
	if turnDurationSoFar == 0 then return 1 end
	if votesThisTurn == 0 then return 1 end
	local vps = votesThisTurn / turnDurationSoFar		
	
	return vps
end


function parseVote(line)
	if line == nil then return nil end
	-- remove tab
	line = split(line,"\t")
	if line[2] == nil then return nil end
	local player = line[1]
	
	line = line[2]
	line = string.gsub(line," ", "")
	line = string.gsub(line,"+","")
	line = string.gsub(line,"and","")
	line = string.gsub(line,"jump","a")
	line = string.gsub(line,"up","u")
	line = string.gsub(line,"left","l")
	line = string.gsub(line,"right","r")
	line = string.gsub(line,"down","d")
	line = string.gsub(line,"And","")
	line = string.gsub(line,"Jump","a")
	line = string.gsub(line,"Up","u")
	line = string.gsub(line,"Left","l")
	line = string.gsub(line,"Right","r")
	line = string.gsub(line,"Down","d")
	line = string.gsub(line,"forward","r")
	line = string.gsub(line,"Forward","r")
	line = string.gsub(line,"back","l")
	line = string.gsub(line,"Back","l")
	line = string.gsub(line,"AI","ai")
	line = string.gsub(line,"Ai","ai")
	
	
	if line == 'ai' then 
		NNTallies = NNTallies + 1
		return nil
	end
	
	if line == 'start' then return {['start'] = true,['voter'] = player} end
	if line == 'select' then return {['select'] = true,['voter'] = player} end
	if line == 'Start' then return {['start'] = true,['voter'] = player} end
	if line == 'Select' then return {['select'] = true,['voter'] = player} end
	
	local outputTable = {['voter'] = player}
	
	-- check for time
	
	if tonumber(line[1]) then
		if string.len(line) ~= 1 then 			
			local localTime = tonumber(line[1])
			if localTime > 0 and localTime < 10 then
				outputTable["time"] = localTime / 10
				line = string.sub(line,2,string.len(line))	
			end
		end
	end
	
	
	if string.len(line) > 4 then return nil end
	m = string.match(line,pattern) 
	if m then
		for c in m:gmatch(".") do			
			outputTable[translationTable[c]] = true
		end
		
		return outputTable
	end
		
	return nil
end
function saveMain()
	savestate.save(state)
	savestate.persist(state)
end
function getElected()
	local elected = {}
	timeArray = {[1]=turnPeriod,[2]=turnPeriod,[3]=turnPeriod}
	i = 1
	for k,v in spairs(tallies, function(t,a,b) return t[b] < t[a] end) do
		if i > emulatorCount then break end
		move = moves[k]		
		if not table.empty(move) then
			if move["time"] then 
				timeArray[i] = move["time"] 
				--move["time"] = nil
			end
			
			elected[i] = moves[k]			
			i = i + 1
		end
	end
	
	return elected
end
function pressNominees(el)
	local i = 1
	files = {}
	dumpArray = {[1]=" ",[2]=" ",[3]=" "}
	
	for j = 1,emulatorCount do
		while not files[j] do 
			files[j] = io.open(emuPaths[j] .. 'joypad','w+')
		end
	end
	
	for k,v in spairs(el) do
		if i > emulatorCount then break end
		
		local fl = files[i]
		dumpArray[i] = ""
		if timeArray[i] ~= 1 then dumpArray [i] = tostring(timeArray[i]*10) end
		
		for kk, vv in spairs(v) do
			dumpArray[i] = dumpArray[i] .. reverseTranslation[kk]
			fl:write(kk..'\n')
		end		
		
		i = i + 1
	end	
	
	dumpFile = io.open(dumpPath,'w+')
	for j=1,3 do		
		dumpFile:write(dumpArray[j]..'\n')
	end

	dumpFile:write(math.floor(progress))
	dumpFile:close()
	
	for j = 1,emulatorCount do
		files[j]:write(timeArray[j] ..'\n')
		files[j]:write(memory.readbyte(0x071D)) -- write cam x
		files[j]:close()
	end	
end
function getMoveKey(moveTable)
	s = ""
	for k,v in spairs(moveTable) do
		if k == "time" then 
			s = s .. tostring(v)
		elseif  k == "voter" then
			s = s
		else
			s = s .. tostring(k)
		end
	end
	return s
end

function populateVoteStats(voter,key)
	if voter == nil or key == nil then return end 
	if votesToSupporters[key] then
		table.insert(votesToSupporters[key],voter)
	else
		votesToSupporters[key] = {voter}
	end
end

marioKilled = false
luigiKilled = false
flagGrabbed = false

function hasMarioDied()
	marioKilled = marioKilled or memory.readbyte(0x000E) == 11
	marioKilled = marioKilled or (memory.readbyte(0x00B5)  > 1 and 0x000E ~= 8)

end

function hasLuigiDied()

end

function hasFlagBeenGrabbed()
	flagGrabbed = flagGrabbed or memory.readbyte(0x001D) == 3
end


function writeStats(majorityVote)
	
	majoritySupporters = votesToSupporters[majorityVote]
	if majoritySupporters == nil then return end
	print (marioKilled)
	if marioKilled then
		local f = io.open("C:/Users/veryc/OneDrive/Documents/emus/GUI2/killers",'a')
		for k, v in pairs(majoritySupporters) do
			f:write(v)
			f:write('\n')
		end
		f:close()
	end
	
	
	
	-- init stat values
	marioKilled = false
	luigiKilled = false
	flagGrabbed = false
	
	votesToSupporters = {}

end

function countVote(lf)	
	local move = parseVote(lf:read())
	if move == nil then return end
	local voter = move.voter
	move.voter = nil
	if table.empty(move) then return end
	local moveKey = getMoveKey(move)
	populateVoteStats(voter,moveKey)
	moves[moveKey] = move
	if tallies[moveKey] == nil then tallies[moveKey] = 0 end
	tallies[moveKey] = tallies[moveKey] + 1
end

function isSemUp()
	local c = 0
	
	for i=1,emulatorCount do
			local sf = io.open(emuPaths[i] .. 'semaphore','r')
			local flag = sf:read()
			if flag == '1' then c = c + 1 end
			sf:close()
	end
	
	if c == emulatorCount then
		for i=1,emulatorCount do
			sf = io.open(emuPaths[i] .. 'semaphore','w+')
			sf:write("")
			sf:close()
		end	
		return true
	end	
	
	return false
end
function repetitionLoop(lf)
	
	while (not isSemUp()) do
		countVote(lf)
	end
end

function waitingForProgress()
	return progress < 100
end

function hasMarioFallen()
	return memory.readbyte(0x00B5) > 1
end

function boostLives()
	local B = tonumber(boostFile:read())
	print(B)
	if B and B ~= 0 and memory.readbyte(0x07F8) == 4 and memory.readbyte(0x07F9) == 0 and memory.readbyte(0x07FA) == 1 then 
		memory.writebyte(0x075A, memory.readbyte(0x075A) + B) 
		boostFile:close()
		boostFile = io.open('C:/Users/veryc/OneDrive/Documents/emus/Miyamoto/boost','w+')
		boostFile:write('0')
		boostFile:close()
		boostFile = io.open('C:/Users/veryc/OneDrive/Documents/emus/Miyamoto/boost','r')
	end	
end
function musicDump()
	local ff = io.open('musicdump','w+')
	ff:write(memory.readbyte(0x075F)*10 + memory.readbyte(0x0760))
	ff:close()

end
logFile = io.open('C:/Users/veryc/AppData/Roaming/HexChat/logs/lastsession.log','r')
function dumpStart()
	startfile = io.open('start.txt','w+')
	local doDump = false
	if memory.readbyte(0x0770) == 0 then doDump = true end
	if memory.readbyte(0x0776) == 1 then doDump = true end
	if doDump then 
		startfile:write('Press Start')
	else
		startfile:write('')	
	end
	startfile:close()
end



while(true) do
	
	tallies = {}
	moves = {}
	votesToSupporters = {}
	local elected = {}
	turnDurationMileStone = os.clock()
	votesThisTurn = 0
	turnDurationSoFar = 0
	progress = 0
	NNTallies = 0
	NNfollow = false
	

	
	-- clear log
	--logFile:close()
	--logFile = io.open('C:/Users/veryc/AppData/Roaming/HexChat/logs/lastsession.log','w+')
	--logFile:write('')
	--logFile:close()
	--logFile = io.open('C:/Users/veryc/AppData/Roaming/HexChat/logs/lastsession.log','r')
	
	while waitingForProgress() do		
		autoPushQ = 100/getRepeatCount()
		progress = progress + autoPushQ
		
		elected = getElected()		
				
		pressNominees(elected)
		repetitionLoop(logFile)
				
		
	end
	local voteEndFile = io.open(voteEndPath,'w+')
	voteEndFile:write('1')
	voteEndFile:close()		

	local mainMove = elected[1]
	if mainMove  == nil then mainMove = {} end
	
	marioInTransit = false
	
	--if pcall(boostLives) then
	--	if nil then print('x') end
	--else
	--	print("failed to boost lives")
	--end
	marioInTransit = marioInTransit or isMarioTransitioning()
	for frameCount = 0,(timeArray[1] * 60 - 1)  do		
		joypad.write(1,mainMove)
		joypad.write(2,mainMove)
		emu.frameadvance()
		hasMarioDied()
		hasFlagBeenGrabbed()
		marioInTransit = marioInTransit or isMarioTransitioning()
	end
	-- let go
	emu.frameadvance()
	hasMarioDied()
	hasFlagBeenGrabbed()
	marioInTransit = marioInTransit or isMarioTransitioning()
	
	-- write stats
	writeStats(getMoveKey(mainMove))
	
	while marioInTransit do			
		emu.frameadvance()	
		marioInTransit = not isMarioNormal()
	end
			
	--musicDump()
	dumpStart()
	saveMain()
		
end
logFile:close()
boostFile:close()