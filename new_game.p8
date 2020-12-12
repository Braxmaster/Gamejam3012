pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- cool game --
-- by fabian (mostly) --

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
c_state_generate_done = 3

c_game_state_free = 0
c_game_state_walking = 1

c_music_game = 00
c_music_generate = 20

c_total_sword_time = 16

-- indexes represent directions
c_player_sprs = {
  {spr=019, mirror=true},
  {spr=019, mirror=false},
  {spr=021, mirror=false},
  {spr=017, mirror=false}
}

c_enemy_skel_sprs= {
  {spr=012, mirror=true},
  {spr=012, mirror=false},
  {spr=012, mirror=false},
  {spr=012, mirror=false}
}

c_sprites_sword_hori = {
  033,
  034,
}
c_sprites_sword_vert = {
  049,
  050,
}

tile_info = {
  wall_tile = 0
}

c_cam_speed = 8

c_sprite_wall = 81
c_sprite_floor = 96

c_sprite_wall_nw = 87
c_sprite_wall_north = 88
c_sprite_wall_ne = 89
c_sprite_wall_west = 103
c_sprite_wall_mid = 104
c_sprite_wall_east = 105
c_sprite_wall_se = 121
c_sprite_wall_south = 120
c_sprite_wall_sw = 119
c_sprite_wall_we = 106
c_sprite_wall_ns = 92
c_sprite_wall_swe = 122
c_sprite_wall_nwe = 90
c_sprite_wall_nse = 93
c_sprite_wall_nsw = 91
c_sprite_wall_nswe = 94

c_enemy_skel_type = 0

-- variables
state = c_state_menu
game_state = c_game_state_free
player = {
  x = 64,
  y = 64,
  next_x = 64,
  next_y = 64,
  dir = c_dir_left,
  sprs = c_player_sprs,
  moving = false,
  speed = 2,
  sword = {
    time = 0,
    x = 0,
    y = 0,
    sprs = c_sprites_sword_hori,
  }
}

enemies = {}

-->8
-- game logic functions --

function first_generation()
  gen = 0
  gen_x = 0

  last_gen_walls = {}

  for x = 0, 121 do
    add(last_gen_walls, {})
    for y = 0, 55 do
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
  return 0 <= x and x <= 121 and 0 <= y and y <= 55
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
  for y = 0, 55 do
    generation(gen_x, y)
  end
end

c_filler_no_group = -1

function empty_map_groups()
  local map_groups = {}

  for x = 0, 121 do
    add(map_groups, {})
    for y = 0, 55 do
      add(map_groups[x + 1], c_filler_no_group)
    end
  end

  return map_groups
end

function traverse(visited, upcoming, x, y)
  if within_map(x, y) and not contains_wall(x, y) and not visited[x+1][y+1] then
    add(upcoming, {x = x, y = y})
    visited[x+1][y+1] = true
  end
end

function empty_visited()
  local visited = {}

  for x = 0, 121 do
    add(visited, {})
    for y = 0, 55 do
      add(visited[x + 1], false)
    end
  end

  return visited
end

function fill_group(current_group, map_groups, start_x, start_y)
  local visited = empty_visited()
  local upcoming = {{x = start_x, y = start_y}}
  visited[start_x+1][start_y+1] = true

  while(#upcoming > 0) do
    local current = upcoming[1]
    local x = current.x
    local y = current.y
    del(upcoming, current)

    map_groups[x+1][y+1] = current_group

    traverse(visited, upcoming, x + 1, y)
    traverse(visited, upcoming, x - 1, y)
    traverse(visited, upcoming, x, y + 1)
    traverse(visited, upcoming, x, y - 1)
  end
end

function fill_map_holes()
  local map_groups = empty_map_groups()
  local current_group = 1

  for x = 0, 121 do
    for y = 0, 55 do
      if not contains_wall(x, y) and map_groups[x+1][y+1] == c_filler_no_group then
        fill_group(current_group, map_groups, x, y)
        current_group += 1
      end
    end
  end

  local group_counts = {}
  for group = 1, current_group do
    group_counts[group] = 0
  end

  for x = 0, 121 do
    for y = 0, 55 do
      if not contains_wall(x, y) then
        local map_group = map_groups[x+1][y+1]
        group_counts[map_group] += 1
      end
    end
  end

  local largest_group = -1
  local largest_group_size = -1

  for group = 1, current_group do
    if group_counts[group] > largest_group_size then
      largest_group = group
      largest_group_size = group_counts[group]
    end
  end

  for x = 0, 121 do
    for y = 0, 55 do
      if not contains_wall(x, y) and map_groups[x+1][y+1] != largest_group then
        mset(x, y, c_sprite_wall)
      end
    end
  end
end

function add_outer_walls()
  for x = 0, 121 do
    local y = 0
    mset(x, y, c_sprite_wall)
  end
  for x = 0, 121 do
    local y = 55
    mset(x, y, c_sprite_wall)
  end
  for y = 0, 55 do
    local x = 0
    mset(x, y, c_sprite_wall)
  end
  for y = 0, 55 do
    local x = 121
    mset(x, y, c_sprite_wall)
  end
end

function cell_is_cavey(x, y)
  return not within_map(x, y) or cell_is_blocked(x, y)
end

function set_wall_sprite(x, y)
  local north = cell_is_cavey(x, y - 1)
  local south = cell_is_cavey(x, y + 1)
  local west = cell_is_cavey(x - 1, y)
  local east = cell_is_cavey(x + 1, y)

  if north and south and west and east then
    mset(x, y, c_sprite_wall_mid)
  elseif north and south and west then
    mset(x, y, c_sprite_wall_east)
  elseif north and south and east then
    mset(x, y, c_sprite_wall_west)
  elseif north and west and east then
    mset(x, y, c_sprite_wall_south)
  elseif south and west and east then
    mset(x, y, c_sprite_wall_north)
  elseif north and south then
    mset(x, y, c_sprite_wall_we)
  elseif north and west then
    mset(x, y, c_sprite_wall_se)
  elseif north and east then
    mset(x, y, c_sprite_wall_sw)
  elseif south and west then
    mset(x, y, c_sprite_wall_ne)
  elseif south and east then
    mset(x, y, c_sprite_wall_nw)
  elseif west and east then
    mset(x, y, c_sprite_wall_ns)
  elseif north then
    mset(x, y, c_sprite_wall_swe)
  elseif south then
    mset(x, y, c_sprite_wall_nwe)
  elseif west then
    mset(x, y, c_sprite_wall_nse)
  elseif east then
    mset(x, y, c_sprite_wall_nsw)
  else
    mset(x, y, c_sprite_wall_nswe)
  end
end

function set_map_sprites()
  for x = 0, 121 do
    for y = 0, 55 do
      if cell_is_blocked(x, y) then
        set_wall_sprite(x, y)
      else
        mset(x, y, c_sprite_floor)
      end
    end
  end
end

function new_cam()
  return {
    x = 4,
    y = -12,
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

function new_skeltal()
  local coords = random_legal_coords()
  return {
    x = coords.x,
    y = coords.y,
    next_x = coords.x,
    next_y = coords.y,
    dir = c_dir_left,
    sprs = c_enemy_skel_sprs,
    moving = false,
    speed = 0.5,
    type = c_enemy_skel_type,
  }
end

function _init()
  state = c_state_menu
  cam = new_cam()
end

function set_coords(actor, coords)
  actor.x = coords.x
  actor.y = coords.y
  actor.next_x = coords.x
  actor.next_y = coords.y
end

function _update()
  if state==c_state_game then
    update_game()
  elseif state==c_state_menu then
    update_menu()
  elseif state==c_state_generate then
    update_generate()
  elseif state==c_state_generate_done then
    update_generate_done()
  end
end

function update_generate_done()
  if (btnp(0) or btnp(1) or btnp(2) or btnp(3) or btnp(4) or btnp(5)) then
    set_map_sprites()
    init_game()
  end
end

function update_generate()
  if gen < 6 then
    if gen_x > 121 then
      gen_x = 0
      gen += 1

      for x = 0, 121 do
        for y = 0, 55 do
          last_gen_walls[x + 1][y + 1] = contains_wall(x, y)
        end
      end
    end

    map_generation()
    gen_x += 1
    map_generation()
    gen_x += 1
  end

  if gen == 5 then
    fill_map_holes()
    add_outer_walls()
    state = c_state_generate_done
  end
end

function update_game()
  update_player()
  foreach(enemies, update_enemy)
  update_cam()
end

function update_player()
  if not player.moving then
    player_move_input()
  else
    move_actor(player)
  end

  update_sword()
end

function update_sword()
  if player.sword.time == 0 and btnp(4) then
    player.sword.time = c_total_sword_time
    local dir = player.dir
    player.sword.dir = dir
    if dir == c_dir_left then
      player.sword.sprs = c_sprites_sword_hori
      player.sword.x_diff = -7
      player.sword.y_diff = 0
    elseif dir == c_dir_right then
      player.sword.sprs = c_sprites_sword_hori
      player.sword.x_diff = 7
      player.sword.y_diff = 0
    elseif dir == c_dir_up then
      player.sword.sprs = c_sprites_sword_vert
      player.sword.x_diff = 0
      player.sword.y_diff = -7
    elseif dir == c_dir_down then
      player.sword.sprs = c_sprites_sword_vert
      player.sword.x_diff = 0
      player.sword.y_diff = 7
    end
  end

  if player.sword.time > 0 then
    player.sword.time -= 1
    player.sword.x = player.x + player.sword.x_diff
    player.sword.y = player.y + player.sword.y_diff
  end
end

function update_enemy(enemy)
  if enemy.type == c_enemy_skel_type then
    update_skeltal(enemy)
  end
end

function update_skeltal(skeltal)
  if not skeltal.moving then
    local x_diff = 8 * flr(rnd(3) -1)
    local y_diff = 8 * flr(rnd(3) -1)
    local next_x = skeltal.x + x_diff
    local next_y = skeltal.y + y_diff

    if not pixel_is_blocked(next_x, next_y) then
      skeltal.next_x = next_x
      skeltal.next_y = next_y
      skeltal.moving = true
    end
  else
    move_actor(skeltal)
  end
end

function player_move_input()
  if btn(0) and not pixel_is_blocked(player.x - 8, player.y) then
    game_state = c_game_state_walking
    player.next_x = player.x - 8
    player.dir = c_dir_left
    player.moving = true
  elseif btn(1) and not pixel_is_blocked(player.x + 8, player.y) then
    game_state = c_game_state_walking
    player.next_x = player.x + 8
    player.dir = c_dir_right
    player.moving = true
  elseif btn(2) and not pixel_is_blocked(player.x, player.y - 8) then
    game_state = c_game_state_walking
    player.next_y = player.y - 8
    player.dir = c_dir_up
    player.moving = true
  elseif btn(3) and not pixel_is_blocked(player.x, player.y + 8) then
    game_state = c_game_state_walking
    player.next_y = player.y + 8
    player.dir = c_dir_down
    player.moving = true
  end
end

function move_actor(actor)
  local move_x = actor.next_x - actor.x
  local move_y = actor.next_y - actor.y
  if move_x > 0 then
    actor.x += actor.speed
  elseif move_x < 0 then
    actor.x -= actor.speed
  end
  if move_y > 0 then
    actor.y += actor.speed
  elseif move_y < 0 then
    actor.y -= actor.speed
  end

  if actor.next_x == actor.x and actor.next_y == actor.y then
    actor.moving = false
  end
end

function update_menu()
  if btn(4) then
    first_generation()
    music(c_music_generate)
    state = c_state_generate
  end
end

function init_game()
  music(c_music_game)
  state = c_state_game

  local coords = random_legal_coords()
  set_coords(player, coords)

  for i = 1, 20 do
    add(enemies, new_skeltal())
  end
end

-- checks if the x, y pixel position is blocked by a wall
function pixel_is_blocked(x, y)
  local cellx = flr(x / 8)
  local celly = flr(y / 8)
  return cell_is_blocked(cellx, celly)
end

function cell_is_blocked(cellx, celly)
  local sprite = mget(cellx, celly)
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

function cam_at_grid_point()
  return (cam.x - 4) % 120 == 0 and (cam.y + 12) % 112 == 0
end
-->8
-- draw functions --

function _draw()
  cls()
  if state==c_state_menu then
    print("welcome to game", 10, 10)
  elseif state==c_state_game then
    draw_game()
  elseif state==c_state_generate then
    draw_generate()
  elseif state==c_state_generate_done then
    draw_generate_done()
  end
end

function random_map_color()
  local random = rnd(20)
  if random < 1 then
    return 0
  elseif random < 3 then
    return 2
  else
    return 8
  end
end

function draw_whole_map()
  for x = 0, 121 do
    for y = 0, 55 do
      if mget(x, y) == c_sprite_wall then
        pset(x+3, y+9, random_map_color())
      end
    end
  end

  for x = 0, 121 do
    pset(x+3, 0+9, random_map_color())
  end
  for x = 0, 121 do
    pset(x+3, 55+9, random_map_color())
  end
  for y = 0, 55 do
    pset(0+3, y+9, random_map_color())
  end
  for y = 0, 55 do
    pset(121+3, y+9, random_map_color())
  end
end

function draw_generate()
  draw_whole_map()
  print("generating...", 39, 90, 8)
end

function draw_generate_done()
  draw_whole_map()
  print("it's done.", 45, 90, 8)
end

function draw_sword()
  if player.sword.time > 0 then
    local spr_index = 2 - flr(player.sword.time * 2 / c_total_sword_time)
    local sprite = player.sword.sprs[spr_index]
    local flip_x = (player.sword.dir == c_dir_left) or (player.sword.dir == c_dir_up)
    local flip_y = (player.sword.dir == c_dir_up)
    spr(sprite, player.sword.x, player.sword.y, 1, 1, flip_x, flip_y)
  end
end

function draw_game()
  camera(cam.x, cam.y)
  map(0, 0, 0, 0, 128, 128)

  foreach(enemies, draw_actor)
  draw_actor(player)
  draw_sword()
  draw_hud()
end

function draw_actor(actor)
  local spr_data = actor.sprs[actor.dir]
  spr(spr_data.spr, actor.x, actor.y, 1, 1, spr_data.mirror)
end

function draw_hud()
  rectfill(cam.x, cam.y, cam.x + 128, cam.y + 9, 0)
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000566500000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005666650000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006686860000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006686860000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006666660000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005060650000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000606000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000566600000000000000000000000000
00000000dddddd0000000000dddddd000000000000dddddd00000000000000000000000000000000000000000000000000000000000000000000000000000000
000000005dd777d0dddddd005dddd7d0dddddd000ddddd5500dddddd000000000000000000000000000000000000000000000000000000000000000000000000
000000000d7878d05dd777d00dd778705dddd7d00dddd5500ddddd55000000000000000000000000000000000000000000000000000000000000000000000000
000000000d7777d00d7878d00dd777700dd778700ddd55d00dddd550000000000000000000000000000000000000000000000000000000000000000000000000
000000000d5775d00d7777d00ddd77d00dd777700dddddd00ddd55d0000000000000000000000000000000000000000000000000000000000000000000000000
0000000000d55d000d5775d000ddd5000ddd77d000d55d000dddddd0000000000000000000000000000000000000000000000000000000000000000000000000
0000000000dd5d0000d55d000dddd50000ddd50000dddd0000d55d00000000000000000000000000000000000000000000000000000000000000000000000000
000000000ddd5dd0dddd5ddddddddd50dddddd500dddddd0dddddddd000000000000000000000000000000000000000000000000000000000000000000000000
00000000000006700000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000067600000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000050676000005006700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000006576000dd15006700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000d500000155666700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000d0650000656776600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000050067700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000d065000061d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000d50000555100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000006576000065550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000005067600076000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000006760676000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000670766667700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000767770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000088888850000000000000000000000000000000000000000088888888888888888888885088888850888888888888888888888850888888500000000
00000000800000080000000000000000000000000000000000000000800000000000000000000008800000088000000000000000000000088000000800000000
00000000800000080000000000000000000000000000000000000000800000000000000000000008800000088000000000000000000000088000000800000000
00000000800000080000000000000000000000000000000000000000800000000000000000000008800000088000000000000000000000088000000800000000
00000000800000080000000000000000000000000000000000000000800000000000000000000008800000088000000000000000000000088000000800000000
00000000800000080000000000000000000000000000000000000000800000000000000000000008800000088000000000000000000000088000000800000000
00000000800000080000000000000000000000000000000000000000800000000000000000000008800000088000000000000000000000088000000800000000
00000000588888800000000000000000000000000000000000000000800000000000000000000008800000085888888888888888888888805888888000000000
00550055000000000000000000000000000000000000000000000000800000000000000000000008800000080000000000000000000000000000000000000000
00550055000000000000000000000000000000000000000000000000800000000000000000000008800000080000000000000000000000000000000000000000
55005500000000000000000000000000000000000000000000000000800000000000000000000008800000080000000000000000000000000000000000000000
55005500000000000000000000000000000000000000000000000000800000000000000000000008800000080000000000000000000000000000000000000000
00550055000000000000000000000000000000000000000000000000800000000000000000000008800000080000000000000000000000000000000000000000
00550055000000000000000000000000000000000000000000000000800000000000000000000008800000080000000000000000000000000000000000000000
55005500000000000000000000000000000000000000000000000000800000000000000000000008800000080000000000000000000000000000000000000000
55005500000000000000000000000000000000000000000000000000800000000000000000000008800000080000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000800000000000000000000008800000080000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000800000000000000000000008800000080000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000800000000000000000000008800000080000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000800000000000000000000008800000080000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000800000000000000000000008800000080000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000800000000000000000000008800000080000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000800000000000000000000008800000080000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000588888888888888888888880588888800000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000100000000000101010101010101000000000000000001010101000000000000000000000000010101010000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000000003010080200a04011050150502005019050250501e0502005028050270502305023050230502705023050250502105020050200501e0501c0501a0501905017050150500d040100300d01009000
011400000707000000000000000007070000000000000000070700707400000000000000000000000000000007070000000000000000070700000000000000000707007074000000000002070020740000000000
01140000131400000015140000001614000000161401613016120161150000000000000000000000000000001314000000151400000016140000001a1401a1301a1201a115181401813018120181150000000000
011400001a140000001c140000001d140000001d1401d1301d1201d1150000000000000000000000000000001a140000001c140000001d14000000211402113021120211101f1401f1301f1201f1100000000000
011400002414024144221402214421140211441f1401f1301f1201f1150000000000000000000000000000001a1401a1441c1401c1441d1401d144211402113021120211151f1401f1301f1201f1150000000000
011400002414024144221402214421140211441f1401f1301f1201f115000000000000000000000000000000221402214421140211441f1401d144211402113021120211151f1401f1301f1201f1150000000000
01140000050700000000000000000507000000000000000007070070740000000000000000000000000000000c070000000000000000090700000000000000000507005074000000000000000000000000000000
011400000507000000000000000005070000000000000000070700707400000000000000000000000000000002070000000000002070000000000005070050500504005030050200501500000000000000000000
011400000507000000000000000005070000000000000000070700707400000000000000000000000000000002070000000000002070000000000000070000500004000030000200001500000000000000000000
011400002112221132211422113221122211152112221135221222213222142221422214222132221222211528122281322612226132241222413221122211322113221132211322113221132211322112021115
011400002414024144221402214421140211441f1401f1301f1201f115000000000000000000000000000000221402214421140211441f1401d144211402113021120211151f1401f1301f1201f1152112221135
011400000712007120071350712007120071350712007125071200712007135071200712007135071200712507120071200713507120071200713507120071250712007120071350712007120071350512005120
011400001371013710137201372013730137301374013740137501375013750137501375013750137501375013750137501375013750137501375013750137501374013740137301373013720137201371013710
011400001a7101a7101a7201a7201a7301a7301a7401a7401a7501a7501a7501a7501a7501a7501a7501a7501a7501a7501a7501a7501a7501a7501a7501a7501a7401a7401a7301a7301a7201a7201a7101a710
011400002371023710237202372023730237302374023740237502375023750237502375023750237502375023750237502375023750237502375023750237502374023740237302373023720237202371023710
011400002171021710217202172021730217302174021740217502175021750217502175021750217502175021750217502175021750217502175021750217502174021740217302173021720217202171021710
011400001271012710127201272012730127301274012740127501275012750127501275012750127501275012750127501275012750127501275012750127501274012740127301273012720127201271012710
011400000212002120021350212002120021350212002125021200212002135021200212002135021200212502120021200213502120021200213502120021250212002120021350212002120021350912009120
011400000b1200b1200b1350b1200b1200b1350b1200b1250b1200b1200b1350b1200b1200b1350b1200b1250b1200b1200b1350b1200b1200b1350b1200b1250b1200b1200b1350b1200b1200b1350912009120
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
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
01 0b0c0d0e
00 0b0c0d0f
00 11100d0f
02 12100d0e

