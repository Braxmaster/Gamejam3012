pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- cool game --
-- by fabian, jens, branne --
--    and jacob --

-- "why then the world's mine
--  oyster,
--  which i with sword will
--  open."

-- constants and variables

-- constants
c_state_menu=0
c_state_game=1

c_music_game=00

tile_info = {free_tile = 0,
             wall_tile = 1
}

 rock_type = 0
 sissor_type = 1
 paper_type = 2

-- variables
state = c_state_menu
player = {x = 64, y = 64, spr = 001}
enemy = {x = 32, y = 32, type = rock_type, spr = 003}
enemies = {enemy}


-->8
-- game logic functions --

function _init()
  state = c_state_menu
  current_game = c_game_0
end

function _update()
  if state==c_state_game then
    update_game()
  elseif state==c_state_menu then
    update_menu()
  end
end


function update_game()
  if btnp(0) or btnp(1) or btnp(2) or btnp(3) or btnp(4) or btnp(5) then
    update_player()
    update_world()
  end
end

function update_player()
  if btn(0) then
    player.x -= 8
  end
  if btn(1) then
    player.x += 8
  end
  if btn(2) then
    player.y -= 8
  end
  if btn(3) then
    player.y += 8
  end
end

function update_world()
  foreach(enemies, update_enemy)
end

function update_enemy(enemy) 
  enemy.x += rnd(2)*8 - 8
  enemy.y += rnd(2)*8 - 8
end

function update_menu()
 if btn(4) then
   init_game()
 end
end

function init_game()
  music(c_music_game)
  state = c_state_game
end

-- checks if the x, y pixel position is blocked by a wall
function pixel_is_blocked(x, y)
   cellx = flr(x / 16)
   celly = flr(y / 16)
   sprite = mget(cellx, celly)
   print(fget(sprite, tile_info.wall_tile), 10, 30)
   return fget(sprite, tile_info.wall_tile)
end

-->8
-- draw functions --

function _draw()
  cls()
  map(0, 0, 0)
  if state==c_state_menu then
    print("welcome to game", 10, 10)
    if pixel_is_blocked(5, 7) then
       print("tile x:5 y:7 is blocked", 10, 20)
    else
       print("something is wrong", 10, 20)
    end
  elseif state==c_state_game then
    print("now in game", 20, 20)
    spr(player.spr, player.x, player.y)
    spr(enemy.spr, enemy.x, enemy.y)
  end
end
__gfx__
00000000099990000999999008880000066666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000009999909999999088555500666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070070099999990999555558555555066666ff60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000770000995555599f55f55855666506666f1f60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700000955f5509fffff00555655066fffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700002222200cccccc005555550633333300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000002222200cccccc005555550033333300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000020002000c00c0005000050030000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000055550000000000005555000000000000555500000000000000cc000000000000000000000000000000000000000000000000000000000000000000
00000000055555500055550005555550005555000555555000555500000c5c000000000000000000000000000000000000000000000000000000000000000000
00000000055c6c500555555005555c60055555500555555005555550000ccc990000000000000000000000000000000000000000000000000000000000000000
0000000005556550055c6c500555556005555c600555555005555550c0cccc000000000000000000000000000000000000000000000000000000000000000000
00000000055555500555655005555550055555600555555005555550ccccccc00000000000000000000000000000000000000000000000000000000000000000
00000000055555500555555005555550055555500555555005555550ccccccc00000000000000000000000000000000000000000000000000000000000000000
000000000555555005555550055555500555555005555550055555500cccccc00000000000000000000000000000000000000000000000000000000000000000
00000000050000500500005005000050050000500500005005000050000909000000000000000000000000000000000000000000000000000000000000000000
00000000099909990dddd00000007700999009990dddd00000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000090909090ddd6dd000777770911991190ddd6dd000077877000000000000000000000000000000000000000000000000000000000000000000000000
0000000009090909dd666ddd0777777791899819dd866d8d00777770000000000000000000000000000000000000000000000000000000000000000000000000
0000000000996990d6dddd5d7777777709999990d618d81d07877700000000000000000000000000000000000000000000000000000000000000000000000000
00000000000516006d6dddd567777776005566006d6dddd577776000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000056600d6ddd5d50677776005500660d887888577666667000000000000000000000000000000000000000000000000000000000000000000000000
00000000000566000d6ddd5000677600550000660d78875007776670000000000000000000000000000000000000000000000000000000000000000000000000
000000000000600000dd5500000660005000000600dd550000077700000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777888888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777888888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777888888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777888888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777888888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777888888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777888888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777888888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
4141414141414141414141414141414100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4140404040404040404040404040404100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4140404040404040404040404040404100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4140404040404040404040404040404100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4140404040404040404040404040404100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4140404040404040404040404040404100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4140404040404040404040404040404100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4140404040404040404040404040404100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4141414141414141414141414141414100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011400000707000000000000000007070000000000000000070700707400000000000000000000000000000007070000000000000000070700000000000000000707007074000000000002070020740000000000
01140000131400000015140000001614000000161401613016120161150000000000000000000000000000001314000000151400000016140000001a1401a1301a1201a115181401813018120181150000000000
011400001a140000001c140000001d140000001d1401d1301d1201d1150000000000000000000000000000001a140000001c140000001d14000000211402113021120211101f1401f1301f1201f1100000000000
011400002414024144221402214421140211441f1401f1301f1201f1150000000000000000000000000000001a1401a1441c1401c1441d1401d144211402113021120211151f1401f1301f1201f1150000000000
011400002414024144221402214421140211441f1401f1301f1201f115000000000000000000000000000000221402214421140211441f1401d144211402113021120211151f1401f1301f1201f1150000000000
01140000050700000000000000000507000000000000000007070070740000000000000000000000000000000c070000000000000000090700000000000000000507005074000000000000000000000000000000
011400000507000000000000000005070000000000000000070700707400000000000000000000000000000002070000000000002070000000000005070050500504005030050200501500000000000000000000
011400000507000000000000000005070000000000000000070700707400000000000000000000000000000002070000000000002070000000000000070000500004000030000200001500000000000000000000
011400002112221132211422113221122211152112221135221222213222142221422214222132221222211528122281322612226132241222413221122211322113221132211322113221132211322112221115
011400002414024144221402214421140211441f1401f1301f1201f115000000000000000000000000000000221402214421140211441f1401d144211402113021120211151f1401f1301f1201f1152112221135
__music__
00 01024344
00 01024344
00 01034344
00 01034344
00 01044344
00 01054344
00 01044344
00 010a4344
01 06094344
00 07424344
00 06094344
02 08424344
