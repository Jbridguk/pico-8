pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
function generate_level()
    level = {}
    
    -- terrain parameters
    local min_height = 8   -- highest terrain can go (low y value)
    local max_height = 14  -- lowest terrain can go (high y value)
    local current_height = 11  -- starting height
    local prev_height = current_height
    
    for x = 1, 500 do
        level[x] = {}
        
        -- randomly adjust terrain height
        local change = flr(rnd(3)) - 1  -- -1, 0, or 1
        current_height += change
        
        -- constrain within bounds
        current_height = mid(min_height, current_height, max_height)
        
        -- determine sprite based on slope
        local terrain_sprite = 2  -- default to level (sprite 2)
        local surface_y = current_height + 1  -- default surface position
        
        if current_height < prev_height then
            terrain_sprite = 1  -- ascending (going up, y decreasing)
            surface_y = current_height + 1
        elseif current_height > prev_height then
            terrain_sprite = 3  -- descending (going down, y increasing)
            surface_y = prev_height + 1  -- descending tile at previous height
        end
        
        -- fill column
        for y = 1, 32 do
            if y == surface_y then
                -- surface tile with appropriate slope
                level[x][y] = terrain_sprite
            elseif y > surface_y then
                -- solid ground below surface
                level[x][y] = 4
            else
                -- air above surface
                level[x][y] = 0
            end
        end
        
        prev_height = current_height
    end
end

function fill_column(world_col)
    local map_col = world_col % buffer_w

    for y = 0, map_h - 1 do
        local tile = 0

        if level[world_col + 1] then
            tile = level[world_col + 1][y + 1]
        end

        mset(map_col, y, tile)
    end
end

function init_buffer()
    for world_col = 0, buffer_w - 1 do
        fill_column(world_col)
    end
end

function _init()
    -- constants
    buffer_w = 64
    screen_w_tiles = 32
    map_h = 32

    -- globals
    scroll_x = 0
    scroll_speed = 1

    last_tile_x = -1

    enemies = {}

    generate_level()

    init_buffer()

    --[[     print(mget(0, 20), 0, 0, 7)
    print(mget(1, 20), 0, 8, 7)
    print(mget(2, 20), 0, 16, 7)
    print(mget(3, 20), 0, 24, 7)

    stop()
 ]]
    ship = {
        x = 40,
        y = 64,
        spr = 16
    }
end

function _update()
    scroll_x += scroll_speed

    -- ship movement

    if btn(2) then ship.y -= 1 end
    if btn(3) then ship.y += 1 end
    if btn(0) then ship.x -= 1 end
    if btn(1) then ship.x += 1 end

    -- constrain ship

    ship.x = mid(16, ship.x, 80)
    ship.y = mid(0, ship.y, 120)

    local tile_x = flr(scroll_x / 8)

    if tile_x > last_tile_x then
        last_tile_x = tile_x

        -- column entering on right side

        local world_col = tile_x + buffer_w - 1

        fill_column(world_col)
    end
end

function draw_ring_buffered_map()
    local tile_x = flr(scroll_x / 8)

    local start_col = tile_x % buffer_w

    local world_x = tile_x * 8

    if start_col + screen_w_tiles
            <= buffer_w then
        -- no wrap

        map(
            start_col,
            0,
            world_x,
            0,
            screen_w_tiles,
            map_h
        )
    else
        -- wraps around buffer end

        local left_cols = buffer_w - start_col

        local right_cols = screen_w_tiles - left_cols

        map(
            start_col,
            0,
            world_x,
            0,
            left_cols,
            map_h
        )

        map(
            0,
            0,
            world_x + left_cols * 8,
            0,
            right_cols,
            map_h
        )
    end
end

function _draw()
    cls()

    camera(scroll_x, 0)

    draw_ring_buffered_map()

    -- enemies

    for e in all(enemies) do
        spr(e.spr, e.x, e.y)
    end

    -- ship

    spr(
        ship.spr,
        ship.x + scroll_x,
        ship.y
    )

    camera()

    print(
        "scroll:" .. flr(scroll_x),
        0,
        0,
        7
    )
end

__gfx__
cccccccc000000bbbbbbbbbbbb000000666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccc00000bb6666666666bb00000666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccc0000bb666666666666bb0000666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccc000bb66666666666666bb000666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccc00bb6666666666666666bb00666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccc0bb666666666666666666bb0666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccccccccbb66666666666666666666bb666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777b6666666666666666666666b666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
96666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
96666666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
96666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
