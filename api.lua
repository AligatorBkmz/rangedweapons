local BODYSHOT=1
local HEADSHOT=2
rangedweapons.hits={}
rangedweapons.api={}
rangedweapons.api.shot_time={}
--
function rangedweapons.api.get_collision_pos(pos1, pos2)
    local dir = vector.direction(pos1, pos2)
    local step = vector.divide(dir, vector.length(dir))
    local current_pos = vector.new(pos1)
    local max_distance = vector.distance(pos1, pos2)
    local distance_traveled = 0

    while distance_traveled < max_distance do
        if minetest.get_node(current_pos).name ~= "air" then
            print(current_pos)
            return current_pos
        end
        current_pos = vector.add(current_pos, step)
        distance_traveled = distance_traveled + vector.length(step)
    end

    return current_pos -- if no non-air blocks are found
end

local FAST_COLLISION_DISTANCE=0
function try_player_hit(player,target_player)
  local res=0
  FAST_COLLISION_DISTANCE=0
                        if target_player then
		          local target_player_pos={x=target_player:get_pos().x,y=target_player:get_pos().y,z=target_player:get_pos().z} 
		          local target_player_head_pos={x=target_player_pos.x,y=target_player_pos.y+1.2,z=target_player_pos.z}
		          local target_player_body_pos={x=target_player_pos.x,y=target_player_pos.y+0.3,z=target_player_pos.z}
		          
		          local player_pos = player:get_pos()
		          local distance=vector.distance(player_pos,target_player_pos)
			  local look_dir =   player:get_look_dir()
			  local displacement = vector.multiply(look_dir, distance)
			  local new_pos = vector.add(player_pos, displacement)
			  local bullet_pos ={x=new_pos.x,y=new_pos.y+1,z=new_pos.z}
			  --local bullet_distance=vector.distance(bullet_pos,target_player_pos)
			  local bullet_distance_to_head=vector.distance(bullet_pos,target_player_head_pos)
			  local bullet_distance_to_body=vector.distance(bullet_pos,target_player_body_pos)
			  --minetest.chat_send_all("distance="..tostring(bullet_distance))
			  if bullet_distance_to_body<0.6 then
			   --minetest.env:add_node({x=new_pos.x,y=new_pos.y+1,z=new_pos.z}, {name="default:dirt"})
			   --minetest.chat_send_all("bodyshot")
			   res=BODYSHOT
			  end
			  if bullet_distance_to_head<0.3 then
			   --minetest.env:add_node({x=new_pos.x,y=new_pos.y+1,z=new_pos.z}, {name="maple:leaves"})
			   --minetest.chat_send_all("headshot")
			   res=HEADSHOT
			  end
			  if res~=0 then
			   local collision_pos=rangedweapons.api.get_collision_pos({x=player_pos.x,y=player_pos.y+1.5,z=player_pos.z},{x=bullet_pos.x,y=bullet_pos.y+0.5,z=bullet_pos.z})
			   local collision_distance=vector.distance(player_pos,collision_pos)
			   --minetest.chat_send_all("collis= "..tostring(collision_distance-distance))
			   --minetest.chat_send_all("cd="..tostring(collision_distance))
			   --minetest.chat_send_all("d="..tostring(distance))
			   FAST_COLLISION_DISTANCE=distance
			   if collision_distance<distance then res=0  FAST_COLLISION_DISTANCE=collision_distance end
			  end
		        end
  return res
end

function rangedweapons.api.hit_player(player,target_player)
  target_player:punch(player, 1.0, {
    full_punch_interval=1.0,
    damage_groups={fleshy=1}
  }, nil)
--end
end

function rangedweapons.api.remove_ammo(player, ammo_name)
  local inv = player:get_inventory()
  inv:remove_item("main", ammo_name)
end

function rangedweapons.api.register_weapons()
  for weapon, stats in pairs(rangedweapons.guns) do
    local damage = rangedweapons.get_gun_damage(stats)
    minetest.register_craftitem("rangedweapons:"..weapon, {
      stack_max = 1,
      wield_scale = {x=2.5, y=2.5, z=1.5},
      description = core.colorize("#35cdff", weapon.."\n")..
                    core.colorize("#FFFFFF", "Ranged damage: "..tostring(damage).."\n")..
                    core.colorize("#FFFFFF", "Accuracy: "..tostring(stats.critical_chance*100).."%\n")..
                    core.colorize("#FFFFFF", "Mob knockback: "..tostring(stats.bullet_velocity/10).."\n")..
                    core.colorize("#FFFFFF", "Critical chance: "..tostring(stats.critical_chance*100).."%\n")..
                    core.colorize("#FFFFFF", "Critical damage: "..tostring(stats.critical_damage).."\n")..
                    core.colorize("#FFFFFF", "Ammunition: "..stats.Ammunition.."\n")..
                    core.colorize("#FFFFFF", "Rate of fire: "..tostring(stats.rate_of_fire).."\n")..
                    core.colorize("#FFFFFF", "Gun type: "..stats.guntype.."\n")..
                    core.colorize("#FFFFFF", "Bullet velocity: "..tostring(stats.bullet_velocity)),
      range = 0,
      inventory_image = "rangedweapons_"..weapon..".png",
    })
    print(weapon)
  end
end

function rangedweapons.api.register_ammo()
local ammoList = rangedweapons.get_ammo_list()
print(ammoList)
for _, ammoName in ipairs(ammoList) do
    local ammoId = string.sub(ammoName, string.find(ammoName, ":") + 1)
    ammoId = string.gsub(ammoId, ":", "_")
    minetest.register_craftitem(ammoName, {
        description = ammoId .. " Ammo",
        inventory_image = "rangedweapons_" .. ammoId .. ".png",
    })
end
end

function rangedweapons.api.is_weapon(itemstack)
    local def = itemstack:get_definition()
    local name=itemstack:get_name()
    local res=def and def.mod_origin == "rangedweapons"
    if res then 
     if string.find(name, ":ammo_") then res=false end
    end
    return res
end

-- define a function to create a laser particle
function rangedweapons.api.draw_ammo(pos1, pos2)
    local particle_def = {
        -- set particle texture to "blank.png" to make the particle invisible
        texture = "rangedweapons_ray_red.png",
        -- set particle size
        size = 1,
        -- set particle velocity to the direction from pos1 to pos2
        velocity = vector.direction(pos1, pos2),
        -- set particle acceleration to (0,0,0) so it won't be affected by gravity
        acceleration = {x=0, y=0, z=0},
        -- set particle expiration time
        expirationtime = 0.1,
        -- set particle glow to full brightness
        glow = 15,
        -- set particle collision to "false" so it doesn't collide with anything
        collisiondetection = false,
        -- set particle object collision to "false" so it doesn't collide with objects
        object_collision = false,
        minpos=pos1,
        maxpos=pos2,
        time=1
    }
    -- spawn particle at pos1
    minetest.add_particlespawner(particle_def)
end

function rangedweapons.api.draw_laser(pos1, pos2)
    
    local vec = vector.direction(pos1, pos2)
    local length = vector.distance(pos1, pos2)
    local step = 0.2
    local num_particles = length / step
    local pos = vector.new(pos1)
    local particle_def = {
        velocity = vector.new(0, 0, 0),
        acceleration = vector.new(0, 0, 0),
        expirationtime = 0.2,
        size = 2,
        collisiondetection = false,
        collision_removal = false,
        vertical = false,
        texture = "rangedweapons_lasershot.png",
        glow = 14,
        object_collision = false,
        player_collision = false,
        collision_removal = false,
        glow = 14,
        color = {r=255, g=0, b=0, a=255}
    }
    for i = 1, num_particles do
        minetest.add_particle(particle_def)
        pos = vector.add(pos, vector.multiply(vec, step))
        particle_def.pos = pos
    end
end

function rangedweapons.api.shut_smoke(player)
local pos = player:get_pos()
local dir = player:get_look_dir()
local smoke_pos = vector.add(pos, vector.multiply(dir, 2))
         smoke_pos ={x=smoke_pos.x,y=smoke_pos.y+2,z=smoke_pos.z}
            -- Add the smoke effect
            minetest.add_particlespawner({
                amount = 1,
                time = 0.1,
                minpos = smoke_pos,
                maxpos = smoke_pos,
                minvel = {x = 0, y = 0, z = 0},
                maxvel = {x = 0, y = 0, z = 0},
                minacc = {x = 0, y = 0, z = 0},
                maxacc = {x = 0, y = 0, z = 0},
                minexptime = 0.5,
                maxexptime = 1,
                minsize = 6,
                maxsize = 8,
                collisiondetection = true,
                collision_removal = true,
                object_collision = true,
                texture = "tnt_smoke.png",
                glow = 10,
                animation = {
                    type = "vertical_frames",
                    aspect_w = 8,
                    aspect_h = 8,
                    length = 2
                }
            })
end
function rangedweapons.api.shut_blood(player)
local pos = player:get_pos()
local dir = player:get_look_dir()
local smoke_pos = pos
         smoke_pos =pos
            -- Add the smoke effect
            minetest.add_particlespawner({
                amount = 1,
                time = 0.1,
                minpos = smoke_pos,
                maxpos = smoke_pos,
                minvel = {x = 0, y = 0, z = 0},
                maxvel = {x = 0, y = 0, z = 0},
                minacc = {x = 0, y = 0, z = 0},
                maxacc = {x = 0, y = 0, z = 0},
                minexptime = 0.5,
                maxexptime = 1,
                minsize = 9,
                maxsize = 12,
                collisiondetection = true,
                collision_removal = true,
                object_collision = true,
                texture = "rangedweapons_blood.png",
                glow = 10,
                animation = {
                    type = "vertical_frames",
                    aspect_w = 12,
                    aspect_h = 12,
                    length = 2
                }
            })
end
function rangedweapons.api.hit_player(target_player,damage)
	local hp=target_player:get_hp()
	local res=true
	if (hp-damage)>0 then 
	 target_player:set_hp(hp-damage)
	 res=true
	else
	 target_player:set_hp(0)
	 res=false
	end
 return res
end

function rangedweapons.shot_effects(player, target_pos, gun_record)
  local pos1 = player:get_pos()
  local player_pos = player:get_pos()

  local distance = FAST_COLLISION_DISTANCE
  if distance == 0 then
    distance = 100
  end

  if target_pos then 
    pos2 = target_pos
    distance = FAST_COLLISION_DISTANCE
  else
    local look_dir = player:get_look_dir()
    local displacement = vector.multiply(look_dir, distance)
    pos2 = vector.add(player_pos, displacement)
  end

  if distance == 100 then
    local collision_pos = rangedweapons.api.get_collision_pos({x=pos1.x, y=pos1.y+1.5, z=player_pos.z}, {x=pos2.x, y=pos2.y+1.5, z=pos2.z})
    distance = vector.distance({x=pos1.x, y=pos1.y+1, z=pos1.z}, {x=collision_pos.x, y=collision_pos.y+1, z=collision_pos.z})
    local look_dir = player:get_look_dir()
    local displacement = vector.multiply(look_dir, distance)
    pos2 = vector.add(player_pos, displacement)
  end

  pos1 = {x=pos1.x, y=pos1.y+1.25, z=pos1.z}
  pos2 = {x=pos2.x, y=pos2.y+1.25, z=pos2.z}
  
  local guntype=gun_record.guntype
  if guntype=="energy weapon" then
    rangedweapons.api.draw_laser(pos1, pos2)
  end
 
  if guntype=="laser shotgun" then
    rangedweapons.api.draw_laser(pos1, pos2)
  end
 
  if guntype=="laser rifle" then
    rangedweapons.api.draw_laser(pos1, pos2)
  end
 
  if guntype=="assault rifle" then
    rangedweapons.api.draw_ammo(pos1, pos2)
  end
  
end

function rangedweapons.api.shot_by_player(player,gun_name)
 
   local player_name=player:get_player_name()
   local gun_record=rangedweapons.guns[gun_name]
   local has_target=false
 

 
 for _,target_player in pairs(minetest.get_connected_players()) do 
   local target_player_name = target_player:get_player_name()
   if target_player_name~=player:get_player_name() then
   if target_player~=nil then
     
     local is_hit=try_player_hit(player,target_player)
     if is_hit~=0 then
        has_target=true
        local body_pos_name="body"
        if is_hit==2 then body_pos_name="head" end
       
        rangedweapons.api.shut_blood(target_player)
              
        
        rangedweapons.shot_effects(player,target_player:get_pos(),gun_record)
       
        damage = rangedweapons.get_gun_damage(gun_record)*is_hit
        if rangedweapons.api.hit_player(target_player,damage) then
         minetest.chat_send_all("damage"..tostring(damage))
        else
          minetest.chat_send_all(player_name.." killed from "..gun_name.." player "..target_player_name.." on "..body_pos_name)
        end
       
        --hit_player(player,target_player)
        rangedweapons.hits[target_player_name]=is_hit --API info about player last hit
        if de_dust~=nil then
          de_dust.punch(target_player,is_hit) --compatiblity with de_dust mod
        end
     end
   end
   end
 end
 
 if has_target==false then
  rangedweapons.shot_effects(player,nil,gun_record)
 end

end


