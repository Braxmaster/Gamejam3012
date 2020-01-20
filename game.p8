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
c_dir_none = 0
c_dir_left = 1
c_dir_right = 2
c_dir_up = 3
c_dir_down = 4

c_state_menu = 0
c_state_game = 1
c_state_generate = 2

c_game_state_free = 0
c_game_state_walking = 1
c_game_state_enemies = 2
c_game_state_attacking = 3

c_music_game = 00

c_enemy_sprs = {
  001,
  002,
  003,
  004
}

-- indexes represent directions
c_player_sprs = {
  {spr=019, mirror=true},
  {spr=019, mirror=false},
  {spr=021, mirror=false},
  {spr=017, mirror=false}
}

-- RPS sprites
spr_scissor = 033
spr_rock = 034
spr_paper = 035
spr_beam_hor = 051
spr_beam_vert = 052

items = {
  {
    name = "rock",
    x = 16,
    y = 16
  },
  {
    name = "paper",
    x = 32,
    y = 32
  },
  {
    name = "scissor",
    x = 40,
    y = 40
  }
}

tile_info = {
  wall_tile = 0
}

c_rock_type = 0
c_paper_type = 1
c_scissor_type = 2


c_types = {rock_type, sissor_type, paper_type}

c_cam_speed = 8

c_sprite_wall = 81

-- variables
state = c_state_menu
game_state = c_game_state_free
player = {
  x = 64,
  y = 64,
  next_x = 64,
  next_y = 64,
  dir = c_dir_left,
  rocks = 0,
  papers = 0,
  scissors = 0,
  current_weapon = c_rock_type
}

movement_factor = 0

-->8
-- game logic functions --

function first_generation()
  gen = 0

  last_gen_walls = {}

  for x = 0, 127 do
    add(last_gen_walls, {})
    for y = 0, 63 do
      local has_wall = false
      if rnd(1) > 0.6 then
        mset(x, y, c_sprite_wall)
        has_wall = true
      end
      add(last_gen_walls[x + 1], has_wall)
    end
  end
end

function contains_wall(x, y)
  return mget(x, y) == c_sprite_wall
end

function within_map(x, y)
  return 0 <= x and x <= 127 and 0 <= y and y <= 63
end

function wider_neighbors(x, y)
  local n = 0
  for dx = -2, 2 do
    for dy = -2, 2 do
      if not (dx == 0 and dy == 0) then
        local neighbor_x = x + dx
        local neighbor_y = y + dy
        if within_map(neighbor_x, neighbor_y) and
           last_gen_walls[neighbor_x + 1][neighbor_y + 1] then
          n += 1
        end
      end
    end
  end
  return n
end

function nearest_neighbors(x, y)
  local n = 0
  for dx = -1, 1 do
    for dy = -1, 1 do
      if not (dx == 0 and dy == 0) then
        local neighbor_x = x + dx
        local neighbor_y = y + dy
        if within_map(neighbor_x, neighbor_y) and
           last_gen_walls[neighbor_x + 1][neighbor_y + 1] then
          n += 1
        end
      end
    end
  end
  return n
end

function generation(x, y)
  local nearest = nearest_neighbors(x, y)
  local wider = wider_neighbors(x, y)
  if nearest > 4 or wider < 2 then
    mset(x, y, c_sprite_wall)
  else
    mset(x, y, 0)
  end
end

function map_generation()
  for x = 0, 127 do
    for y = 0, 63 do
      generation(x, y)
    end
  end

  for x = 0, 127 do
    for y = 0, 63 do
      last_gen_walls[x + 1][y + 1] = contains_wall(x, y)
    end
  end
end

function new_cam()
  return {
    x = 4,
    y = 4,
    moving = false,
    dir = c_dir_none
  }
end

-- todo: change numbers if map gets larger
function random_legal_coords()
  local map_width = 32
  local map_height = 32
  cellx = flr(rnd(map_width))
  celly = flr(rnd(map_height))
  while(cell_is_blocked(cellx, celly)) do
    cellx = flr(rnd(map_width))
    celly = flr(rnd(map_height))
  end

  return {
    x = cellx * 8,
    y = celly * 8
  }
end

function random_type()
  return c_types[flr(rnd(#c_types))+1]
end

function random_enemy_spr()
  return c_enemy_sprs[flr(rnd(#c_enemy_sprs))+1]
end

function new_enemy()
  coords = random_legal_coords()
  return {
    x = coords.x,
    y = coords.y,
    next_x = coords.x,
    next_y = coords.y,
    type = random_type(),
    spr = random_enemy_spr()
  }
end

function _init()
  state = c_state_menu
  current_game = c_game_0
  cam = new_cam()

  enemies = {}
  for i = 1, 5 do
    add(enemies, new_enemy())
  end
end

function _update()
  if state==c_state_game then
    update_game()
  elseif state==c_state_menu then
    update_menu()
  elseif state==c_state_generate then
    update_generate()
  end
end

function update_generate()
  gen += 1
  map_generation()
  if gen == 5 then
   init_game()
 end
end

function update_game()
  if (btnp(0) or btnp(1) or btnp(2) or btnp(3) or btnp(4) or btnp(5)) and game_state == c_game_state_free then
    update_player()
    check_if_on_item()
  elseif game_state == c_game_state_walking then
    move_player()
  elseif game_state == c_game_state_enemies then
    foreach(enemies, move_dude)
    if enemies_moved() then
      game_state = c_game_state_free
    end
  elseif game_state == c_game_state_attacking then
    game_state = c_game_state_free -- temporary, change when adding attack animation
    update_enemies()
  end
  update_cam()
end

function update_player()
  if btnp(0) and not pixel_is_blocked(player.x - 8, player.y) then
    game_state = c_game_state_walking
    player.next_x -= 8
    player.dir = c_dir_left
  elseif btnp(1) and not pixel_is_blocked(player.x + 8, player.y) then
    game_state = c_game_state_walking
    player.next_x += 8
    player.dir = c_dir_right
  elseif btnp(2) and not pixel_is_blocked(player.x, player.y - 8) then
    game_state = c_game_state_walking
    player.next_y -= 8
    player.dir = c_dir_up
  elseif btnp(3) and not pixel_is_blocked(player.x, player.y + 8) then
    game_state = c_game_state_walking
    player.next_y += 8
    player.dir = c_dir_down
  elseif btn(4) then
    game_state = c_game_state_attacking
    throw_projectile()
  elseif btn(5) then
    player.current_weapon = (player.current_weapon + 1) % 3
  end
end

function move_player()
  move_dude(player)
  if player.next_x == player.x and player.next_y == player.y then
    game_state = c_game_state_enemies
    update_enemies()
  end
end


function check_if_on_item()
  for i in all(items) do
    if player.x == i.x and player.y == i.y then
      if i.name == "rock" then
        player.rocks += 1
      end
      if i.name == "paper" then
        player.papers += 1
      end
      if i.name == "scissor" then
        player.scissors += 1
      end
      del(items, i)
    end
  end
end

function update_enemies()
  foreach(enemies, update_enemy)
end

function update_enemy(enemy)
  x_dist = player.x - enemy.x
  y_dist = player.y - enemy.y
  tmp ={
  x = enemy.x,
  y = enemy.y
  }
  if abs(x_dist) > abs(y_dist) then
    if x_dist > 0 then tmp.x += 8 else tmp.x -= 8 end
  else
    if y_dist > 0 then tmp.y += 8 else tmp.y -= 8 end
  end
  if not pixel_is_blocked(tmp.x, tmp.y) then
     enemy.next_x = tmp.x
     enemy.next_y = tmp.y
  end
end

function move_dude(dude)
  move_x = dude.next_x - dude.x
  move_y = dude.next_y - dude.y
  if move_x > 0 then
    dude.x += 2
  elseif move_x < 0 then
    dude.x -= 2
  elseif move_y > 0 then
    dude.y += 2
  elseif move_y < 0 then
    dude.y -= 2
  end
end

function enemies_moved()
  for enemy in all(enemies) do
    if not enemy_moved(enemy) then
      return false
    end
  end
  return true
end
  
function enemy_moved(enemy)
  isDone = false
  if enemy.next_x == enemy.x and enemy.next_y == enemy.y then 
    isDone = true
  end
  return isDone
end

function update_menu()
 if btn(4) then
   first_generation()
   state = c_state_generate
 end
end

function init_game()
  music(c_music_game)
  state = c_state_game
end

-- checks if the x, y pixel position is blocked by a wall
function pixel_is_blocked(x, y)
  cellx = flr(x / 8)
  celly = flr(y / 8)
  return cell_is_blocked(cellx, celly)
end

function cell_is_blocked(cellx, celly)
  sprite = mget(cellx, celly)
  return fget(sprite, tile_info.wall_tile)
end

function update_cam()
  cam_transition_start()

  if cam.moving then
    move_cam()
  end

  cam_transition_stop()
end

function cam_transition_start()
  if not cam.moving then
    if player.x < cam.x then
      cam.moving = true
      cam.dir = c_dir_left
    elseif player.x >= cam.x + 124 then
      cam.moving = true
      cam.dir = c_dir_right
    elseif player.y < cam.y + 8 then
      cam.moving = true
      cam.dir = c_dir_up
    elseif player.y >= cam.y + 124 then
      cam.moving = true
      cam.dir = c_dir_down
    end
  end
end

function move_cam()
  if cam.dir == c_dir_left then
    cam.x -= c_cam_speed
  elseif cam.dir == c_dir_right then
    cam.x += c_cam_speed
  elseif cam.dir == c_dir_up then
    cam.y -= c_cam_speed
  elseif cam.dir == c_dir_down then
    cam.y += c_cam_speed
  end
end

function cam_transition_stop()
  if cam_at_grid_point() then
    cam.moving = false
  end
end

function throw_projectile()
  if player.current_weapon == 0 and player.rocks > 0 then
    hit = throw(player.current_weapon)
    player.rocks -= 1
  elseif player.current_weapon == 1 and player.papers > 0 then
    throw(player.current_weapon)
    player.papers -= 1
  elseif player.current_weapon == 2 and player.scissors > 0 then
    throw(player.current_weapon)
    player.scissors -= 1
  end
end

--finds a hit on an enemy or a wall.
--TODO: refactor & add enemy hit detection
function throw(item_num)
 hit = 2
 if player.dir == c_dir_right then
  hit = player.x + 8
  while not pixel_is_blocked(hit, player.y) do
   hit += 8
  end
  return {x = hit, y = player.pos}
 elseif player.dir == c_dir_left then
  hit = player.x - 8
  while not pixel_is_blocked(hit, player.y) do
   hit -= 8
  end
  return {x = hit, y = player.pos}
 elseif player.dir == c_dir_up then
  hit = player.y - 8
  while not pixel_is_blocked(player.x, hit) do
   hit -= 8
  end
  return {x = player.x, y = hit}
 else
  hit = player.y + 8
  while not pixel_is_blocked(player.x, hit) do
   hit += 8
  end
  return {x = player.x, y = hit}
 end
 player.scissors = hit
end

function cam_at_grid_point()
  return (cam.x - 4) % 120 == 0 and (cam.y - 4) % 112 == 0
end
-->8
-- draw functions --

function _draw()
  cls()
  if state==c_state_menu then
    print("welcome to game", 10, 10)
    if pixel_is_blocked(9, 9) then
       print("collision is broken", 10, 20)
    end
  elseif state==c_state_game then
    draw_game()
  elseif state==c_state_generate then
    map(0, 0, 0, 0, 128, 128)
  end
end

function draw_game()
  camera(cam.x, cam.y)
  map(0, 0, 0, 0, 128, 128)

  draw_player()
  draw_menu()
  draw_items()
  foreach(enemies, draw_enemy)
  if btn(4) then
    draw_beam()
  end
end

function draw_enemy(enemy)
  spr(enemy.spr, enemy.x, enemy.y)
end

function draw_player()
  local spr_data = c_player_sprs[player.dir]
  spr(spr_data.spr, player.x, player.y, 1, 1, spr_data.mirror)
end

function draw_beam()
local x = player.x
local y = player.y

if player.dir == 1 then
      sspr(24, 24, movement_factor, 8, x-movement_factor, y)
      x -= 8
    elseif player.dir == 2 then
      x += 8
      sspr(31-movement_factor, 24, movement_factor, 8, x, y)
    elseif player.dir == 3 then
      sspr(32, 24, 8, movement_factor, x, y-movement_factor)
      y -= 8
    elseif player.dir == 4 then
      y += 8
      sspr(32, 31-movement_factor, 8, movement_factor, x, y)
    end

local times = 0

  while times < 10 do
    if player.dir == 1 then
      sspr(24, 24, 8, 8, x - movement_factor, y)
      x -= 8
    elseif player.dir == 2 then
      sspr(24, 24, 8, 8, x + movement_factor, y)
      x += 8
    elseif player.dir == 3 then
      sspr(32, 24, 8, 8, x, y - movement_factor)
      y -= 8
    elseif player.dir == 4 then
      sspr(32, 24, 8, 8, x, y + movement_factor)
      y += 8
    end
  times += 1
  end
  movement_factor += 1
  if movement_factor >= 8 then
    movement_factor = 0
  end
end

function draw_menu()
  local spr_highlight = 005
  rectfill(cam.x, cam.y, cam.x + 128, cam.y + 9, 0)
  if player.current_weapon == 0 then
    spr(spr_highlight, cam.x + 0, cam.y + 1)
  end
  if player.current_weapon == 1 then
    spr(spr_highlight, cam.x + 16, cam.y + 1)
  end
  if player.current_weapon == 2 then
    spr(spr_highlight, cam.x + 32, cam.y + 1)
  end
  spr(spr_rock, cam.x + 0, cam.y + 1)
  print(tostr(player.rocks), cam.x + 10, cam.y + 2, 7)
  spr(spr_paper, cam.x + 16, cam.y + 1)
  print(tostr(player.papers), cam.x + 26, cam.y + 2, 7)
  spr(spr_scissor, cam.x + 31, cam.y + 1)
  print(tostr(player.scissors), cam.x + 41, cam.y + 2, 7)
end

function draw_items()
  for i in all(items) do
    if i.name == "rock" then
      spr(spr_rock, i.x, i.y)
    end
    if i.name == "scissor" then
      spr(spr_scissor, i.x, i.y)
    end
    if i.name == "paper" then
      spr(spr_paper, i.x, i.y)
    end
  end
end

__gfx__
00000000099990000999999008880000066666600aaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000999990999999908855550066666666a000000a00000000000000000000000000000000000000000000000000000000000000000000000000000000
0070070099999990999555558555555066666ff6a000000a00000000000000000000000000000000000000000000000000000000000000000000000000000000
000770000995555599f55f55855666506666f1f6a000000a00000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700000955f5509fffff00555655066fffff0a000000a00000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700002222200cccccc00555555063333330a000000a00000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000002222200cccccc00555555003333330a000000a00000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000020002000c00c0005000050030000300aaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000022220000000000002222000000000000222200000000000000cc000090909000000000000000000000000000000000000000000000000000000000
000000000eeeeee0002222000eeeeee0002222000eeeeee000222200000c5c000099999000000000000000000000000000000000000000000000000000000000
00000000e22cfc200eeeeee002e22cf00eeeeee002222e200eeeeee0000ccc9907fffff000000000000000000000000000000000000000000000000000000000
00000000e222f220e22cfc200e2222f002e22cf0022222e002222e20c0cccc00007ffff000000000000000000000000000000000000000000000000000000000
0000000002222220e222f220022222200e2222f002222220022222e0ccccccc000c7777000000000000000000000000000000000000000000000000000000000
0000000002f2222f02f2222f0222f2200222f2200222222002222220ccccccc000ccccc000000000000000000000000000000000000000000000000000000000
000000000222222002222220022222200222222002222220022222200cccccc000ccccc000000000000000000000000000000000000000000000000000000000
00000000020000200200002002000020020000200200002002000020000909000040004000000000000000000000000000000000000000000000000000000000
00000000099909990dddd00000007700999009990dddd00000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000090909090ddd6dd000777770911991190ddd6dd000077877000000000000000000000000000000000000000000000000000000000000000000000000
0000000009090909dd666ddd0777777791899819dd866d8d00777770000000000000000000000000000000000000000000000000000000000000000000000000
0000000000996990d6dddd5d7777777709999990d618d81d07877700000000000000000000000000000000000000000000000000000000000000000000000000
00000000000516006d6dddd567777776005566006d6dddd577776000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000056600d6ddd5d50677776005500660d887888577666667000000000000000000000000000000000000000000000000000000000000000000000000
00000000000566000d6ddd5000677600550000660d78875007776670000000000000000000000000000000000000000000000000000000000000000000000000
000000000000600000dd5500000660005000000600dd550000077700000000000000000000000000000000000000000000000000000000000000000000000000
00000000999000000000000006666000067777606666666000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000900900000000000067777666067777767777777600000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000999955000000000077777777067777767777777600000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000515550000000077777777677777767777777600000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000666660000000077777777677777767777777600000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000999966000000000077777777677777607777777600000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000900900000000000066677776677777607777777600000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000999000000000000000066660067777606666666000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000055d57d555555555555555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000005555555555d67d5555d67d55000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000056d67d65d5ddddd55ddddd5d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000056d67d6555d67d5555d67d55000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000056d67d6575d67d5555d67d57000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000056d67d65d5ddddd55ddddd5d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000005555555555d67d5555d67d55000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000055d67d5555d67d5555d67d55000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9aa33aa95555555555d67d5555d67d55555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9aaaaaa95566665555d67d5555d67d55556666550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a9aaaa9ad5dddd5dd5ddddd55ddddd5d95dddd590000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aa9999aa5566665555d67d5555d67d55a566665a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aa9999aa7566665775d67d5555d67d57a566665a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a9aaaa9ad5dddd5dd5ddddd55ddddd5d95dddd590000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9aaaaaa95566665555d67d5555d67d55556666550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9aa33aa9555555555555555555555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000101010000000000000000000000000001010101000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
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
00 06094344
00 07424344
00 06094344
02 08424344

