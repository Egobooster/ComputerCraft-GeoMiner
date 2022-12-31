-- geomine.lua v1.0
-- Author: Egobooster
-- requires: Advanced Peripherals - GeoScanner

-- config
ENDERCHEST_SLOT = 16
BEDROCK_Y = -55
MAXERROR = 15
y_steps = 4
search_ore = "_ore"
fuel_enderchest = false
FUEL_ENDERCHEST_SLOT = 15
unmineable_ores = {"allthemodium_ore","allthemodium_slate_ore","unobtainium_ore","vibranium_ore"}

-- functions

function log(s)
  print(s)
  logfile.writeLine(s)
  logfile.flush()
end

function isinventoryfull()
  for x = 1,16 do
      turtle.getItemCount(x)
      if turtle.getItemCount(x) == 0 then
        return false
      end
  end
  return true
end

-- bless you stackoverflow guy
function mysplit (inputstr, sep)
  if sep == nil then
          sep = "%s"
  end
  local t={}
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
          table.insert(t, str)
  end
  return t
end

-- bless you other stackoverflow guy
local function isblacklisted (val)
  for index, value in ipairs(unmineable_ores) do
      if string.find(val,value) then
          return true
      end
  end

  return false
end

function savepos()
  gps = fs.open("gps.data","w")
  gps.write(x .. ";")
  gps.write(y .. ";")
  gps.write(z .. ";")
  gps.write(facing .. "")
  gps.close()
end  

function saveunmineablepos(ore)
  local unm = fs.open("unmineable.data","a")
  unm.write(ore .. ";")
  unm.write(x .. ";")
  unm.write(y .. ";")
  unm.write(z .. ";")
  unm.write(facing .. "")
  unm.writeLine("")
  unm.close()
end  

function printscan(scan)
  for k,v in pairs(scan) do
      for a,b in pairs(v) do
          if a ~= "tags" then
            log(a .. ": " .. b)
          end
      end
      log("------")
  end
end

function remove_non_ores(scan)
  for number,block in pairs(scan) do
    if string.find(block["name"],search_ore) then
      log("found: " .. block["name"])
      if isblacklisted(block["name"]) then
        log("unminable ore found, saving location and removing from scan. Pray that we don't try to path through it!")
        saveunmineablepos(block["name"])
        scan[number] = nil
      end
    else
      scan[number] = nil
    end
  end
end

function calculatedistance(block)
  local x_dist = tonumber(block["x"]) - x
  local y_dist = tonumber(block["y"]) - y - (y_steps * step)
  local z_dist = tonumber(block["z"]) - z

  if x_dist < 0 then
    x_dist = x_dist * (-1)
  end
  if y_dist < 0 then
    y_dist = y_dist * (-1) 
  end  
  if z_dist < 0 then
    z_dist = z_dist * (-1)
  end
  return x_dist + y_dist + z_dist
end

function moveUp(n)
  local i = 0
  local errorcounter = 0
  while i < n do
    checkInventory()
    turtle.digUp()
    if not emergency then
      checkFuel()
    end
    if turtle.up() then
      i=i+1
      errorcounter = 0
      y = y+1
      savepos()
    else
      if turtle.attackUp() then
        log("I'm walking here")
      else
        errorcounter = errorcounter+1
      end
      i = i-1
      if errorcounter > MAXERROR then
        log("i cant move!")
        error("exit called!")
        
      end
    end
  end
end

function moveDown(n)
  local i = 0
  local errorcounter = 0
  while i < n do
    checkInventory()
    turtle.digDown()
    if not emergency then
      checkFuel()
    end
    if turtle.down() then
      i=i+1
      errorcounter = 0
      y = y-1
      savepos()
    else
      if turtle.attackDown() then
        log("I'm walking here!")
      else
        errorcounter = errorcounter+1
      end
      if errorcounter > MAXERROR then
        log("i cant move!")
        error("exit called!")
        
      end
    end
  end
end

function setfacing(d)
  while facing ~= d do
    turtle.turnRight()
    if facing == "n" then
      facing = "e"
    elseif facing == "e" then
      facing = "s"
    elseif facing == "s" then
      facing = "w"
    elseif facing == "w" then
      facing = "n"
    end
    savepos()
  end
end

function moveDirection(n,f)
  setfacing(f)
  local i = 0
  local errorcounter = 0
  while i < n do
    checkInventory()
    turtle.dig()
    if not emergency then
      checkFuel()
    end
    if turtle.forward() then
      i=i+1
      errorcounter = 0
      if f == "n" then
        z = z-1
      elseif f == "e" then
        x = x+1
      elseif f == "s" then
        z = z+1
      elseif f == "w" then
        x = x-1
      end
      savepos()
    else
      if turtle.attack() then
        log("I'm walking here")
      else
        errorcounter = errorcounter+1
      end
      log("errorcounter: " .. errorcounter)
      if errorcounter > MAXERROR then
        log("I'm walking here")
        error("exit called!")
        
      end
    end
  end
end

function moveTo(xl,yl,zl)

  --- y level
  if tonumber(yl) < 0 then
    moveDown(yl * (-1))
  end
  if yl > 0 then
    moveUp(yl)
  end

  --- x level
  if xl < 0 then
    moveDirection(xl * (-1),"w")
  end
  
  if xl > 0 then
    moveDirection(xl,"e")
  end

  --- z level
  if zl < 0 then
    moveDirection(zl * (-1),"n")
  end
  
  if zl > 0 then
    moveDirection(zl,"s")
  end
end

function checkInventory()
  if isinventoryfull() then
    log("inventory is full")
    dumpInv()
  end
end

function dumpInv()
  log("dumping inventory")
  turtle.select(ENDERCHEST_SLOT)
  local errorcounter = 0
  while not turtle.placeUp() do
    if (not turtle.digUp()) and (not turtle.attackUp()) then
      errorcounter = errorcounter+1
      if errorcounter > MAXERROR then
        log("cant place enderchest!")
        error("cant place enderchest!")
        
      end
    end
  end
  for i = 1,16 do
    if i ~= FUEL_ENDERCHEST_SLOT then
      turtle.select(i)
      turtle.dropUp()
    end
  end
  turtle.select(ENDERCHEST_SLOT)
  turtle.digUp()
end

function checkFuel()
  local curfuel = turtle.getFuelLevel()
  --log("Fuel: " .. curfuel)
  if fuel_enderchest then
    if curfuel == 0 then
      dumpInv()
      log(FUEL_ENDERCHEST_SLOT)
      turtle.select(FUEL_ENDERCHEST_SLOT)
      turtle.placeUp()
      turtle.suckUp(64)
      turtle.refuel(64)
      turtle.digUp()
    end
  else
    local homedistance = 0
    if x > 0 then
      homedistance = homedistance + x
    else
      homedistance = homedistance - x
    end
    if y > 0 then
      homedistance = homedistance + y
    else
      homedistance = homedistance - y
    end
    if z > 0 then
      homedistance = homedistance + z
    else
      homedistance = homedistance - z
    end
    if homedistance >= curfuel then
      --panic go home
      log("out of fuel i need to go home!")
      emergency = true
      moveTo(-x,-y,-z)
      setfacing(og_facing)
      error("Out of Fuel!")
    end
  end
end

-- Init
emergency = false
logfile = fs.open("geomine.log","w")
facing = nil
args = {...}
if args[1] == nil or args[2] == nil or args[3] == nil then
    print("geomine <facing> <radius> <y> [search_ore]")
    print("facing:")
    print("n - North")
    print("e - East")
    print("s - South")
    print("w - West")
    print("radius - the radius the turtle will scan and mine")
    print("y - current y level")
    print("search_ore - i will try to only search for *search_ore*")
end
if args[5] ~= nil then
  if args[5] == "--resume" then
    log("resuming program!")
    x = 0
    y = 0
    z = 0
    local gps_data_line = nil
    local gps = fs.open("gps.data","r")
    if gps ~= nil then
      gps_data_line = gps.readLine()
      gps.close()
    end
    if gps_data_line ~= nil and gps_data_line ~= "" then
      local cords = mysplit(gps_data_line,";")
      x = tonumber(cords[1])
      y = tonumber(cords[2])
      z = tonumber(cords[3])
      facing = cords[4]
    end
    log("going home!")
    moveTo(-x,-y,-z)
    setfacing(facing)
    log("restarting geomine with previous parameters")
  else
    gps = fs.open("gps.data","w")
    gps.write("")
    gps.close()
    run = fs.open("run.conf","w")
    run.write("")
    run.close()
  end
end
x = 0
y = 0
z = 0
og_facing = args[1]
facing = og_facing
log("facing is:" .. facing)
radius = tonumber(args[2])
log("radius is: " .. radius)
starting_y = tonumber(args[3])
log("starting y level is: " .. starting_y)
log("expecting bedrock at: " .. BEDROCK_Y)
if args[4] ~= nil then
    search_ore = args[4]
end
log("using search ore: " .. search_ore)

local gs = peripheral.find("geoScanner")
local run_conf = fs.open("run.conf","w")

run_conf.write(facing .. ";")
run_conf.write(radius .. ";")
run_conf.write(starting_y .. ";")
run_conf.write(search_ore)
run_conf.flush()


-- main
function main()
  -- init
  step = 0
  local gps = fs.open("gps.data","r")
  local line = nil
  if gps ~= nil then
    line = gps.readLine()
    gps.close()
  end
  if line ~= nil and line ~= "" then
    cords = mysplit(line,";")
    x = tonumber(cords[1])
    y = tonumber(cords[2])
    z = tonumber(cords[3])
    facing = cords[4]
  end
  savepos(x,y,z,facing)
  local run = true
  while run do
    -- scan
    cost = gs.cost(radius)
    if cost > turtle.getFuelLevel() then
      log("not enough fuel!")
      error("not enough fuel for scanning!")
      
    end
    local scan = gs.scan(radius)
    if scan ~= nil then
      remove_non_ores(scan)
      printscan(scan)

      -- find nearest block
      local running = true
      while running do
        mindist = 9999
        targetblock = nil
        targetnumber = nil
        for number,block in pairs(scan) do
          distance = calculatedistance(block)
          if distance < mindist then
            mindist = distance
            targetblock = block
            targetnumber = number
          end
        end

        if mindist ~= 9999 and targetblock ~= nil and targetnumber ~= nil then
          print("target: ", targetblock["name"])
          log("target: " .. targetblock["name"])
          -- move to target
          moveTo(tonumber(targetblock["x"] - x),
          tonumber(targetblock["y"] - y - (y_steps * step)),
          tonumber(targetblock["z"] - z))
          scan[targetnumber] = nil
        else
          running = false
        end
        
      end
    end
    -- gehe zu ursprung - y_steps
    step = step +1
    local targety = 0 - y - (y_steps * step)
    if (starting_y+targety+y) > (BEDROCK_Y+radius) then
      log("moving to next scan position")
      moveTo(-x,targety,-z)
      log("x: " .. x .. " y: " .. y .. " z: " .. z)
    else
      print("starting_y + targety + y: ",(starting_y+targety+y))
      log("starting_y + targety + y: " .. (starting_y+targety+y))
      print("going back home")
      log("going back home")
      moveTo(-x,-y,-z)
      log("setting facing to: " .. og_facing)
      setfacing(og_facing)
      run = false
    end
  end
  dumpInv()
end


main()


logfile.close()
gps = fs.open("gps.data","w")
gps.write("")
gps.close()
run = fs.open("run.conf","w")
run.write("")
run.close()
