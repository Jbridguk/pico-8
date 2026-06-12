pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
function set_diff(d)
 -- how fast rocks start off at
 -- > = harder
 rock_max_speed=1
 if (d==2) rock_max_speed=1.1
 if (d==3) rock_max_speed=1.15
 if (d==4) rock_max_speed=1.2
 if (d>=5) rock_max_speed=1.25

 -- how fast speed increases 
 -- when rocks split 
 -- > = harder
 rock_speed_inc=1.1
 if (d==2) rock_speed_inc=1.1
 if (d==3) rock_speed_inc=1.12
 if (d==4) rock_speed_inc=1.13
 if (d>=5) rock_speed_inc=1.15

 -- number of rocks per wave
 max_rocks=5
 if (d==2) max_rocks=5
 if (d==3) max_rocks=6
 if (d==4) max_rocks=7
 if (d>=5) max_rocks=8
 
 -- saucer max speed
 scr_max_speed=1
 if (d==2) scr_max_speed=1.1
 if (d==3) scr_max_speed=1.2
 if (d==4) scr_max_speed=1.3
 if (d>=5) scr_max_speed=1.5
 
 
 -- saucer spawn rate [big,small]
 scr_spwn_rate={1000,9999}
 if (d==2) scr_spwn_rate={800,9999}
 if (d==3) scr_spwn_rate={700,5000}
 if (d==4) scr_spwn_rate={1500,700}
 if (d==5) scr_spwn_rate={1800,600}
 if (d==6) scr_spwn_rate={1900,400}
 if (d>=7) scr_spwn_rate={2000,300}
  
 -- saucer spawn rate reduction
 scr_spwn_rate_red=0.25
 --if (d==2) scr_spwn_rate_red=0.3
 --if (d==3) scr_spwn_rate_red=0.4
 --if (d==4) scr_spwn_rate_red=0.5
 --if (d>=5) scr_spwn_rate_red=0.6
end

function init_game()
 diff,score=0,0
	freeship_cntdwn=freeship

 set_diff(diff)

	init_ship()
 init_stars()
 
 rocks={}
 
 game_state=gs.running
end

function _init()
 cartdata("spacerocks_jb")
 hiscores={}
 init_hiscores()
 
 sfx_bangbig,
 sfx_bangmed,
 sfx_bangsml,
 sfx_fire,
 sfx_thrust,
 sfx_wavehi,
 sfx_wavelo,
 sfx_freeship,
	sfx_shipexplode,
	sfx_scrbig,
	sfx_scrsml,
	sfx_scrxpl,
	sfx_scrfire=0,1,2,3,4,5,6,7,8,9,10,11,12

 sfx_chl={
  ship=0,
  bullet=1,
  rock=2,
  saucer=3
 } 
 
 sfx_wave_delay,
 sfx_wave_delay_cnt,
 sfx_wave=40,0,sfx_wavehi

 smax=255
 gcoll=nil

	score=0
	freeship=10000
	 
 -- how long before new rocks appear
 rock_delay=100 
 rock_cntdwn=100
 
 cam_x=0
 cam_y=0
 --p5=0.5

 parts={}
 
 -- game states
 gs={
  over=0,
  running=1,
  ending=2,
  newhs=3,
 }
 
 game_state,
 gs_ending_delay,
 gs_endgame_cntr=gs.over,150,0

 --printh("", "logh.txt", true)
 
 init_ship()
 init_bullets()
 init_saucers()
 init_minimap()
 --init_game()	 
end

function set_gamestate(st)
 if st==gs.over then
  init_stars()
  init_rocks()
  sfx(-1,sfx_chl.saucer)
  ship.x=64
  ship.y=64
	end
	game_state=st
end

function _update()
 if game_state==gs.over then
  if btn(❎) then
   init_game()
  end
  goto exit
 end

 if game_state==gs.ending then
  gs_endgame_cntr-=1
  if gs_endgame_cntr<1 then
   if new_hiscore() then
    game_state=gs.newhs
    hsname={".",".","."}
    hsentpos=1
   else
    set_gamestate(gs.over)
   end
  end
 end
 
 if game_state==gs.newhs then
  enter_new_hiscore()
 else
  local prev_x,prev_y=ship.x,ship.y
  update_ship()
  local dx,dy=ship.x-prev_x,ship.y-prev_y
  update_stars(dx,dy)
 end

 update_bullets()
 update_rocks()
 
 if (game_state!=gs.newhs) spawn_saucers()
 update_saucers()
 update_parts()
 
 ::exit::
end

function draw_grid()
 for x=0,smax,8 do
  line(x,0,x,smax,1)
 end
 for y=0,smax,8 do
  line(0,y,smax,y,1)
 end
end

function _draw()
 cls() 
 
 if game_state==gs.over then
  draw_gameover_scrn()
  goto exit
 end

 -- center camera on ship (round to nearest integer)
 cam_x=ship.x-64
 cam_y=ship.y-64
 camera(cam_x,cam_y)
 
 --draw_grid()
 draw_stars()
 draw_bullets()
 draw_rocks()
 draw_saucers()
 draw_parts()

 cam_x=0
 cam_y=0
 camera() 
 if (game_state!=gs.newhs) draw_minimap()
 draw_ship()
 draw_hud()
 
 if (game_state==gs.ending) shprint("game over",46,61,12,1)
 if (game_state==gs.newhs) draw_new_hiscore()

 
 -- debug
 --[[
	 rect(0,0,127,127,11) 
	 
	 print(ship.thrust_power.." "..ship.vx.." "..ship.vy,4,4,7)
	 if gcoll then
	  print(grock.minx.." "..grock.miny.." "..grock.maxx.." "..grock.maxy,0,20,0)
	 end
	--]]
	
	::exit::
end

function draw_hud()
 -- print score
	local dscr=tostr(score,0x2)
	while #dscr < 6 do
	 dscr="0"..dscr
	end
	shprint(dscr,52,4,12,1) 
	
	for i=1,ship.lives do
	 draw_mini_ship(4+i*6,6)
	end
end

function draw_gameover_scrn()
 --spr(0,0,0,16,20)
 if rocks==nil then
  diff=0
  init_rocks()
  init_stars()
 end
 
 saucers={}
 sfx(-1,sfx_chl.saucer)
 
 draw_stars() 
 update_rocks()
 draw_rocks()
 
 local left=4
 local top=4
 local logo_col=12

 vector_print("space",left,top,logo_col)
 
 --line 2--
 top+=25
 left=4
 
 vector_print("rocks",left,top,logo_col)
 
 if hiscore_timer > 0 then
  hiscore_timer-=1
  if hiscore_timer==0 then
   hiscore_timer=hiscore_delay
   hiscore_idx+=1
   if (hiscore_idx>7) hiscore_idx=4
  end
 end
 
 print_hiscores(hiscore_idx,7,55)

 shprint("press    to start",29,120,12,1)
 if (flr(t()*10%5)!=0) shprint("❎",53,120,11,3)
end
-->8
-- rock handling

function new_rock(
   x,y,
   size,col,
   rotation,
   speed_x,speed_y)
   
 -- default parameters
 x = x or 64
 y = y or 64
 size = size or 10
 col = col or 7
 rotation = rotation or 0
 speed_x = speed_x or 0
 speed_y = speed_y or 0
 
 -- create a fixed set of relative positions (shape template)
 local shape = {
   {x = 0, y = -1},      -- top
   {x = 0.8, y = -0.6},  -- top right
   {x = 1, y = 0},       -- right
   {x = 0.8, y = 0.6},   -- bottom right
   {x = 0, y = 1},       -- bottom
   {x = -0.8, y = 0.6},  -- bottom left
   {x = -1, y = 0},      -- left
   {x = -0.8, y = -0.6}  -- top left
 }
 
 -- apply minor random variations to create unique shape
 local points = {}
 
 for i = 1, #shape do
  -- apply a small random variation (15%)
  local variation_x = 1 + (rnd(0.3) - 0.15)
  local variation_y = 1 + (rnd(0.3) - 0.15)
  
  -- store the modified relative position
  local px=shape[i].x * variation_x
  local py=shape[i].y * variation_y
     
  add(points, {x=px,y=py})
 end
 
 -- create the rock object (without the method code)
 local rock={
   x=x, -- center x position
   y=y, -- center y position
   minx=9999,
   maxx=0,
   miny=9999,
   maxy=0,
   size=size, -- scale factor
   col=col,   -- outline color
   points=points, -- relative shape points
   rotation=rotation,    -- current rotation in radians
   rot_speed=rnd(0.02)-0.01, -- rotation speed (random)
   speed_x=speed_x, -- horizontal speed
   speed_y=speed_y, -- vertical speed
   update=rock_update,
   draw=rock_draw,
   trans_points=rock_trans_points,
   divide=rock_divide,
   destroy=rock_destroy,
   update_bounding_box=
     rock_update_bounding_box
 }
 
 add(rocks,rock)
end

function rock_update_bounding_box(rock)
 local points=rock:trans_points()
 local minx,miny=points[1].x,points[1].y
 local maxx,maxy=points[1].x,points[1].y

 for p in all(points) do
  if p.x<minx then minx=p.x end
  if p.y<miny then miny=p.y end
  if p.x>maxx then maxx=p.x end
  if p.y>maxy then maxy=p.y end
 end

 -- handle wrapping
 if maxx-minx > smax/2 then
  minx=(minx+smax)%smax
  maxx=(maxx+smax)%smax
 end
 if maxy-miny > smax/2 then
  miny=(miny+smax)%smax
  maxy=(maxy+smax)%smax
 end

 rock.minx = minx
 rock.miny = miny
 rock.maxx = maxx
 rock.maxy = maxy
end

function rock_update(rock)
 -- update position
 rock.x = rock.x + rock.speed_x
 rock.y = rock.y + rock.speed_y
 
 -- update rotation
 rock.rotation = rock.rotation + rock.rot_speed
 
 -- handle screen wrapping
 rock.x = (rock.x + smax) % smax
 rock.y = (rock.y + smax) % smax 

 -- update bounding box
 rock:update_bounding_box()
end

function rock_trans_points(rock,x,y)
 local points_transformed={}
 x=x or rock.x
 y=y or rock.y

 -- transform all points based on position, size, and rotation
 for i = 1, #rock.points do
  -- apply rotation to the point
  local rx = rock.points[i].x            * cos(rock.rotation)            - rock.points[i].y * sin(rock.rotation)
  local ry = rock.points[i].x            * sin(rock.rotation)            + rock.points[i].y * cos(rock.rotation)

  -- apply size and position
  local px = x + rx * rock.size
  local py = y + ry * rock.size

  -- wrap coordinates to handle world wrapping
  --px = (px + smax) % smax
  --py = (py + smax) % smax

  add(points_transformed, 
    {x=px, y=py})
 end

 return points_transformed
end

function rock_draw(rock)
 local draw_rock=false
 for dx in all({-smax, smax, 0}) do
  for dy in all({-smax,smax, 0}) do
   draw_rock=
    (abs(rock.x+dx-ship.x)<80) 
    and (abs(rock.y+dy-ship.y)<80)

   local mnx=9999
   local mny=9999
   local mxx=-9999
   local mxy=-9999
     
   local points_transformed=
     rock:trans_points(
       rock.x+dx,rock.y+dy)
     
   -- draw the outline
   for i = 1, #points_transformed do
    local p1 = points_transformed[i]
    local p2 = points_transformed[(i % #points_transformed) + 1]
       
    if (p1.x>mxx) mxx=p1.x
    if (p1.x<mnx) mnx=p1.x
    if (p1.y>mxy) mxy=p1.y
    if (p1.y<mny) mny=p1.y
     
    if draw_rock then
     line(p1.x, p1.y, p2.x, p2.y, rock.col)
    end
   end
     
   rock.minx,
   rock.miny,
   rock.maxx,
   rock.maxy=mnx,mny,mxx,mxy
   --[[ debug --
   if false then
    --draw bounding box 
    rect(rock.minx,rock.miny,rock.maxx,rock.maxy,12)
   end
   --]]
  end
 end
end

function rock_divide(rock,obj)
 if obj==ship then
	 if rock.size > 30 then
	  sfx(sfx_bangbig,sfx_chl.rock)
	  addscore(20)
	 elseif rock.size > 10 then
	  sfx(sfx_bangmed,sfx_chl.rock)
	  addscore(30)
	 else
	  sfx(sfx_bangsml,sfx_chl.rock)
	  addscore(50)
	 end
 end
 
 -- draw rock about to explode
 rock:draw() 
 
 local cx,cy=ship.x-64,ship.y-64
 
 create_parts(
  rock.minx-cx,
  rock.miny-cy,
  rock.maxx-cx,
  rock.maxy-cy,
  10, -- life,
  1  -- speed
 )

 if rock.size<4 then
  rock:destroy()
  return
 end

 local speed_factor=rock_speed_inc
 local split_angle=0.5
 local angle_var=0.1
                   
 local new_speedx=rock.speed_x*
       speed_factor
 local new_speedy=rock.speed_y*
       speed_factor

 local new_speed=sqrt(
         new_speedx^2+
         new_speedy^2)

 for i=1,2 do
  if i==1 then
   new_speedy=new_speedy / 2
   											+(rnd(0.1)
   											  *sign(new_speedy)
   											 )
   new_speedx=calculatev2(
       new_speedy,
       new_speed,
       rock.speed_x)
  else 
   new_speedx=new_speedx / 2
   											+(rnd(0.1)
   											  *sign(new_speedx)
   											 )
   new_speedy=calculatev2(
       new_speedx,
       new_speed,
       rock.speed_y)
  end
  -- create new rock
  new_rock(
   rock.x,
   rock.y,
   rock.size/2,
   rock.col,
   rnd(1),
   new_speedx,
   new_speedy
  )
 end

 -- remove original rock
 del(rocks,rock)
end

function rock_destroy(rock)
 del(rocks,rock)
end

function init_rocks()
 -- create a few rocks
 rocks={}
 rock_colors={7,8,10,11,13,14,15}
 diff+=1
 set_diff(diff)
 
 for i = 1, max_rocks do
   new_rock(
     rnd(smax), -- random x
     rnd(smax), -- random y
     10 + rnd(15), -- random size between 10-25
     rnd(rock_colors), -- random colour
     rnd(1),    -- random rotation
     rnd(rock_max_speed*2)
         -rock_max_speed,-- random x speed
     rnd(rock_max_speed*2)
         -rock_max_speed -- random y speed
   )
 end
 
 set_ship_state(ss.spawning)
end

function update_rocks()
 if #rocks==0 then
  if rock_cntdwn<1 then
   -- new wave --
   init_rocks()
   rock_cntdwn=rock_delay
  else
   rock_cntdwn-=1
  end
 end
 
 if game_state!=gs.over
  and game_state!=gs.newhs 
 then
	 if sfx_wave_delay_cnt > 0 then
	  sfx_wave_delay_cnt-=1
	 elseif #rocks>0 then
	  sfx_wave_delay_cnt=
	    max(sfx_wave_delay-#rocks,10)
	  sfx(sfx_wave)
	  if sfx_wave==sfx_wavehi then
	   sfx_wave=sfx_wavelo
	  else
	   sfx_wave=sfx_wavehi
	  end
	 end
 end
 
 for rock in all(rocks) do
  rock:update()
 end
end

function draw_rocks()
 for rock in all(rocks) do
  -- skip drawing the rock if it is colliding with the ship
  if gcoll and rock == grock then
   -- skip this rock
  else
   rock:draw()
	 end
 end 
end 

-->8
-- ship handling

function init_ship()
 -- ship states
 ss={
  waiting=-1,
  spawning=0,
  intact=1,
  destroyed=2
 }

	-- constants
	ship_spawn_delay,
	ship_lives,
	ship_max_lives=60,3,5
	 
 local minx,miny=-4,-6
 local maxx=abs(minx)
 local maxy,boty,botx=4,2,0
 
 ship = {
  x=64,y=64,
  drawx=64,drawy=64, -- always centered
  angle=0,
  vx=0,
  vy=0,
  thrust=0.1, -- max acceleration per frame
  thrust_power=0, -- current thrust level
  thrust_inc=0.1/20, -- how quickly thrust increases
  thrust_dec=0.1/10, -- how quickly thrust decreases
  drag=0.995,  -- friction (1 = no drag)
  minx=minx,
  miny=miny,
  maxx=maxx,
  maxy=maxy,
  points={
   {x=botx, y=miny},-- top
   {x=maxx, y=maxy},-- b right
   {x=botx, y=boty},-- bot
   {x=minx, y=maxy} -- b left
  },
  fx=1, -- flame x
  fy=6, -- flame y
  state=ss.waiting,
  spwncnt=0,
  spwndly=ship_spawn_delay,
  invisible=false,
  inv_dur=7, -- duration invisible
  invcnt=0, -- count invisible
  rotated_points={},
  draw_points={},
  lives=ship_lives
 }
 
 set_ship_state(ship.state) 
end

function set_ship_state(state)
 if (state==ss.spawning) ship.spwncnt,ship.invisible=60,false

 if state==ss.destroyed then
  --stop(sfx_chl.ship)
		sfx(sfx_shipexplode,sfx_chl.ship)
  ship.vx,ship.vy=0,0
  ship.lives-=1
 end
 ship.state=state
end

function ship_speed()
 return sqrt(ship.vx^2+
             ship.vy^2)
end

function update_ship()
 if ship.state==ss.waiting then
  if ship.spwndly>0 then
   ship.spwndly-=1
   return
  else
   if ship.lives > 0 then
     set_ship_state(ss.spawning)
   else
    if game_state==gs.running then
      game_state=gs.ending
      gs_endgame_cntr=gs_ending_delay
    end 
    return
   end
  end
 end 

 if btn(⬅️) then
  ship.angle += 0.03
 end 
 
 if btn(➡️) then
  ship.angle -= 0.03
 end 
 
 -- adjust thrust power
 if btn(❎) then
  sfx(sfx_thrust,sfx_chl.ship)
  ship.thrust_power = min(
     ship.thrust_power+
     ship.thrust_inc, 
     ship.thrust)
 else
  ship.thrust_power = max(
     ship.thrust_power-
     ship.thrust_dec, 0)
 end
 -- apply thrust in direction of current angle
 if ship.thrust_power > 0 then
  local a = ship.angle - 0.25
  ship.vx -= cos(a) * ship.thrust_power
  ship.vy -= sin(a) * ship.thrust_power
 end

 -- apply drag/friction
 ship.vx *= ship.drag
 ship.vy *= ship.drag

 -- update position by velocity
 ship.x += ship.vx
 ship.y += ship.vy

 -- handle screen wrapping
 ship.x = (ship.x + smax) % smax
 ship.y = (ship.y + smax) % smax

 ship.minx,ship.miny,
 ship.maxx,ship.maxy=
    9999,9999,-9999,-9999
 
 ship.rotated_points,
 ship.draw_points={},{}

 -- rotate each point based on the ship's angle
 for pt in all(ship.points) do
  local x, y = rotate_point(pt.x, pt.y, ship.angle)
  local dx,dy=
    x+ship.drawx,
    y+ship.drawy
  add(ship.draw_points, 
      {x=dx, y=dy})

  x += ship.x  
  if x > ship.maxx then ship.maxx = x end
  if x < ship.minx then ship.minx = x end

  y += ship.y
  if y > ship.maxy then ship.maxy = y end
  if y < ship.miny then ship.miny = y end
      
  add(ship.rotated_points, {x = x, y = y})
 end

 if ship.state==ss.spawning then
  ship.spwncnt-=1
  if ship.spwncnt<=0 then
   local bnd=10
	  local rock=poss_collision(
	    ship.minx-bnd,ship.miny-bnd,
	    ship.maxx+bnd,ship.maxx+bnd,
	    rocks)
	  if rock==nil then
	   --stop("no poss coll")
	   set_ship_state(ss.intact)
	   ship.invisible=false
	  end
	 end
 end

	if (ship.state==ss.spawning) return  

 if btnp(🅾️) 
   and #bullets<max_bullets 
 then
  local b = new_bullet(ship)
  --move_bullet(b) -- avoid shooting self
  sfx(sfx_fire,sfx_chl.bullet)
 end  

 local rock = poss_collision(
  ship.minx, 
  ship.miny,
  ship.maxx,
  ship.maxy,
  rocks)
   
 gcoll = not (rock == nil)
 
 --debug
 --gcoll=false
 --debug
 
 if gcoll then
  --stop("bounding box coll")
  local rock_points = rock:trans_points()
  if collision(ship.rotated_points, rock_points) then
   grock = rock
   set_ship_state(ss.destroyed)
   rock:divide()
  end
 end
 
 -- check for saucer collisions
 local scr=poss_collision(
    ship.minx,
    ship.miny,
    ship.maxx,
    ship.maxy,
    saucers)
  
 if scr then
  if collision(
    scr:trans_points(), 
    ship.rotated_points) 
  then
   set_ship_state(ss.destroyed)
   scr:explode()
   return
  end
 end
end

function draw_ship()
 if ship.state==ss.waiting then
  return
 end

 if ship.state==ss.destroyed then
  circfill(64,64,10,9)
  create_parts(44,44,74,74,
    100, --life
    3,   --speed
    9,9  --color 7 (ship only)
    )
  ship.spwndly=ship_spawn_delay
  set_ship_state(ss.waiting)
  return
 end
 
 if ship.state==ss.spawning then
  --stop("flip:"..flr(t)%ship.inv_dur)
  if ship.invcnt<=0 then
   ship.invisible=not ship.invisible
   ship.invcnt=ship.inv_dur   
  else
   ship.invcnt-=1
  end
 end

 if not (ship.invisible) then
	 local npts=#ship.draw_points
	 for i = 1,npts  do
	  local p1 = ship.draw_points[i]
	  local p2 = ship.draw_points[(i % npts) + 1]
	  line(p1.x, p1.y, p2.x, p2.y, 7) -- color 7 (white)
	 end
	
	 if ship.thrust_power>0 then 
		 -- draw flame
	  local x1,y1=rotate_point(
	     -ship.fx,ship.fy,
	     ship.angle)
		 x1+=ship.drawx
	  y1+=ship.drawy
	  
	  local x2,y2=rotate_point(
	     0+rnd(2)-1,ship.fy+3+ship.thrust_power*50,
	     ship.angle)
		 x2+=ship.drawx
	  y2+=ship.drawy
	
	  local x3,y3=rotate_point(
	     ship.fx,ship.fy,
	     ship.angle)
		 x3+=ship.drawx
	  y3+=ship.drawy
	  
	  line(x1,y1,x2,y2,9)
	  line(x2,y2,x3,y3,9)
	 end 
 end
 
 ::debug::
 --[[
	--print("ship.state:"..ship.state
	--      .."  #bullets:"..#bullets,4,120,8)
  print("ship:"..flr(ship.x)..","..flr(ship.y)
        .."cam:"..flr(cam_x)..','..flr(cam_y),4,120,8)
  --if #bullets==1 then
  -- print("bx,by="..bullets[1].x..","..bullets[1].y,40,112,9)	       
  --end
  --print(x1..","..y1,20,40,12)
  --print(x2..","..y2,20,50,12)
  --print(x3..","..y3,20,60,12)

  --stop()
  --[[
  local cx=ship.x-64
  local cy=ship.y-64
  
  for dx in all({-smax,0,smax}) do
   for dy in all({-smax,0,smax}) do
    rect(dx+ship.minx-cx,
         dy+ship.miny-cy,
         dx+ship.maxx-cx,
         dy+ship.maxy-cy,12)
   end
  end
  --]]
 --]]
end

function draw_mini_ship(x,y)
 local minx,miny=-2,-3
 local maxx,maxy=abs(minx),2
 local boty,botx=1,0
 
 local points={
   {x=botx, y=miny},-- top
   {x=maxx, y=maxy},-- b right
   {x=botx, y=boty},-- bot
   {x=minx, y=maxy} -- b left
  }

	local npts=#points
 for i=1,npts do
  local p1,p2=
  points[i],
  points[(i % npts) + 1]
  line(x+p1.x,y+p1.y,x+p2.x,y+p2.y, 7) -- color 7 (white)
 end
end
-->8
-- collision detection
function lines_intersect(x1,y1,x2,y2,x3,y3,x4,y4)
	local den = (x1-x2)*(y3-y4)-(y1-y2)*(x3-x4)
	if den == 0 then return f end -- parallel lines
	
	local t,u=
	 ((x1-x3)*(y3-y4)-(y1-y3)*(x3-x4))/den,
	 ((x1-x2)*(y1-y3)-(y1-y2)*(x1-x3))/den
	
	return (t >= 0 and t <= 1 and u >= 0 and u <= 1)
end

function poss_collision(x1,y1,x2,y2,objs)
 -- check for possible collisions 
 -- with rocks
 -- for object with bounding box
 -- x1,y1,x2,y2
 for obj in all(objs) do
  if not (
   x2 < obj.minx or 
   y2 < obj.miny or
   x1 > obj.maxx or
   y1 > obj.maxy) then
   return obj
  end
  
  --[[ debug--
	  if not(x2 < obj.minx) then
	   print(x2..">="..obj.minx)
	  end
	  if not(y2 < obj.miny) then
	   print(y2..">="..obj.miny)
	  end
	  if not(x1 > obj.maxx) then
	   print(x1.."<="..obj.maxx)
	  end
	  if not(y1 > obj.maxy) then
	   print(y1.."<="..obj.maxy)
	  end
	 --]]
 end
 return nil
end

function collision(p1,p2)
 -- p1 and p2 are table of points
 -- with x and y
 local result=false
 color(7)
 camera()
 --print_table(ship.points)
 --dump_table(ship.points)
 --print_table(p2)
 --stop()
 --stop(#p1.." "..#p2)  
 for i = 1, #p1 do
  for j = 1, #p2 do
   if lines_intersect(
	    --print(
	    p1[i].x,
	    --.." "..--,
	    p1[i].y,
	    --.." "..--,
	    p1[(i%#p1)+1].x,
	    --.." "..--,
	    p1[(i%#p1)+1].y,
	    --.." "..--,
	    p2[j].x,
	    --.." "..--,
	    p2[j].y,
	    --.." "..--,
	    p2[(j%#p2)+1].x,
	    --.." "..--,
	    p2[(j%#p2)+1].y)
	    --,7)
	  then
	   --stop()
	   result=true
	   break
	  end
  end
 end
 camera(cam_x,cam_y)
 return(result)
end

function point_in_polygon(
   px,py,polygon)
   
 local inside=false
 local n=#polygon

 --print_table(polygon)
 --stop()
 
 for i=1,n do
  local p1,p2=
    polygon[i],polygon[(i%n)+1]

  -- check if the ray intersects the edge
  if ((p1.y>py)~=(p2.y>py)) and
     (px<(p2.x-p1.x)*(py-p1.y)/
         (p2.y-p1.y)+p1.x) then
   inside=not inside
  end
 end

 return inside
end

-->8
-- bullet handling
function init_bullets()
 max_bullets,
 bullet_speed, 
 bullet_colour,
 bullets=6,3,10,{}
end

function new_bullet(
   _firer,
   _angle,
   _speed,
   _x,
   _y)
   
 _angle=_angle or ship.angle+0.25
 _speed=_speed or ship_speed()
 _x=_x or ship.rotated_points[1].x
 _y=_y or ship.rotated_points[1].y
 
 add(bullets,{
  x=_x,
  y=_y,
  life=33, -- distance bullet travels
  angle=_angle,
  speed=_speed+
        bullet_speed,
  firer=_firer
 })

 move_bullet(bullets[#bullets]) 
 return bullets[#bullets]
end

function move_bullet(b)
 -- update the bullet's position
 b.life -= 1
 if b.life < 1 then
  del(bullets, b)
 else
  b.x,b.y=
   (b.x+cos(b.angle)*b.speed+smax)%smax,
   (b.y+sin(b.angle)*b.speed+smax)%smax
 end
end

function update_bullet(b)
 -- store the bullet's previous position
 local prev_x,prev_y=b.x,b.y

 move_bullet(b)
 
 -- check for collisions along the path
 local steps=max(ceil(b.speed),1) -- number of steps to interpolate
 for i = 0, steps do
  local t=i/steps
  local interp_x,interp_y=
    prev_x+(b.x-prev_x)*t,
    prev_y+(b.y-prev_y)*t

  -- check for collision at the interpolated position
  local rock = poss_collision(
     interp_x-1,
     interp_y-1,
     interp_x+1, 
     interp_y+1,
     rocks)
     
  if rock then
   --bposscoll=true
   --brock=rock
   --gbullet=b

   -- check wrapped positions
   for dx in all({-smax, 0, smax}) do
    for dy in all({-smax, 0, smax}) do
     local bx=interp_x+dx
     local by=interp_y+dy
     if point_in_polygon(
         bx,by, 
         rock:trans_points()) 
     then
      rock:divide(b.firer)
      del(bullets, b)
      return
     end
    end
   end
  end
  
  local scr = poss_collision(
     interp_x-1,
     interp_y-1,
     interp_x+1, 
     interp_y+1,
     saucers)

  if scr and b.firer==ship then
   -- check wrapped positions
   for dx in all({-smax, 0, smax}) do
    for dy in all({-smax, 0, smax}) do
     local bx=interp_x+dx
     local by=interp_y+dy
     if point_in_polygon(
         bx,by, 
         scr:trans_points()) 
     then
      addscore(scr_points[scr.stype])
      scr:explode()
      del(bullets, b)
      return
     end
    end
   end
  end
  
  if ship.state==ss.intact then
	  local shp=poss_collision(
	     interp_x-1,
	     interp_y-1,
	     interp_x+1, 
	     interp_y+1,
	     {ship})
	
	  -- debug
	  --shp=nil
	  -- 
	      
	  if shp and b.firer!=ship then
	   for dx in all({-smax, 0, smax}) do
	    for dy in all({-smax, 0, smax}) do
	     local bx=interp_x+dx
	     local by=interp_y+dy
	     if point_in_polygon(
	         bx,by, 
	         shp.rotated_points) 
	     then
	      set_ship_state(ss.destroyed)
	      del(bullets, b)
	      return
	     end
	    end
	   end
	  end
	 end
	end
end

function update_bullets()
 for b in all(bullets) do
  update_bullet(b)
 end
	
	--[[ debug
	if btnp(⬇️) then
	 dump_table(bullets)
	 dump_table(rocks)
	 --stop()
	end
	--]]
end

function draw_bullets()
 for b in all(bullets) do
  for dx in all({-smax, 0, smax}) do
   for dy in all({-smax, 0, smax}) do
    if abs(b.x+dx-ship.x)<80 and
       abs(b.y+dy-ship.y)<80 then
     pset(b.x+dx, b.y+dy, bullet_colour)
     --[[
     rect(b.x+dx-1,
          b.y+dy-1,
          b.x+dx+1,
          b.y+dy+1,10)
     --]]
    end
   end
  end
 end
end


-->8
-- utilities
function rotate_point(x, y, angle)
  local rx = x * cos(angle) - y * sin(angle)
  local ry = x * sin(angle) + y * cos(angle)
  return rx, ry
end

function sign(x)
 if (x>0) return 1
 if (x<0) return -1
 return 0
end

function calculatev2(v1,s,v2_orig)
 return sign(v2_orig)*sqrt(s^2-v1^2)
end

function addscore(s)
 score+=0x.0001*s
 freeship_cntdwn-=s
 if freeship_cntdwn<=0 then
  if ship.lives<ship_max_lives then
   ship.lives+=1
   sfx(sfx_freeship,sfx_chl.ship)
  end
  freeship_cntdwn+=freeship
 end
end

function shprint(txt,x,y,c,sc,cl)
 sc=sc or 0
 if cl then
  rectfill(x,y,x+(#txt)*4,y+9,0)
 end
 print(txt,x+1,y+1,sc)
 print(txt,x,y,c) 
end

--[[ debug
function print_table(t, indent)
 indent = indent or ""
	for k, v in pairs(t) do
	 local key = tostring(k)
	 if type(v) == "table" then
   print(indent..key..":")
   print_table(v, indent.."  ")
	 else
   print(indent..key..": "..tostring(v))
	 end
 end
end

function dump_table(t)
 for i,v in pairs(t) do
  log(i..": "..tostr(v).." ("..type(v)..")")
  if type(v) == "table" then
   log("  x: "..tostr(v.x))
   log("  y: "..tostr(v.y))
  end
 end
end

function log(t)
 printh(t, "logh.txt")
end

--]]

-- qsort(a,c,l,r)
--
-- a
--    array to be sorted,
--    in-place
-- c
--    comparator function(a,b)
--    (default=return a<b)
-- l
--    first index to be sorted
--    (default=1)
-- r
--    last index to be sorted
--    (default=#a)
--
-- typical usage:
--   qsort(array)
--   -- custom descending sort
--   qsort(array,function(a,b) return a>b end)
--
function qsort(a,c,l,r)
	c,l,r=c or function(a,b) return a<b end,l or 1,r or #a
	if l<r then
		if c(a[r],a[l]) then
			a[l],a[r]=a[r],a[l]
		end
		local lp,k,rp,p,q=l+1,l+1,r-1,a[l],a[r]
		while k<=rp do
			local swaplp=c(a[k],p)
			-- "if a or b then else"
			-- saves a token versus
			-- "if not (a or b) then"
			if swaplp or c(a[k],q) then
			else
				while c(q,a[rp]) and k<rp do
					rp-=1
				end
 		 --stop("swap k&rp")
				a[k],a[rp],swaplp=a[rp],a[k],c(a[rp],p)
				rp-=1
			end
			if swaplp then
 		 --stop("swap k&lp")
				a[k],a[lp]=a[lp],a[k]
				lp+=1
			end
			k+=1
		end
		lp-=1
		rp+=1
		-- sometimes lp==rp, so 
		-- these two lines *must*
		-- occur in sequence;
		-- don't combine them to
		-- save a token!
		a[l],a[lp]=a[lp],a[l]
		a[r],a[rp]=a[rp],a[r]
		qsort(a,c,l,lp-1       )
		qsort(a,c,  lp+1,rp-1  )
		qsort(a,c,       rp+1,r)
	end
end

function draw_lines(lines,col)
 for i=1,#lines,4 do
  line(lines[i],lines[i+1],
       lines[i+2],lines[i+3],
       col)
 end 
end

function vector_print(txt,_x,_y,_col,_scale)
 local scale=_scale or 1
 local x=_x or 4
 local y=_y or 4
 local col=_col or 12
 
 for i=1,#txt do
  local spacewidth=max(5*scale,2)
  if txt[i]==" " then
   x+=spacewidth*2
  else
   vector_char(txt[i],x,y,col,scale)
   x+=20*scale+spacewidth
  end
 end
end

function vector_char(c,_x,_y,_col,_scale)
 local scale=_scale or 1
 local left=_x or 4
 local top=_y or 4
 local col=_col or 12

 local u=10*scale
 local uh,u2,u15=
						  0.5*u,
						  2*u,
						  1.5*u
 
 local tuh,
       lu,
	      luh,
 						lu15,
       lu2,
						 tu,
 						tu15,
 						tu2=
   top+uh,
   left+u,
   left+uh,
   left+u15,
   left+u2,
   top+u,
   top+u15,
   top+u2

 local lines
 
 if c=="a" then
	 lines={
	     left,tuh,lu,top,
	     lu,top,lu2,tuh,
	     lu2,tuh,lu2,tu2,
	     left,tuh,left,tu2,
	     left,tu,lu2,tu}
 elseif c=="b" then
  lines={
      left,top,lu15,top,
      lu15,top,lu2,tuh,
      lu2,tuh,lu15,tu,
      lu15,tu,left,tu,
      left,top,left,tu2,
      left,tu2,lu15,tu2,
      lu15,tu2,lu2,tu15,
      lu2,tu15,lu15,tu}
 elseif c=="c" then
  lines={
      left,tuh,luh,top,
      luh,top,lu15,top,
      lu15,top,lu2,tuh,
      left,tuh,left,tu15,
      left,tu15,luh,tu2,
      luh,tu2,lu15,tu2,
      lu15,tu2,lu2,tu15}
 elseif c=="d" then
  lines={
      left,top,lu15,top,
      lu15,top,lu2,tuh,
      lu2,tuh,lu2,tu15,
      lu2,tu15,lu15,tu2,
      lu15,tu2,left,tu2,
      left,tu2,left,top}
 elseif c=="e" then
  lines={
      left,top,lu2,top,
      left,top,left,tu2,
      left,tu2,lu2,tu2,
      left,tu,lu,tu}
 elseif c=="f" then
  lines={
      left,top,lu2,top,
      left,top,left,tu2,
      left,tu,lu,tu}
 elseif c=="g" then
  lines={
      left,tuh,luh,top,
      luh,top,lu15,top,
      lu15,top,lu2,tuh,
      left,tuh,left,tu15,
      left,tu15,luh,tu2,
      luh,tu2,lu15,tu2,
      lu15,tu2,lu2,tu15,
      lu2,tu15,lu2,tu,
      lu2,tu,lu,tu}
 elseif c=="h" then
  lines={
      left,top,left,tu2,
      left,tu,lu2,tu,
      lu2,top,lu2,tu2}
 elseif c=="i" then
  lines={
      left,top,lu2,top,
      left,tu2,lu2,tu2,
      lu,top,lu,tu2}
 elseif c=="j" then
  lines={
      left,top,lu2,top,
      lu,top,lu,tu15,
 					lu,tu15,luh,tu2,
 					luh,tu2,left,tu15}
 elseif c=="k" then
  lines={
      left,top,left,tu2,
 					left,tu,lu2,top,
 					left,tu,lu2,tu2}
 elseif c=="l" then
  lines={
      left,top,left,tu2,
      left,tu2,lu2,tu2}
 elseif c=="m" then
  lines={
      left,top,left,tu2,
      left,top,lu,tu,
      lu,tu,lu2,top,
      lu2,top,lu2,tu2}
 elseif c=="n" then
  lines={
      left,top,left,tu2,
      left,top,lu2,tu2,
      lu2,tu2,lu2,top}
 elseif c=="o" then
  lines={
      left,tuh,luh,top,
      luh,top,lu15,top,
      lu15,top,lu2,tuh,
 					left,tuh,left,tu15,
      left,tu15,luh,tu2,
      luh,tu2,lu15,tu2,
      lu15,tu2,lu2,tu15,
      lu2,tu15,lu2,tuh}
 elseif c=="p" then
  lines={
      left,top,lu2,top,
      lu2,top,lu2,tu,
      lu2,tu,left,tu,
      left,top,left,tu2}
 elseif c=="q" then
  lines={
      left,tuh,luh,top,
      luh,top,lu15,top,
      lu15,top,lu2,tuh,
 					lu2,tuh,lu2,tu15,
 					lu2,tu15,lu15,tu2,
      lu15,tu2,luh,tu2,
      luh,tu2,left,tu15,
      left,tu15,left,tuh,
      lu15,tu15,lu2,tu2}
 elseif c=="r" then
  lines={
      left,top,lu2,top,
      left,top,left,tu2,
      left,tu,lu2,tu,
      lu2,tu,lu2,top,
      lu,tu,lu2,tu2}
 elseif c=="s" then
  lines={
      left,top,lu2,top,
      left,top,left,tu,
      left,tu,lu2,tu,
      lu2,tu,lu2,tu2,
      lu2,tu2,left,tu2}
 elseif c=="t" then
  lines={
      left,top,lu2,top,
      lu,top,lu,tu2}
 elseif c=="u" then
  lines={
      left,top,left,tu15,
      left,tu15,luh,tu2,
      luh,tu2,lu15,tu2,
      lu15,tu2,lu2,tu15,
      lu2,tu15,lu2,top}
 elseif c=="v" then
  lines={
      left,top,lu,tu2,
      lu2,top,lu,tu2
      }
 elseif c=="w" then
  lines={
      left,top,left,tu2,
      left,tu2,lu,tu,
      lu,tu,lu2,tu2,
      lu2,tu2,lu2,top
      }
 elseif c=="x" then
  lines={
      left,top,lu2,tu2,
      lu2,top,left,tu2
      }
 elseif c=="y" then
  lines={
      left,top,lu,tu,
      lu,tu,lu2,top,
      lu,tu,lu,tu2
      }
 elseif c=="z" then
  lines={
      left,top,lu2,top,
      lu2,top,left,tu2,
      left,tu2,lu2,tu2
      }
 elseif c=="+" then
  lines={
      luh,tu,lu15,tu,
      lu,tuh,lu,tu15
      }
 elseif c=="." then
  lines={
      lu,tu2,lu,tu15
      }
 elseif c=="-" then
  lines={
      luh,tu,lu15,tu
      }
 elseif c=="/" then
  lines={
      lu2,top,left,tu2
      }
 elseif c=="=" then
  lines={
      left,tuh,lu2,tuh,
      left,tu15,lu2,tu15
      }
 elseif c=="!" then
  lines={
      lu,top,lu,tu,
      lu,tu15,lu,tu2
      }
 elseif c=="&" then
  lines={
      luh,tuh,lu,top,
      lu,top,lu15,tuh,
      lu15,tuh,luh,tu15,
      luh,tuh,lu2,tu2,
      luh,tu15,lu,tu2,
      lu,tu2,lu15,tu2,
      lu15,tu2,lu2,tu15
      }
 else
  lines={}
 end
 
 draw_lines(lines,col)
end
-->8
--stars


function init_stars()
	star_count=100

	stars={}

 -- draw middle and far stars
 for i=1,star_count do
  local layer=flr(rnd(3))+1 -- 1=far,2=middle,3=near
  add(stars,{
   x=rnd(smax), -- random x position
   y=rnd(smax), -- random y position
   layer=layer, -- star layer
   col=(layer==1 and 1) or
   				(layer==2 and 13) or
       7, -- color based on layer
  })
 end
end

function update_stars(dx,dy)
 for star in all(stars) do
  -- handle wrapping for dx and dy
  if abs(dx) > smax/2 then
   dx = (dx + smax) % smax - smax
  end
  if abs(dy) > smax/2 then
   dy = (dy + smax) % smax - smax
  end

  -- move stars opposite to player
  local speed=
     (star.layer==1 and 0) 
     or (star.layer==2 and 0.2)
     or 0.5

  star.x,star.y=
    (star.x-dx*speed+smax)%smax,
    (star.y-dy*speed+smax)%smax
 end
end

function draw_stars()
 for star in all(stars) do
  local close_to_ship= 
   (star.x >= ship.minx) and
   (star.x <= ship.maxx) and
   (star.y >= ship.miny) and
   (star.y <= ship.maxy)
  --if close_to_ship then
  -- print_table(ship.rotated_points)
  -- stop("star.x="..star.x..",y="..star.y)
  --end
  if (not close_to_ship)
  then
   local close_to_rock
   for rock in all(rocks) do
    close_to_rock=
		   (star.x >= rock.minx) and
		   (star.x <= rock.maxx) and
		   (star.y >= rock.miny) and
		   (star.y <= rock.maxy)
		  if close_to_rock then
		   break
		  end
   end
   if (not close_to_rock) then
		  for dx in all({-smax,0,smax}) do
		   for dy in all({-smax,0,smax}) do
		    if abs(star.x+dx-ship.x)<80 and
		       abs(star.y+dy-ship.y)<80
	     then
	      pset(star.x+dx,
		          star.y+dy,
		          star.col)
	     end
		   end
		  end
   end
  end
 end
end

-->8
-- particle explosion
function create_parts(
   xmin,ymin,xmax,ymax,
   plife,pspeed,
   pcolmin,pcolmax)

 camera()
 
	local llife=plife or 3
	local lspeed=pspeed or 8
	local lcolmin=pcolmin or 7
	local lcolmax=pcolmax or 15
	
 -- coords s/b screen coords

 -- cx & cy are relative 
 -- to ship pos (world coords)
 local cx=ship.x-64
 local cy=ship.y-64
 
 -- draw the rectangle for debugging
 --rect(xminx, yminy, xmaxx, ymaxy, lcolmin)
 --stop("debug: rect drawn at ("
 --  ..xmin-cx..","..ymin-cy..","..xmax-cx..","..ymax-cy..")")

 for x=xmin,xmax do
  for y=ymin,ymax do
    
   colour=pget(x,y)
   --[[
   log("x,y,col="
       ..x..","
       ..y..","
       ..colour)
   --]]

   if colour >=lcolmin
   and colour <= lcolmax then
	   dx = rnd(lspeed)-lspeed/2
	   dy = rnd(lspeed)-lspeed/2 
	               
	   local p = {
	     x=x+cx, -- add real world coords
	     y=y+cy, -- add real world coords
	     dx=dx,
	     dy=dy,
	     life=rnd(llife*2)-llife,
	     colour=colour
	   }
	
		  add(parts,p)
	   --log("added part#"..#parts.." "..flr(p.x)..","..flr(p.y))
   end
  end
 end
 --[[
 log("x1,y1="
   ..xmin..","
   ..ymin
   ,10,90,7)
 log("x2,y2="
   ..xmax..","
   ..ymax
   ,10,100,7)
 --stop("parts:"..#parts)
 --]]
 camera(cam_x,cam_y)
end

function update_parts()
 for p in all(parts) do
  if not update_part(p) then
   del(parts,p)
   --log("deleted part:"..
   --    flr(p.x)..","..flr(p.y))
  end
 end
end

function draw_parts()
 --print(#parts,0,0,11)

 --for p in all(parts) do
 for i,p in ipairs(parts) do
  draw_part(p,i)
 end
 --if (#parts>0) stop()
end

function update_part(p)
 p.x+=p.dx
 p.y+=p.dy
 p.life-=1
 if (p.life<0) return false
 return true
end

function draw_part(p,i)
 for dx in all({-smax, 0, smax}) do
  for dy in all({-smax, 0, smax}) do
   pset(p.x+dx,p.y+dy,p.colour)
   --[[
   log("draw part #"
       ..i.." "
       ..flr(p.x)+dx
       ..","
       ..flr(p.y)+dy
       ..","
       ..flr(p.colour)
       )
   --]]
  end
 end
end


-->8
-- minimap handling

function init_minimap()
  mx1=127-smax\10
  mx2=mx1+smax\10
  my1=127-smax\10
  my2=my1+smax\10
  --[[
  stop(mx1..","..
       my1..","..
       mx2..","..
       my2)
  --]]
end

-- mini map
function draw_minimap()
 -- draw inner frame
 rect(mx1+smax/4/10,
      my1+smax/4/10,
      mx1+smax/4*3/10,
      my1+smax/4*3/10,7)
 
 -- draw rocks
 for rock in all(rocks) do
  draw_mapobj(rock.minx,
              rock.miny,
              rock.maxx,
              rock.maxy,
              rock.col)
 end

 -- draw saucers
 for scr in all(saucers) do
  draw_mapobj(scr.minx,
              scr.miny,
              scr.maxx,
              scr.maxy,
              12)
  --stop(scr.x..","..scr.minx..","..scr.maxx)
  --[[
  print("scrmmap:x1="
   ..scr.minx
   ..",y1="
   ..scr.miny,0,10)
  print(",x2="
   ..scr.maxx
   ..",y2="
   ..scr.maxy,0,20)
  --]]
 end
  
 -- draw ship
 draw_mapobj(ship.minx,
             ship.miny,
             ship.maxx,
             ship.maxy,7)         

 -- draw outer frame
 rect(mx1,my1,mx2,my2,8)
end

function draw_mapobj(x1,y1,x2,y2,col)
 -- calculate relative positions based on the ship's position
 local rel_x1,
       rel_y1,
       rel_x2,
       rel_y2=
   (128+x1-ship.x+smax)%smax,
   (128+y1-ship.y+smax)%smax,
   (128+x2-ship.x+smax)%smax,
   (128+y2-ship.y+smax)%smax

 -- mini-map scale (assumes 256 world / 10 = 25.6 map)
 local scale=10

 -- calculate map positions
 local ox1,oy1,ox2,oy2=
   flr(rel_x1/scale),
   flr(rel_y1/scale),
   flr(rel_x2/scale),
   flr(rel_y2/scale)

 -- normal case: no wrapping
 if rel_x1<=rel_x2 and rel_y1<=rel_y2 then
  rect(mx1+ox1,my1+oy1,mx1+ox2,my1+oy2,col)

 -- horizontal wrap only
 elseif rel_x1>rel_x2 and rel_y1<=rel_y2 then
  rect(mx1+ox1,my1+oy1,mx1+flr((smax-1)/scale),my1+oy2,col)
  rect(mx1,my1+oy1,mx1+ox2,my1+oy2,col)

 -- vertical wrap only
 elseif rel_x1<=rel_x2 and rel_y1>rel_y2 then
  rect(mx1+ox1,my1+oy1,mx1+ox2,my1+flr((smax-1)/scale),col)
  rect(mx1+ox1,my1,mx1+ox2,my1+oy2,col)

 -- both horizontal and vertical wrap
 else
  rect(mx1+ox1,my1+oy1,mx1+flr((smax-1)/scale),my1+flr((smax-1)/scale),col)
  rect(mx1,my1+oy1,mx1+ox2,my1+flr((smax-1)/scale),col)
  rect(mx1+ox1,my1,mx1+flr((smax-1)/scale),my1+oy2,col)
  rect(mx1,my1,mx1+ox2,my1+oy2,col)
 end
end
-->8
-- saucer handling --
function init_saucers()
 gdrawscr=false
 
 saucers={}

 scr_types={
  big=1,
  small=2
 }

 scr_points={200,500}
 
 scr_states={
  intact=1,
  destroyed=2
 }
 
 scr_dirs={
  lr=1, -- left to right
  rl=2, -- right to left
  tb=3, -- top to bottom
  bt=4  -- bottm to top
 }
  
 scr_dir={scr_dirs.lr,
          scr_dirs.rl,
          scr_dirs.tb,
          scr_dirs.bt}
          
 scr_bul_delay=60
end

function new_saucer(_stype)
 local sdir=rnd(scr_dir)
 local dirx,diry,sx,sy,svx,svy
 if sdir==scr_dirs.lr then
  dirx=1
  diry=rnd({-1,1})
  sx=(ship.x-smax/2)%smax
  sy=rnd(smax)
  svx=scr_max_speed*dirx
  svy=svx
  --((svx/2)+rnd(svx/2))*diry
 elseif sdir==scr_dirs.rl then
  dirx=-1
  diry=rnd({-1,1})
  sx=(ship.x+smax/2)%smax
  sy=rnd(scr_max)
  svx=scr_max_speed*dirx
  svy=svx
  --((svx/2)+rnd(svx/2))*diry
 elseif sdir==scr_dirs.tb then
  dirx=rnd({-1,1})
  diry=1
  sx=rnd(scr_max)
  sy=(ship.y-smax/2)%smax
  svy=scr_max_speed*diry
  svx=svy
  --((svy/2)+rnd(svy/2))*dirx
 elseif sdir==scr_dirs.bt then
  dirx=rnd({-1,1})
  diry=-1
  sx=rnd(scr_max)
  sy=(ship.y+smax/2)%smax
  svy=scr_max_speed*diry
  svx=svy
  --((svy/2)+rnd(svy/2))*dirx
 end

 local scr={
  x=sx,
  y=sy,
  lx=0,
  ly=0,
  dx=0,
  dy=0,
  vx=svx,
  vy=svy,
  bul_delay=0,
  dir=sdir,
  state=scr_states.intact,
  points={},
  stype=_stype,
  trans_points=saucer_trans_points,
  explode=saucer_explode,
  draw=saucer_draw,
  update=saucer_update
 }
 
 if _stype==scr_types.big then
  add(scr.points,{x=-6,y=0})
  add(scr.points,{x=-4,y=-2})
  add(scr.points,{x=2,y=-2})
  add(scr.points,{x=-2,y=-2})
  add(scr.points,{x=0,y=-4})
  add(scr.points,{x=2,y=-2})
  add(scr.points,{x=4,y=-2})
  add(scr.points,{x=6,y=0})
  add(scr.points,{x=-6,y=0})
  add(scr.points,{x=6,y=0})
  add(scr.points,{x=4,y=2})
  add(scr.points,{x=-4,y=2})
  scr.rminx=-6 -- rel minx
  scr.rmaxx=6  -- rel miny
  scr.rminy=-4 -- rel maxx
  scr.rmaxy=2  -- rel maxy
  scr.angvar=0.028 -- 10 deg
  sfx(sfx_scrbig,sfx_chl.saucer)
 else -- small saucer
  add(scr.points,{x=-4,y=0})
  add(scr.points,{x=-2,y=-2})
  add(scr.points,{x=1,y=-2})
  add(scr.points,{x=-1,y=-2})
  add(scr.points,{x=0,y=-3})
  add(scr.points,{x=1,y=-2})
  add(scr.points,{x=2,y=-2})
  add(scr.points,{x=4,y=0})
  add(scr.points,{x=-4,y=0})
  add(scr.points,{x=4,y=0})
  add(scr.points,{x=2,y=2})
  add(scr.points,{x=-2,y=2})
  scr.rminx=-3 -- rel minx
  scr.rmaxx=3  -- rel maxx
  scr.rminy=-3 -- rel miny
  scr.rmaxy=2  -- rel maxy
  scr.angvar=0.0139 -- 5 deg
  sfx(sfx_scrsml,sfx_chl.saucer)
 end
 scr.minx=sx+scr.rminx
 scr.maxx=sx+scr.rmaxx
 scr.miny=sy+scr.rminy
 scr.maxy=sy+scr.rmaxy
 add(saucers,scr)
 --print("scr spwned:x="
 --  ..scr.x
 --  ..",y="
 --  ..scr.y
 --  ,0,0)
 --stop(
 -- ",dir="
 --  ..scr.dir
 --  ..",vx="
 --  ..scr.vx
 --  .."vy="
 --  ..scr.vy,0,10)
end

function saucer_trans_points(scr)
 local points_transformed={}

 -- pick saucer points that
 -- are outline of polygon
 scr_pts={1,2,4,5,6,7,8,11,12}
 
 -- transform all points based on position, size, and rotation
 for i in all(scr_pts) do
  -- apply rotation to the point
  local sx = scr.x+scr.points[i].x
  local sy = scr.y+scr.points[i].y

  add(points_transformed, 
    {x=sx, y=sy})
 end

 return points_transformed
end

function saucer_explode(scr)
 sfx(sfx_scrxpl,sfx_chl.saucer)
 scr.state=scr_states.destroyed
end

function saucer_draw(scr)
 --stop("saucer draw:npts="..npts)
 --camera()
 --print("scr.x="..scr.x..",y="..scr.y..",dir="..scr.dir,0,0,7)
 --print("scr.dx="..scr.dx..",dy="..scr.dy,0,10,7)
 --camera(cam_x,cam_y)
 
 --gdrawscr=false
 
 --[[ debug - draw fire box
 if fal then
	 rect(scr.x-50,scr.y-50,
       scr.x+50,scr.y+50,11)
 end
 --]]
      
 if scr.state==scr_states.destroyed then
  circfill(scr.x,scr.y,10,12)
  --stop()
  create_parts(
    abs(scr.minx-10-ship.x+64+smax)%smax,
    abs(scr.miny-10-ship.y+64+smax)%smax,
    abs(scr.maxx+10-ship.x+64+smax)%smax,
    abs(scr.maxy+10-ship.y+64+smax)%smax,
    50, --life
    4,   --speed
    12,12  --color 7 (ship only)
    )
  del(saucers,scr)
  return
 end

 for dx in all({-smax, 0, smax}) do
  for dy in all({-smax, 0, smax}) do
   local draw_saucer =
    (abs(scr.x+dx-ship.x)<80) and
    (abs(scr.y+dy-ship.y)<80)
   
   if draw_saucer then 
 			--gdrawscr=draw_saucer
    local npts=#scr.points
    for i = 1,npts  do
     local p1,p2=
       scr.points[i],
       scr.points[(i%npts)+1]
       
     line(p1.x+scr.x+dx,
          p1.y+scr.y+dy,
          p2.x+scr.x+dx,
          p2.y+scr.y+dy,12) -- bright blue
	    --[[
	    if dx==0 and dy==0 then
		    print("scrdraw:x1="
		       ..p1.x+scr.x+dx
		       ..",y1="
		       ..p1.y+scr.y+dy
		       ,0,i*8,7)
		   end
		   --]]
    end
   end
  end     
 end
end

function saucer_update(scr)
 scr.x+=scr.vx
 scr.y+=scr.vy
 scr.lx+=scr.vx
 scr.ly+=scr.vy
 
 --stop("scrupd:x="
 --  ..scr.x
 --  ..",y="
 --  ..scr.y)
 
 if (scr.dir==scr_dirs.lr 
   or scr.dir==scr_dirs.rl)
 then
  if abs(scr.lx)<smax then
   goto cont
  else
	  scr.dx=min(
	     abs(scr.x-ship.x), 
	     smax-abs(scr.x-ship.x))
	 end
 end

 if (scr.dir==scr_dirs.tb 
   or scr.dir==scr_dirs.bt)
 then
  if abs(scr.ly)<smax then
   goto cont
  else
	  scr.dy=min(
	     abs(scr.y-ship.y), 
	     smax-abs(scr.y-ship.y))
  end
 end
  
 if scr.dir==scr_dirs.lr 
 then  
  if scr.dx>=smax/2-scr.vx then
   --print"\a"
   del(saucers, scr)
   sfx(-1,sfx_chl.saucer)
   return
  end
 elseif scr.dir==scr_dirs.rl 
 then
  if scr.dx>=smax/2+scr.vx then
   --print"\a"
   del(saucers, scr)
   sfx(-1,sfx_chl.saucer)
   return
  end
 elseif scr.dir==scr_dirs.tb 
 then 
  if scr.dy>=smax/2-scr.vy then
   --print"\a"
   del(saucers,scr)
   sfx(-1,sfx_chl.saucer)
   return
  end
 elseif scr.dir==scr_dirs.bt
 then 
  if scr.dy>=smax/2+scr.vy then
   --print"\a"
   del(saucers,scr)
   sfx(-1,sfx_chl.saucer)
   return
  end
 else
  stop("invalid scr dir:"..scr.dir)
 end

 ::cont::
 
 -- handle wrapping of coords
 scr.x,scr.y=
   (scr.x+smax)%smax, 
   (scr.y+smax)%smax 

 scr.minx,
 scr.maxx,
 scr.miny,
 scr.maxy=
   scr.x+scr.rminx,
   scr.x+scr.rmaxx,
   scr.y+scr.rminy,
   scr.y+scr.rmaxy
 
 -- check for rock collisions
 for rock in all(rocks) do
  -- check for possible collision
  local rock = poss_collision(
    scr.minx,
    scr.miny,
    scr.maxx,
    scr.maxy,
    rocks)
  
  if rock then
   if collision(
    scr:trans_points(), 
    rock:trans_points()) 
   then
    scr:explode()
    rock:divide()
    return
   end
  end
 end

 -- check for rocks nearby
 if scr.bul_delay > 0 then
  scr.bul_delay-=1
 else
	 local rock=poss_collision(
	    scr.x-50,
	    scr.y-50,
	    scr.y+50,
	    scr.y+50,
	    rocks)
	     
  if rock then
   local dx=(rock.x-scr.x+smax)%smax
   if (dx>smax/2) dx-=smax

   local dy=(rock.y-scr.y+smax)%smax
   if (dy>smax/2) dy-=smax
   
   local ang=atan2(
     rock.y-scr.y,rock.x-scr.x)
   ang=-ang-0.25-(rnd({1,-1})*scr.angvar)
   
   local b = new_bullet(
    scr,ang,scr.speed,scr.x,scr.y)
   -- move bullet twice so that
   -- it starts outside ship
   -- move_bullet(b)
   -- move_bullet(b)
   sfx(sfx_scrfire,sfx_chl.bullets)
   scr.bul_delay=scr_bul_delay
  end
	end
 
	-- check for ships nearby
 if scr.bul_delay > 0 then
  scr.bul_delay-=1
 else
	 local s=poss_collision(
	    ship.minx-50,
	    ship.miny-50,
	    ship.maxx+50,
	    ship.maxy+50,
	    {scr})
	     
  if s then
   local dx=(ship.x-scr.x+smax)%smax
   if (dx>smax/2) dx-=smax

   local dy=(ship.y-scr.y+smax)%smax
   if (dy>smax/2) dy-=smax

   local ang=atan2(dy,dx)
   ang=-ang-0.25-(rnd({1,-1})*scr.angvar)
   
   --debug--
   -- stop the saucer
   --scr.vx=0
   --scr.vy=0
   --------
   
   local b = new_bullet(
    scr,ang,scr.speed,scr.x,scr.y)
   -- move bullet so that
   -- it starts outside ship
   --stop("scr.bx,by="..b.x..","..b.y)
   
   --move_bullet(b)
   scr.bul_delay=scr_bul_delay
   sfx(sfx_scrfire,sfx_chl.bullets)
  end
	end
end

function spawn_saucers()
 if (#saucers>0) return

 for st=scr_types.big,
        scr_types.small do
   --stop("scr_spwn_rate["..st.."]="..scr_spwn_rate[st])
   local spawn=flr(rnd(
      scr_spwn_rate[st]))
   --stop("spawm:"..spawn)
   if flr(spawn)==0 then
    local sx=(smax+ship.x)%smax
    new_saucer(st,
       rnd({ship.x-smax,ship.xsmax}),
       rnd(127))
   end
 end
end


function update_saucers()
 for scr in all(saucers) do
  scr:update()
 end
 
 -- increase saucer spawn 
 -- as wave proceeds
 scr_spwn_rate[1]=max(
    scr_spwn_rate[1]-
    scr_spwn_rate_red,100)
 scr_spwn_rate[2]=max(
    scr_spwn_rate[2]-
    scr_spwn_rate_red,100)
end

function draw_saucers()
 for scr in all(saucers) do
  scr:draw()
 end
 
 --[[ debug
	 camera()
	 print("scr_spwn_rate:"
	       ..scr_spwn_rate[1]
	       ,4,112,8)
	 print(scr_spwn_rate[2],
	       4,120,8)
	 camera(cam_x,cam_y)
	--]]
end
-->8
-- hi scores
function init_hiscores()
 hsname={".",".","."}
 
 hsentpos=1
 hschars=" abcedfghijklmnopqrstuvwxyz!&-+=./"
 
 hiscores,
 hiscore_delay,
 hiscore_timer,
 hiscore_idx={},150,150,4

 --dset(0,0) -- force reset of hiscores
 
 load_hiscores()
end

function reset_hiscores()
 hiscores={}
 for i=1,10 do
  local _score=(11000-
          (i*1000))*0x.0001
  local hiscore={
    score=_score,
    name=chr(96+i,96+i,96+i)
  }
  add(hiscores,hiscore)
 end
end

function load_hiscores()
 if dget(0)==0 then
  reset_hiscores()
  save_hiscores()
 else
  hiscores={}
  for i=1,10 do
   local _score=dget(i)
   local _name=chr(dget(10+i),
    dget(20+i),dget(30+i))
   local hiscore={
     score=_score,
     name=_name
   }
   add(hiscores,hiscore)
  end
 end  
 sort_hiscores()
end

function save_hiscores()
 dset(0,1)
 local num=0
 for hs in all(hiscores) do
  num+=1
  dset(num,hs.score)
  dset(num+10,ord(hs.name[1]))
  dset(num+20,ord(hs.name[2]))
  dset(num+30,ord(hs.name[3]))
 end
end

function sort_hiscores()
 qsort(hiscores,
   function(a,b)
    --print("scoreab="..a.score..","..b.score)
    return a.score>b.score
   end
 )  
-- print_table(hiscores)
-- stop()
end

function print_hiscores(idx,cnt,y)
 idx=idx or 1
 cnt=cnt or 5
 
 local num=0
 local x=30
 local y=y or 70
 
 shprint("high scores",x+10,y,12,1,fal)
 local ctr=0
 for hs in all(hiscores) do
  num+=1

  if (idx>num and num>3) goto cont
  
  ctr+=1

  if (ctr>cnt or cnt>7) break

		local hscol1,hscol2=
		   num<4 and 11 or 12,
		   num<4 and 3 or 1
  
  shprint(num..".",x,y+ctr*8,hscol1,hscol2,fal)

		local dscr=tostr(hs.score,0x2)
		while #dscr < 6 do
		 dscr="0"..dscr
		end
		   
		shprint(hs.name,x+12,y+ctr*8,hscol1,hscol2,false) 
		shprint(dscr,x+40,y+ctr*8,hscol1,hscol2,false) 
	 ::cont::
	end
end

function new_hiscore()
 return score>hiscores[#hiscores].score
end

function charpos(hschar)
 result=0
 for i=1,#hschars do
  if hschars[i]==hschar then
   result=i
   break
  end
 end
 return result
end

function enter_new_hiscore()
 local dirv,dirh=0,0
 if (btnp(⬆️)) dirv=1
 if (btnp(⬇️)) dirv=-1
 
 local hscharidx=charpos(hsname[hsentpos])
 hscharidx=hscharidx+dirv
 if (hscharidx<1) hscharidx=#hschars
 if (hscharidx>#hschars) hscharidx=1
 hsname[hsentpos]=hschars[hscharidx]
 
 if (btnp(⬅️)) dirh=-1
 if (btnp(➡️)) dirh=1
 hsentpos=max((hsentpos+dirh)%4,1)
 
 if (btnp(🅾️)) then
  add(hiscores,{score=score,name=hsname[1]..hsname[2]..hsname[3]})
  sort_hiscores()
  del(hiscores,hiscores[11]) 
  save_hiscores()
  set_gamestate(gs.over)
 end
end

function draw_new_hiscore()
 vector_print("well done!",8,20,12,0.5)
 vector_print("you have achieved",1,40,12,0.3)
 vector_print("a top ten score!",8,50,12,0.3)
 vector_print("enter your name",9,70,12,0.3)
 shprint("use ⬆️⬇️⬅️➡️ and 🅾️ when done",10,120,12,1)
 
 if (flr(t()*10%5)!=0) then
  if(hsentpos==1) rect(5,78,42,113,7)
  if (hsentpos==2) rect(44,78,82,113,7)
  if (hsentpos==3) rect(83,78,122,113,7)
 end
 
 vector_char(hsname[1],
              8,80,12,1.6)
 vector_char(hsname[2],
              48,80,12,1.6)
 vector_char(hsname[3],
              88,80,12,1.6)
end
__gfx__
00000000000000000077777707777777777700000000000000007777777777700000000000000000000000000000000777777000000000000000007777777000
00000000000000000777777707777777777770000000000000007777777777770000000000000000000000000000007777777000000000000000077777777000
000000000000000077cccc77077ccccccccc770000000000000077ccccccccc77000000000000000000000000000077ccccc700000000000000077ccccc77000
00000000000000077ccccc77077cccccccccc77000000000000077cccccccccc770000000000000000000000000077ccccc770000000000000077ccccc770000
0000000000000077ccccc770077ccc777ccccc7700000000000077ccc777ccccc7700000000000000000000000077ccccc770000000000000077ccccc7700000
000000000000077ccccc7700077ccc7777ccccc770000000000077ccc7777ccccc77000000000000000000000077ccccc770000000000000077ccccc77000000
00000000000077ccccc77000077ccc77077ccccc77000000000077ccc77077ccccc770000000000000000000077ccccc770000000000000077ccccc770000000
0000000000077ccccc770000077ccc770077ccccc7700000000077ccc770077ccccc7700000000000000000077ccccc770000000000000077ccccc7700000000
000000000077ccccc7700000077ccc7700077ccccc770000000077ccc7700077ccccc77000000000000000077ccccc770000000000000077ccccc77000000000
00000000077ccccc77000000077ccc77000077ccccc77000000077ccc77000077ccccc770000000000000077ccccc770000000000000077ccccc770000000000
0000000077ccccc770000000077ccc770000077ccccc7700000077ccc770000077ccccc7700000000000077ccccc770000000000000077ccccc7700000000000
000000077ccccc7700000000077ccc7700000077ccccc770000077ccc7700000077ccccc77000000000077ccccc770000000000000077ccccc77000000000000
00000077ccccc77000000000077ccc77000000077ccccc77000077ccc77000000077ccccc770000000077ccccc770000000000000077ccccc770000000000000
0000077ccccc770000000000077ccc770000000077ccccc7700077ccc770000000077ccccc7700000077ccccc770000000000000077ccccc7700000000000000
000077ccccc7700000000000077ccc7700000000077ccccc770077ccc7700000000077ccccc77000077ccccc770000000000000077ccccc77000000000000000
00077ccccc77000000000000077ccc77000000000077ccccc77077ccc77000000000077ccccc770077ccccc770000000000000077ccccc770000000000000000
0077ccccc770000000000000077ccc77000000000077ccccc77077ccc77000000000077ccccc77077ccccc770000000000000077ccccc7700000000777777000
077ccccc7700000000000000077ccc7700000000077ccccc770077ccc7700000000077cccccc77077cccc7700000000000000077cccc77000000007777777000
0077ccccc770000000000000077ccc770000000077ccccc7700077ccc770000000077ccccccc77077ccc77000000000000000077ccc770000000077ccccc7000
00077ccccc77000000000000077ccc77000000077ccccc77000077ccc77000000077cccccccc77077ccc77000000000000000077ccc77000000077ccccc77000
000077ccccc7700000000000077ccc7700000077ccccc770000077ccc7700000077ccccc7ccc77077ccc77000000000000000077ccc7700000077ccccc770000
0000077ccccc770000000000077ccc770000077ccccc7700000077ccc770000077ccccc77ccc77077ccc77000000000000000077ccc770000077ccccc7700000
00000077ccccc77000000000077ccc77000077ccccc77000000077ccc77000077ccccc777ccc77077ccc77000000000000000077ccc77000077ccccc77000000
000000077ccccc7700000000077ccc7700077ccccc770000000077ccc7700077ccccc7777ccc77077ccc77000000000000000077ccc7700077ccccc770000000
0000000077ccccc770000000077ccc770077ccccc7700000000077ccc770077ccccc77077ccc77077ccc77000000000000000077ccc770077ccccc7700000000
00000000077ccccc77000000077ccc77077ccccc77000000000077ccc77077ccccc770077ccc77077ccc77000000000000000077ccc77077ccccc77000000000
000000000077ccccc7700000077ccc7777ccccc770000000000077ccc7777ccccc7700077ccc77077ccc77000000000000000077ccc7777ccccc770000000000
0000000000077ccccc770000077ccc777ccccc7700000000000077ccc777ccccc77000077ccc77077ccc77000000000000000077ccc777ccccc7700000000000
00000000000077ccccc77000077ccc77ccccc77000000000000077ccc77ccccc770000077ccc77077ccc77000000000000000077ccc77ccccc77000000000000
000000000000077ccccc7700077ccc7ccccc770000000000000077ccc7ccccc7700000077ccc77077ccc77000000000000000077ccccccccc770000000000000
0000000000000077ccccc700077cccccccc7700000000000000077cccccccc77000000077ccc77077ccc77000000000000000077cccccccc7700000000000000
000000000000077ccccc7700077ccccccc77000000000000000077ccccccc770000000077ccc77077cccc7700000000000000077ccccccc77000000000000000
00000000000077ccccc77000077cccccc770000000000000000077cccccc7700000000077ccc77077ccccc770000000000000077cccccc770000000000000000
0000000000077ccccc770000077ccccc7700000000000000000077ccccc77000000000077ccc770077ccccc77000000000000077ccccc7700000077777770000
000000000077ccccc7700000077cccc77000000000000000000077cccc770000000000077ccc7700077ccccc7700000000000077cccc77000000777777770000
00000000077ccccc77000000077ccc770000000000000000000077ccc7700000000000077ccc77000077ccccc770000000000077ccc7700000077ccccc770000
0000000077ccccc770000000077ccc770000000000000000000077ccc7700000000000077ccc770000077ccccc77000000000077ccc770000077ccccc7700000
000000077ccccc7700000000077ccc770000000000000000000077ccc7700000000000077ccc7700000077ccccc7700000000077ccc77000077ccccc77000000
00000077ccccc77000000000077ccc770000000000000000000077ccc7700000000000077ccc77000000077ccccc770000000077ccc7700077ccccc770000000
0000077ccccc770000000000077ccc770000000000000000000077ccc7700000000000077ccc770000000077ccccc77000000077ccc770077ccccc7700000000
000077ccccc7700000000000077ccc770000000000000000000077ccc7700000000000077ccc7700000000077ccccc7700000077ccc77077ccccc77000000000
00077ccccc77000000000000077ccc770000000000000000000077ccc7700000000000077ccc77000000000077ccccc770000077ccc7777ccccc770000000000
0077ccccc770000000000000077ccc770000000000000000000077ccc7700000000000077ccc770000000000077ccccc77000077ccc777ccccc7700000000000
077ccccc7700000000000000077ccc770000000000000000000077ccc7700000000000077ccc7700000000000077ccccc7700077ccc77ccccc77000000000000
77ccccc77000000000000000077ccc770000000000000000000077ccc7700000000000077ccc77000000000000077ccccc770077ccccccccc770000000000000
77cccc770000000000000000077ccc770000000000000000000077ccc7700000000000077ccc770000000000000077ccccc77077cccccccc7700000000000000
777777700000000000000000077777770000000000000000000077ccc7700000000000077ccc7700000000000000077cccc77077ccccccc77000000000000000
77777700000000000000000007777777000000000000000000007777777000000000000777777700000000000000007777777077777777770000000000000000
00000000000000000000000000000000000000000000000000007777777000000000000777777700000000000000000777777077777777700000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07777777777770000000000000000000000000000000000777777700000000000000000777777077777770000000007777770000000000000000000777777000
07777777777770000000000000000000000000000000007777777700000000000000007777777077777770000000077777770000000000000000007777777000
077ccccccccc77000000000000000000000000000000077ccccc7700000000000000077ccccc7077ccc77000000077ccccc70000000000000000077cccc77000
077cccccccccc770000000000000000000000000000077cccccc770000000000000077ccccc77077ccc7700000077ccccc77000000000000000077ccccc77000
077ccc777ccccc7700000000000000000000000000077ccccccc77000000000000077ccccc770077ccc770000077ccccc77000000000000000077ccccc770000
077ccc7777ccccc77000000000000000000000000077cccccccc7700000000000077ccccc7700077ccc77000077ccccc77000000000000000077ccccc7700000
077ccc77077ccccc770000000000000000000000077ccccc7ccc770000000000077ccccc77000077ccc7700077ccccc77000000000000000077ccccc77000000
077ccc770077ccccc7700000000000000000000077ccccc77ccc77000000000077ccccc770000077ccc770077ccccc77000000000000000077ccccc770000000
077ccc7700077ccccc77000000000000000000077ccccc777ccc7700000000077ccccc7700000077ccc77077ccccc77000000000000000077ccccc7700000000
077ccc77000077ccccc770000000000000000077ccccc7777ccc770000000077ccccc77000000077ccc7777ccccc77000000000000000077ccccc77000000000
077ccc770000077ccccc7700000000000000077ccccc77077ccc77000000077ccccc770000000077ccc777ccccc77000000000000000077ccccc770000000000
077ccc7700000077ccccc77000000000000077ccccc770077ccc7700000077ccccc7700000000077ccc77ccccc77000000000000000077ccccc7700000000000
077ccc77000000077ccccc770000000000077ccccc7700077ccc770000077ccccc77000000000077ccc7ccccc77000000000000000077ccccc77000000000000
077ccc770000000077ccccc7700000000077ccccc77000077ccc77000077ccccc770000000000077cccccccc77000000000000000077ccccc770000000000000
077ccc7700000000077ccccc77000000077ccccc770000077ccc7700077ccccc7700000000000077ccccccc77000000000000000077ccccc7700000000000000
077ccc77000000000077ccccc770000077ccccc7700000077ccc770077ccccc77000000000000077cccccc77000000000000000077ccccc77000000000000000
077ccc77000000000077ccccc77000077ccccc77000000077ccc77077ccccc770000000000000077ccccc77000000000000000077ccccc770000000000000000
077ccc7700000000077ccccc77000077ccccc770000000077ccc77077cccc7700000000000000077cccc77000000000000000077ccccc7700000000000000000
077ccc770000000077ccccc77000077ccccc7700000000077ccc77077ccc77000000000000000077ccc7700000000000000000077ccccc770000000000000000
077ccc77000000077ccccc77000077ccccc77000000000077ccc77077ccc77000000000000000077ccc77000000000000000000077ccccc77000000000000000
077ccc7700000077ccccc770000077cccc770000000000077ccc77077ccc77000000000000000077ccc770000000000000000000077ccccc7700000000000000
077ccc770000077ccccc7700000077ccc7700000000000077ccc77077ccc77000000000000000077ccc7700000000000000000000077ccccc770000000000000
077ccc77000077ccccc77000000077ccc7700000000000077ccc77077ccc77000000000000000077ccc77000000000000000000000077ccccc77000000000000
077ccc7700077ccccc770000000077ccc7700000000000077ccc77077ccc77000000000000000077ccc770000000000000000000000077ccccc7700000000000
077ccc770077ccccc7700000000077ccc7700000000000077ccc77077ccc77000000000000000077ccc7700000000000000000000000077ccccc770000000000
077ccc77077ccccc77000000000077ccc7700000000000077ccc77077ccc77000000000000000077ccc77000000000000000000000000077ccccc77000000000
077ccc7777ccccc770000000000077ccc7700000000000077ccc77077ccc77000000000000000077ccc770000000000000000000000000077ccccc7700000000
077ccc777ccccc7700000000000077ccc7700000000000077ccc77077ccc77000000000000000077ccc7700000000000000000000000000077ccccc770000000
077ccc77ccccc77000000000000077ccc7700000000000077ccc77077ccc77000000000000000077ccc77000000000000000000000000000077ccccc77000000
077ccc7ccccc770000000000000077ccc7700000000000077ccc77077ccc77000000000000000077ccc770000000000000000000000000000077ccccc7700000
077cccccccc7700000000000000077ccc7700000000000077ccc77077ccc77000000000000000077ccc7700000000000000000000000000000077ccccc700000
077cccccccc7700000000000000077ccc770000000000077cccc77077cccc7700000000000000077cccc77000000000000000000000000000077ccccc7700000
077ccccccccc770000000000000077ccc77000000000077ccccc77077ccccc770000000000000077ccccc770000000000000000000000000077ccccc77000000
077ccc77ccccc77000000000000077ccc7700000000077cccccc770077ccccc77000000000000077cccccc7700000000000000000000000077ccccc770000000
077ccc777ccccc7700000000000077ccc770000000077cccccc77000077ccccc7700000000000077ccccccc77000000000000000000000077ccccc7700000000
077ccc7777ccccc770000000000077ccc77000000077cccccc7700000077ccccc770000000000077cccccccc770000000000000000000077ccccc77000000000
077ccc77077ccccc77000000000077ccc7700000077cccccc770000000077ccccc77000000000077ccc7ccccc7700000000000000000077ccccc770000000000
077ccc770077ccccc7700000000077ccc770000077cccccc77000000000077ccccc7700000000077ccc77ccccc77000000000000000077ccccc7700000000000
077ccc7700077ccccc770000000077ccc77000077cccccc7700000000000077ccccc770000000077ccc777ccccc770000000000000077ccccc77000000000000
077ccc77000077ccccc77000000077ccc7700077cccccc770000000000000077ccccc77000000077ccc7777ccccc7700000000000077ccccc770000000000000
077ccc770000077ccccc7700000077ccc770077cccccc77000000000000000077ccccc7700000077ccc77077ccccc77000000000077ccccc7700000000000000
077ccc7700000077ccccc770000077ccc77077cccccc7700000000000000000077ccccc770000077ccc770077ccccc770000000077ccccc77000000000000000
077ccc77000000077ccccc77000077ccc7777cccccc770000000000000000000077ccccc77000077ccc7700077ccccc7700000077ccccc770000000000000000
077ccc770000000077ccccc7700077ccc777cccccc77000000000000000000000077ccccc7700077ccc77000077ccccc77000077ccccc7700000000000000000
077ccc7700000000077ccccc770077ccccccccccc7700000000000000000000000077ccccc770077ccc770000077ccccc770077ccccc77000000000000000000
077ccc77000000000077ccccc77077cccccccccc770000000000000000000000000077ccccc77077ccc7700000077ccccc77077cccc770000000000000000000
077ccc770000000000077cccc77077ccccccccc77000000000000000000000000000077cccc77077ccc77000000077cccc770777777700000000000000000000
07777777000000000000777777707777777777770000000000000000000000000000007777777077777770000000077777770777777000000000000000000000
07777777000000000000077777707777777777700000000000000000000000000000000777777077777770000000007777770777770000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000007000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000700000700000000000000000000000000000000000ccc0ccc0ccc0ccc0ccc0ccc00000000000000000000000000000000000000000000000000000
00000000070700070700000000000000d0000000000000000000c1c1c1c101c1c1c101c1c1c10000000000000000000000000000000000000000000000000000
0000000007070007070000000000000000000000000000000000c1c1c1c1ccc1c1c100c1c1c10000000000000000000000000000000010000000000000000000
0000000070707070707000000000000000000000000000000000c1c1c1c1c111c1c100c1c1c10000000000000000000000000000000000000000000000000000
0000000077077077077000000000000000000000000000000000ccc1ccc1ccc0ccc100c1ccc10000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000111011101110111000101110000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000ffff000000000000000000000000000000000000700000000000000000000000000000000000000
000000000000000000000000000000000000000000000000f0000fff000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000d00000000000000f000000f0000000000000000000d0000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000f0000000f000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000f00000000f000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000f00000000f000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000f0000000f000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000f000000f0000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000ff00000f0000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000fffff00000000000000000000000000000000000000000000000000000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d00000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00000000000000007000000000000000000000000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000070700000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000070700000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000007700070000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000007770000070000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000770000070000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000007700007000000000000000000000000000000000000000000000000000000000000
00000000700000000000000000000000000000000000000000000000000000077007000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000d0000000000000770700000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000007700000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000d000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000ff0ff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000f0000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000f000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000f00f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000ff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000
000000000000000000000ee000000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000
000000000000000000eee00e0000000000000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000
00000000000000000e000000e00000000000000000000000000000000000000000000000000000000000000000000c0c00000088888888888888888888888888
0000000000000000e00000000e0000000000000000000000000000000000000000000000000000000000000000ccccccccc00080000000000000000000000008
0000000000000000e00000000e000000000000000000000000000000000000000000000000000000000000000c000000000c0080000000000000000000000008
00000000000000000e0000000e00000000000000000000000000000000000000000000000000000000000000ccccccccccccc080000000000000000000000008
00000000000000000e0000000e000000000000000000000000000000000000000000000000000000000000000c000000000c0080000000000000000000000008
000000000000000000e000000e0000000000000000000000000000000000000000000000000000000000000000ccccccccc00080000000000000000000000008
0000000000000000000e000ee0000000000000000000000000000000000000000000000000000000000000000000000000000080000077777777777777000008
00000000000000000000eee000000000000000000000000000000000000000000000000000000000000000000000000000000080000070000000000007000008
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000007000ff00000007000008
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000007000ff00000007000008
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080000070000000000007000008
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080000070000000000007000008
00000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000000080000070000077000007000008
00000000000000000000000000000000880800000000000000000000000000000000000000000000000000000000000000000080000070000077000007000008
00000000000000000000000000000008000800000000000000000000000000000000000000000000000000000000000000000080000070000000000007000008
000000000000000000000000000000080008000000000000000000000000000000000000000000000000010000000000000000800000700ff000000007000008
0000000000000000000000000000000800080000000000000000000000000000000000000000000000000000000000000000008000007ee000000cc007000008
0000000000000000000000000000000088800000000000000000000000000000000000000000000000000000000000000000008000007ee800000cc007000088
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000ee70080000000007000088
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000ee77777777777777000008
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080000000000000000010000008
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080000000000000000000000008
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080000000000000000000000008
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080e00000000000000000000008
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080000000000000000000000008
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000088888888888888888888888888

__sfx__
9004000019650196501865018650186501865017650166501565013650106500e6500c6500a650086500465003650026500065000640006400063000630006300062000620006000060000600006000060000000
9004000012650126501265013650126501265012650106500f6500e6500c6500a6500565004650036500365002650026500165001640006400063000630006300062000620006000060000600006000060000000
900400000a6500a6500a6500965008650076500765006650056500465003650026500165000650006500064000640006300062000620006200061000610006000060000600006000060000600006000060000000
900200002c4302c4302b4302a430294302543023430224301e4301c4301843015420114200e4200c4200842007420054200342002420024200142001420014200142001420004200041000400004000000000000
900500000064001640036400364003640036400263001620006100060000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
90020000063500935009350093500534000320003000030000300003000b1000b1000a10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
900200000535006350063500535002340003200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
781000003903039030380003903039030380003903039030370003903039030360000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
120600002265025650266502665027650276502765027650256502465023650226502165021650206501e6501d6501b6501a65019650176401664015640146401363012630106300f6300f6300e6200e6200d620
000400082702027020210202102027020270202102021020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400083803038030350303503038030380303503035030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
120600000665007650066500765006650076500865007650056500465001650006400062001620006100360002600016000060000600006000560005600056000560005600046001260004600036000360002600
900200002c4412b4412a44126441224411b441164510c441074410443103431034210141101401004010040102401004010040100401004010040102401014010140101401014010040000400004000000000000
