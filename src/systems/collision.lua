module(...,package.seeall)

Filter = require("src.utilities.filter")
globals = require('src.utilities.globals')

local filter = Filter.filter({"position","collider","movement"})

function update(world)
  for _,entity in pairs(world) do
    if filter:fit(entity) then
      --find all dynamic colliders
      searchFilterDynamic = Filter.filter({"position","collider"})
      activeDynamicColliders = searchFilterDynamic:allFit(world)
      for _,e2 in pairs(activeDynamicColliders) do
        future = futurePosition(entity)
        if(future.x == e2.position.x and future.y == e2.position.y and entity.collider.id ~= e2.collider.id) then
          collision(entity,e2)
        end
      end
      --find all static colliders
      searchFilterStatic = Filter.filter({"position","collisionMap"})
      activeStaticColliders = searchFilterStatic:allFit(world)
      for _,static in pairs(activeStaticColliders) do
        future = futurePosition(entity)
        if(checkStatic(future,static.collisionMap.map)) then
          staticCollision(entity,static)
        end
      end
    end
  end
end

function futurePosition(entity)
  future = {
    x = entity.position.x + entity.movement.x,
    y = entity.position.y + entity.movement.y
  }
  return future
end

function collision(e1,e2)
  if e2.collider.type == globals.CollisionEnum.Wall then
    e1.movement = nil
  end
end

function checkStatic(future,cMap)
  return cMap[future.x][future.y] >= 1
end

function staticCollision(e1,e2)
  e1.movement = nil
end