rangedweapons={}
local modpath = minetest.get_modpath(minetest.get_current_modname())

dofile(modpath.."/weapons.lua")
dofile(modpath.."/api.lua")


--dofile(modpath.."/generator.lua")




rangedweapons.api.register_weapons()

rangedweapons.api.register_ammo()




function get_ammo_count(player, ammo_name)
  if player then
    local inv = player:get_inventory()
    print(player:get_player_name())
    print(ammo_name)
    --print(minetest.serialize(inv:get_list("main")))
    return inv:get_item_count(ammo_name)
  end
  return 0
end

function has_ammo(player, ammo_name)
  local res=false
  if player then
    local inv = player:get_inventory()
    print(player:get_player_name())
    print(ammo_name)
    if inv:contains_item("main", ammo_name) then res=true end
  end
  return res
end


function clock() --faster then os.time
return minetest.get_us_time()/ 10000000
end
function on_use(itemstack, player, pointed_thing)
    local player_name = player:get_player_name()
    -- Check if the item being used is a craftitem
    if rangedweapons.api.is_weapon(itemstack) then
        -- Do something
        local pos = player:get_pos()
        local dir = player:get_look_dir()
        
        local gun_name = itemstack:get_name()
        gun_name = gun_name:sub(string.len("rangedweapons:") + 1)
        sound=string.gsub(rangedweapons.guns[gun_name].guntype, " ", "_")
        print(sound)
        gun_record=rangedweapons.guns[gun_name]
        ammo_name=gun_record.Ammunition
        --print(ammo_type)
       if rangedweapons.api.shot_time[player_name] then
        if (clock()-rangedweapons.api.shot_time[player_name])>(gun_record.rate_of_fire*0.01) then
         rangedweapons.api.shot_time[player_name]=clock()
         
          if has_ammo(player, ammo_name) then
           rangedweapons.api.remove_ammo(player, ammo_name)
           rangedweapons.api.shot_by_player(player,gun_name)
           minetest.sound_play("rangedweapons_"..sound, { pos = pos, gain = 1.0, max_hear_distance = 32 })
           rangedweapons.api.shut_smoke(player)
         
          else
           minetest.sound_play("rangedweapons_empty", { pos = pos, gain = 1.0, max_hear_distance = 32 })
          end
        end
      else
       rangedweapons.api.shot_time[player_name]=clock()
      end
    end
end

minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do 
        local itemstack = player:get_wielded_item()
        local controls = player:get_player_control()
	if controls.LMB then
         on_use(itemstack, player)
        end
    end
end)
