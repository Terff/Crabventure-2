module(...,package.seeall)
Filter = require("src.utilities.filter")
Maze = require("src.utilities.maze")
Components = require("src.components")
StaticTCMGrower = require("src.entities.staticTCMGrower")

local filter = Filter.filter({"chunks","chunkData","position","spriteMap","camera","id"})

function update(world)
  for _,entity in pairs(world) do
    if filter:fit(entity) then
      --width of map
      mwid = entity.chunkData.width
      --height of map
      mhei = entity.chunkData.height
      --width of one chunk in tiles
      wid = entity.chunkData.chunkWidth
      --2d array of chunks
      chunks = entity.chunks.chunks

      --get the maze from maze.lua, currently always uses maze1 but maybe I'll add more possible maze algorithms
      maze = Maze.maze1(mwid,mhei,entity.chunkData.start)

      --build map 'chunks' based off the maze we created
      --chunks are just an array of openings in each 'room'
      for x = 1, mwid do
        chunks[x] = {}
        for y = 1, mhei do
          chunks[x][y] = {}
          --maze spot is a shitty variable name for a 'room' in the maze
          mazeSpot = maze[x][y]
          --list of attachment points for a room
          holes = mazeSpot.holes

          for _,hole in ipairs(holes) do
            currentHole = {x = 0, y = 0,width = 0}
            if chunks[x+hole.x] and chunks[x+hole.x][y+hole.y] then
              found = searchPair(hole,chunks[x+hole.x][y+hole.y])
              if found ~= nil then
                currentHole = pairOpening(hole,wid,3,found)
              else
                currentHole = genOpening(hole,wid,3)
              end
            else
              --currentHole = genOpening(hole,wid,3)
            end
            table.insert(chunks[x][y],currentHole)
          end
          builder = StaticTCMGrower.staticTCMGrower()
          if #chunks[x][y] == 2 and love.math.random(3) > 1 then
            builder.builder.types = {2,5}
            builder.builder.parameters[2] = {
              width = chunks[x][y][1].width,
              sPos =
                {x = chunks[x][y][1].x, y = chunks[x][y][1].y},
              ePos =
                {x = chunks[x][y][2].x, y = chunks[x][y][2].y}
            }

          else
            builder.builder.types = {1,3}
            count = 2
            for h = 1, #chunks[x][y] do
              count = count + 1
              table.insert(builder.builder.types,4)
              builder.builder.parameters[count] = {
                width = chunks[x][y][h].width,
                height = chunks[x][y][h].width,
                position = {
                  x = chunks[x][y][h].x,
                  y = chunks[x][y][h].y
                }
              }
            end
          end
          builder.builder.width = wid
          builder.builder.height = wid
          builder.position.x = wid*(x-1)
          builder.position.y = wid*(y-1)
          builder.spriteMap = entity.spriteMap
          builder.camera = entity.camera
          builder.id = Components.id(entity.id.value)
          table.insert(world,builder)
        end
      end
      entity.chunks = nil
      entity.chunkData = nil
    end
  end
end

function genOpening(hole,cwid,hwid)
  osx = 0;
  osy = 0

  if math.abs(hole.x) ~= 0 then
    center = (cwid+1-hwid+1.0)/2
    osx = center + hole.x * (center - 1)
    osy = love.math.random(2,cwid-hwid)
  end
  if math.abs(hole.y) ~= 0 then
    center = (cwid+1-hwid+1.0)/2
    osy = center + hole.y * (center - 1)
    osx = love.math.random(2,cwid-hwid)
  end
  return {x = osx, y = osy, width = hwid,hx = hole.x,hy = hole.y}
end

function pairOpening(hole,cwid,hwid,phole)
  osx = 0;
  osy = 0

  if math.abs(hole.x) ~= 0 then
    center = (cwid+1-hwid+1.0)/2
    osx = center + hole.x * (center - 1)
    osy = phole.y
  end
  if math.abs(hole.y) ~= 0 then
    center = (cwid+1-hwid+1.0)/2
    osy = center + hole.y * (center - 1)
    osx = phole.x
  end
  return {x = osx, y = osy, width = hwid,hx = hole.x,hy = hole.y}
end

function searchPair(hole,chunk)
  for _,h in pairs(chunk) do
    if(-hole.x == h.hx and -hole.y == h.hy) then
      return h
    end
  end
  return nil
end
