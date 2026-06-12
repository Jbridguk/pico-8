pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
function _init()
	cartdata("galaxyinv_jb")
	init_hiscores()
	init_gals()
	init_base()  
	init_blocks()
	new_game()
	gtf=1 -- global time factor, for slowing down time when debugging
	next_wave_delay_max=300
	next_wave_delay=next_wave_delay_max
	score_labels={}
	
	flag_fire_lasers_delay=10
	
	-- Sound Effects
	sfx_fire=0
	sfx_explode=1
	sfx_die=2
	sfx_free_life=3
	sfx_flg_die=4
	sfx_flg_attack=5
	sfx_flg_attack_siren=6
	sfx_flg_fire=7
	sfx_block=8
	sfx_title=10
	sfx_instr=11
	
	-- Game state
	gs_title=0
	gs_instructions=1
	gs_playing=2
	gs_over=3
	gs_newhs=4

	game_over_delay=300
	game_over_delay_cntr=game_over_delay

	game_state=gs_title
	title_sfx_played=false
	title_sfx_active=false
	title_sfx_ch=3
	init_title_edge_blocks()
end	

function init_title_edge_blocks()
	local x_max=126
	local y_max=116
	local spacing=11
	local path_len=(x_max*2)+(y_max*2)
	title_edge={
		spr=13,
		x_max=x_max,
		y_max=y_max,
		count=flr(path_len/spacing)+1,
		spacing=spacing,
		speed=1,
		path_len=path_len,
		offset=0
	}	
end	

function edge_rect_pos(dist)
	local d=dist%title_edge.path_len
	if d<title_edge.x_max then
		return d,0
	elseif d<title_edge.x_max+title_edge.y_max then
		return title_edge.x_max,d-title_edge.x_max
	elseif d<(title_edge.x_max*2)+title_edge.y_max then
		return title_edge.x_max-(d-(title_edge.x_max+title_edge.y_max)),title_edge.y_max
	end	
	return 0,title_edge.y_max-(d-((title_edge.x_max*2)+title_edge.y_max))
end	

function update_title_edge_blocks()
	title_edge.offset=(title_edge.offset+title_edge.speed)%title_edge.path_len
end	

function init_base()
	-- base states
	bst_intact=0
	bst_explod=1
	bst_spawn=2
	
	base={
		x=60,
		y=120,
		sprites={6,7},
		expspr={80,81,82,83,84,85,86,87},
		firing=false,
		spridx=1,
		sprdly=10,
		state=bst_intact
	}
end

function new_game()
	stop_title_sfx()
	init_base()
	gals={}
	wave=0
	setup_next_wave()
	msl={sprite=8}
	bombs={}
	lives=3
	score=0
	free_life_points=10000
	free_life_cntdwn=free_life_points
	
	flag_attack=false
	
	game_over_delay_cntr=game_over_delay

	init_stars()
	start_block_wipe()
end

function setup_next_wave()
	wave+=1
	attackers=0
	create_gals()
	
	if wave==1 then
		gal_attack_chance=500
		gal_attack_chance_min=50
		flg_attack_chance=5000
		flg_attack_duration=900
		bombspd=1
		maxattackers=3
	elseif wave==2 then
		gal_attack_chance=400
		gal_attack_chance_min=30
		flg_attack_chance=5000
		flg_attack_duration=900
		bombspd=1.1
		maxattackers=4
	elseif wave==3 then
		gal_attack_chance=300
		gal_attack_chance_min=20
		flg_attack_chance=4000
		flg_attack_duration=900
		bombspd=1.3
		maxattackers=5
	elseif wave==4 then
		gal_attack_chance=250
		gal_attack_chance_min=15
		flg_attack_chance=3500
		flg_attack_duration=700
		bombspd=1.5
		maxattackers=6
	else
		gal_attack_chance=200
		gal_attack_chance_min=15
		flg_attack_chance=3000
		flg_attack_duration=600
		bombspd=1.5
		maxattackers=7
	end
	gal_attack_chance_curr=gal_attack_chance
end

function draw_title_edge_blocks()
	for i=0,title_edge.count-1 do
		local dist=title_edge.offset+i*title_edge.spacing
		local x,y=edge_rect_pos(dist)
		spr(title_edge.spr,x,y)
	end	
end	

function draw_title_prompt()
	local y=120
	local flash_on=flr(time()*3)%2==0
	
	shprint("FOR iNSTRUCTIONS,",10,y,7,5,false)
	shprint("TO sTART",90,y,7,5,false)
	if flash_on then
		shprint("❎",0,y,7,5,false)
		shprint("🅾️",80,y,7,5,false)
	end	
end	

function draw_title_screen()
	cls()
	map()
	draw_title_edge_blocks()
	local hs_cnt=6
	local hs_scroll_rows=max(hs_cnt-3,0)
	local hs_max_idx=max(10-hs_scroll_rows+1,4)
	shprint("a tRIBUTE TO bIG fIVE sOFTWARE",4,58,7,5,false)
	shprint("bILL hOGUE AND jEFF kONYU",14,64,7,5,false)
	if hiscore_timer>0 then
		hiscore_timer-=1
		if hiscore_timer==0 then
			hiscore_timer=hiscore_delay
			hiscore_idx+=1
			if hiscore_idx>hs_max_idx then hiscore_idx=4 end
		end
	end
	print_hiscores(hiscore_idx,hs_cnt,72)
	draw_title_prompt()
	if block_state!=blst_idle then
		draw_blocks()
	end
end

function draw_instr_prompt()
	local y=120
	local flash_on=flr(time()*3)%2==0

	shprint("pRESS",30,y,7,5,false)
	shprint("TO sTART",62,y,7,5,false)
	if flash_on then
		shprint("🅾️",52,y,7,5,false)
	end
end

function draw_instructions()
	cls()
	map()
	draw_title_edge_blocks()
	shprint("mISSION oBJECTIVE:",28,60,7,5,false)
	shprint("dESTROY aLIENS fOR pOINTS",14,68,7,5,false)
	shprint("40  50  60  70  100  ?",20,84,7,5,false)
	shprint("sCORES dOUBLE wHEN aTTACKING",8,108,7,5,false)
	
	draw_gals()
	draw_instr_prompt()
end

function _draw()

	if block_state==blst_on then
		draw_blocks()
		return
	end
	
	cls()
	
	if game_state==gs_title then
		draw_title_screen()
		return
	end

	if game_state==gs_instructions then
		draw_instructions()
		return
	end

	if game_state==gs_newhs then
		draw_new_hiscore()
		return
	end

	if game_state==gs_over then
		cancel_flagship_attack()
		game_over_delay_cntr-=1
		if game_over_delay_cntr<=0 then
			if new_hiscore() then
				game_state=gs_newhs
				hsname={".",".","."}
				hsentpos=1
			else
				new_game()
				game_state=gs_title
			end
		end
		shprint("gAME oVER",44,60,7,5,true)
	end

	draw_stars()

	if flag_attack then
		if flag_attack_display_counter>0  then
			shprint("FLAGSHIP ATTACK ALERT!",25,60,7,5,false)
		end
		--print(flag_attack_counter,0,120)
	end

	--rect(0,0,127,127,5)
	draw_gals()

	-- draw base (not during game over: spridx overruns expspr, nilヌ●★spr 0 = flagship)
	if game_state!=gs_over then
		if base.state==bst_explod then
			spr(base.expspr[base.spridx],base.x,base.y)
		elseif base.state==bst_intact then
			spr(base.sprites[base.spridx],base.x,base.y)
		end
	end

	-- draw missiles
	for m in all(msl) do
		spr(m.sprite,m.x,m.y)
	end

	-- draw bombs
	for b in all(bombs) do
		spr(b.spr,b.x,b.y)
	end

	draw_score_labels()

	for l=1,lives do
		spr(39,2+(l-1)*4,2)
	end

	draw_flags()
	
	local dscr=tostr(score,0x2)
	while #dscr<6 do
		dscr="0"..dscr
	end
	shprint(dscr,48,0,7,5,false)
	
	if block_state!=blst_idle then
		draw_blocks()
	end
end

function draw_score_labels()
	for sl in all(score_labels) do
		local scorestr=tostr(sl.score)
		local strlen=#scorestr*4
		local slx=sl.x+3-flr(strlen/2)
		print(scorestr,slx,sl.y,10)
	end
end

function draw_flags()
	local tens=wave\10
	local ones=wave%10

	for i=1,ones do
		spr(55,127-(i*3),0)
	end

	for i=1,tens do
		spr(54,127-(ones*3)-(i*4),0)
	end
end

function update_score_labels()
	for sl in all(score_labels) do
		sl.ttl-=1
		sl.risectr+=1
		if sl.risectr>=4 then
			sl.risectr=0
			sl.y-=1
		end
		if sl.ttl<=0 then
			del(score_labels,sl)
		end
	end
end

function update_flag_attack()
	if flag_attack then
		flag_attack_display_counter-=1
		if flag_attack_display_counter<-30 then
			flag_attack_display_counter=60
		end
	end
end

function _update60()
	update_blocks()
	if block_state==blst_on or block_state==blst_hold or block_state==blst_off then
		return
	end

	if (block_state==blst_idle and game_state==gs_title) then
		update_title_edge_blocks()
		if btn(🅾️) then
			new_game()
			game_state=gs_playing
			return
		end
		if btn(❎) then
			base.x=64
			gals={}
			local gal=new_gal(gt_blu,20,92)
			gal.state=gst_instructions
			add(gals, gal) 
			
			gal=new_gal(gt_grn,36,92)
			gal.state=gst_instructions
			add(gals, gal) 

			gal=new_gal(gt_ppl,52,92)
			gal.state=gst_instructions
			add(gals, gal) 

			gal=new_gal(gt_red,68,92)
			gal.state=gst_instructions
			add(gals, gal) 

			gal=new_gal(gt_grd,86,92)
			gal.state=gst_instructions
			add(gals, gal) 

			gal=new_gal(gt_flg,102,92)
			gal.state=gst_instructions
			add(gals, gal) 

			game_state=gs_instructions
		end
		return
	end
	
	if game_state==gs_instructions then
		update_title_edge_blocks()
		update_gals_instructions()
		if btn(🅾️) then
			new_game()
			game_state=gs_playing
		end
		return
	end

	if game_state==gs_newhs then
		update_title_edge_blocks()
		enter_new_hiscore()
		return
	end

	galx+=(galdir*galspd)
	if (galx<=0) galx=1 galdir=1
	if (galx>=30) galx=30 galdir=-1
	update_gals()
	update_score_labels()
	update_flag_attack()

	for m in all(msl) do
		m.y-=2*gtf
		if m.y<0 then
			del(msl,m)
			base.spridx=1
		end

		-- check collision with gals
		for gal in all(gals) do
			if gal.state!=gst_explod then
				local gx,gy=gal_coords(gal)

				glbgal=gal -- for debugging collision function

				local galspr=gal.sprites[gal.spridx]
				if collide_pixel(m.sprite,galspr,gx-m.x,gy-m.y) then
					--log_tbl(m) log_tbl(gal) stop("collide")
					
					--debug: draw collision box
					--rect(gx,gy,gx+7,gy+7,8)
					--stop("collision")

					del(msl,m)
					base.spridx=1
					gal_explode(gal)
				end
			end
		end
	end

	for b in all(bombs) do
		b.y+=bombspd*gtf
		if b.y>127 then
			del(bombs,b)
		end
	end

	update_stars()

	if base.state==bst_explod then
		base.sprdcnt-=1

		if base.sprdcnt<=0 then
			base.sprdcnt=base.sprdly
			base.spridx+=1
			if (#base.expspr<base.spridx) then
				lives-=1
				if lives<=0 then
					cancel_flagship_attack()
					game_state=gs_over
				else
					base.state=bst_spawn
					base.x=60
					base.sprdcnt=180 -- three seconds before respawn
					base.spridx=1
				end
			end
		end

		return -- skip input and collision when exploding
	elseif base.state==bst_spawn then
		base.sprdcnt-=1
		if base.sprdcnt<=0 then
			local attacking=false
			for gal in all(gals) do
				if gal.state==gst_attack then
					attacking=true
					break
				end
			end
			if not attacking then
				base.state=bst_intact
			end
		end

		return -- skip input and collision when spawning
	end

	-- check input
	if (btn(0)) base.x-=(base.x>0) and 1 or 0
	if (btn(1)) base.x+=(base.x<121) and 1 or 0

	if btn(❎) then
		if not btnxdown then
			if (#msl==0) then
	    		btnxdown=true
	    		add(msl,{
	                     x=flr(base.x)+3,
	                     y=base.y,
			             sprite=37
				})
				base.spridx=2
				sfx(sfx_fire)
			end
	 	end
	else
		btnxdown=false
	end

	--[[ debug: slow down time
	if btn(4) then
		if not slow then
			slow=true
			gtf=0.1
		else
			slow=false
			gtf=1
		end
	end
	--]]

	-- check bomb collision with base
	for b in all(bombs) do
		local dx=b.x-base.x
		local dy=b.y-base.y
		if dx>=0 and dx<7 and dy<8 then
			if (dx==0 and dy>=5) or
			   ((dx==1 or dx==6) and dy>=3) or
			   (dx>1 and dx<5 and dy>=1)
			then
				del(bombs,b)
				base_explode()
			end
		end
	end
end

function do_flag_attack(turn_on)
	if turn_on then
		flag_attack=true
		flag_attack_counter = flg_attack_duration
		flag_attack_display_counter = 60
		sfx(sfx_flg_attack_siren)
		sfx(sfx_flg_attack)
	else
		flag_attack=false
		sfx(sfx_flg_attack,-2) -- stop siren
	end
end

function cancel_flagship_attack()
	if flag_attack then
		do_flag_attack(false)
	end

	for gal in all(gals) do
		if gal.gt==gt_flg.gt then
			gal.fire_lasers=false
			gal.lasers_fired=true
			gal.fire_delay=0
			gal.lasers_fired_delay=0
		end
	end
end

function base_explode()
	sfx(sfx_die)

	base.state=bst_explod
	base.spridx=1
	base.sprdcnt=base.sprdly
	
	-- lower attack chance when base is hit
	gal_attack_chance_curr=min(gal_attack_chance_curr+200, gal_attack_chance)

	if flag_attack then
		do_flag_attack(false)
	end
end
-->8
-- galaxians
function init_gals()
	gal_attack_chance=500
	gal_attack_chance_curr=gal_attack_chance -- current attack chance, decreases over time
	gal_attack_chance_incr=-25 -- every 60 frames, increase attack chance by this amount
	gal_attack_chance_min=50 -- minimum attack chance (max attack frequency)
	gal_attack_chance_ctr=60 -- every 60 frames, increase attack chance
	gal_attack_range=15

	gal_bomb_chance=100 -- chance that a gal will drop a bomb when attacking

	gal_jink_chance=100 -- chance that a gal will "jink" (move left or right) when attacking
	gal_endgame_jink_start=50 -- at 8 remaining, jink on average every n checks
	gal_endgame_jink_min=20 -- at 1 remaining, jink on average every n checks
	gal_attack_deflect_pts=30
	gal_attack_deflect_max=20
	gal_attack_deflect_delay=2 -- frames between each deflect point while attacking

	-- gal types
	gt_flg={
		gt=1, -- flagship
		sprites={0,1,2,3,4},
		expspr={48,49,50,51,52},
		flgatckspr={32,33,34,35,36},
		fire_lasers=false,
		lasers_fired=false,
		sprdly=6,
		attackrate=1.25,
		speed=5,
		maxspd=5,
		points=300,
		deflect={}
	}

	gt_grd={
		gt=2, -- guard
		sprites={5},
		expspr={64,65,66,67,68},
		attackrate=0,
		speed=5,
		maxspd=5,
		points=100,
		deflect={}
	}

	gt_red={
		gt=3, -- red
		sprites={16,17},
		expspr={24,25,26,27,28},
		attackrate=1.5,
		speed=6,
		maxspd=9,
		points=70,
		deflect={}
	}

	gt_ppl={
		gt=4, -- purple
		sprites={18,19},
		expspr={40,41,42,43,44},
		attackrate=1.25,
		speed=7,
		maxspd=10,
		points=60,
		deflect={}
	}

	gt_grn={
		gt=5, -- green
		sprites={20,21},
		expspr={56,57,58,59,60},
		attackrate=1,
		speed=5,
		maxspd=7,
		points=50,
		deflect={}
	}

	gt_blu={
		gt=6, -- blue
		sprites={22,23},
		expspr={8,9,10,11,12},
		attackrate=1,
		speed=3,
		maxspd=6,
		points=40,
		deflect={}
	}

	gtyps={gt_flg,gt_grd,gt_red,gt_ppl,gt_grn,gt_blu}

	galx=10 -- global offset
	galspc=10 -- global spacing
	galy=8 -- global offset
	galdir=-1 -- left
	galspd=0.1

	--gal states
	gst_inform=0 -- in formation
	gst_attack=1 -- attacking
	gst_return=2 -- ret to formation
	gst_explod=3 -- exploding
	gst_instructions=4 -- for instruction screen

	gals={}
end

function gal_coords(gal)
	if gal.state==gst_inform then
		return gal.fx+flr(galx), gal.fy+galy
	else
		return gal.x, gal.y
	end
end

function gal_explode(gal)
	if gal.state==gst_explod then
		return
	end

	if gal.gt==gt_flg.gt and flag_attack then
		do_flag_attack(false)
	end

	if gal.state==gst_attack then
		if (gal.gt==gt_flg.gt) then
			sfx(sfx_flg_die)
		else
			sfx(sfx_explode)
		end
		attackers-=1
	else
		sfx(sfx_explode)
	end

	if (gal.gt==gt_grd.gt) and (gal.flgshp!=nil) and (gal.flgshp.state!=gst_explod) then
		gal.flgshp.points+=500 -- guard killed before flagship: increase flagship award
	end

	local award=gal.points
	if gal.gt!=gt_flg.gt then
		award=gal.state==gst_attack and gal.points*2 or gal.points
	end
	addscore(award)
	if gal.gt==gt_flg.gt and gal.state==gst_attack then
		add(score_labels,{
			x=flr(gal.x+0.5),
			y=flr(gal.y+0.5),
			score=award,
			ttl=90,
			risectr=0
		})
	end

	-- handle gal explosion or damage here
	for ogal in all(gals) do
		if ogal.flgshp==gal then
			ogal.flgshp=nil
			ogal.xspd=gal.xspd
			ogal.yspd=gal.yspd
		end
	end

	local gx,gy=gal_coords(gal)

	gal.state=gst_explod
	gal.spridx=1
	gal.sprdly=5
	gal.sprdcnt=gal.sprdly
	gal.fire_lasers=false
	gal.lasers_fired=true
	gal.lasers_fired_delay=0
	gal.fire_delay=0
	gal.xspd=0
	gal.yspd=0
	gal.x=gx
	gal.y=gy
end

function make_attack_deflect(points,max_deflect)
	local deflect={}
	local prev=0
	for i=1,points do
		local curve=max_deflect*sin(i/points*0.5)
		-- pico-8 sin is y-inverted; this sign yields away-first then with-travel at the end
		add(deflect,curve-prev)
		prev=curve
	end
	return deflect
end

function new_gal(pgt,pfx,pfy)
	--log_tbl(pgt)
	--stop("")

	local gal={
		fx=pfx, --formation x
		fy=pfy, --formation y
		x=pfx, --actual x (when attacking)
		y=pfy, --actual y (when attacking)
		state=gst_inform,
		xspd=0,
		yspd=0,
		spridx=1,
		sprdcnt=0,
		sprdly=20,
		attackrate=0,
		deflectctr=0,
		jink_chance=gal_jink_chance
	}

	merge(gal,pgt)
	gal.deflect={}
	gal.basepoints=gal.points
	gal.sprdcnt=gal.sprdly

	return gal
end

function create_gals()
	if wave<3 then
		galpos={
			{0,gt_grd,gt_flg,gt_grd,0,0,gt_grd,gt_flg,gt_grd,0}
		}
	elseif wave<5 then
		galpos={
			{gt_grd,gt_flg,gt_grd,gt_flg,gt_grd,gt_grd,gt_flg,gt_grd,gt_flg,gt_grd}
		}
	elseif wave<7 then
		galpos={
			{gt_grd,gt_flg,gt_flg,gt_flg,gt_grd,gt_grd,gt_flg,gt_flg,gt_flg,gt_grd}
		}
	else
		galpos={
			{gt_flg,gt_flg,gt_flg,gt_flg,gt_flg,gt_flg,gt_flg,gt_flg,gt_flg,gt_flg}
		}
	end

	for i=3,6 do
		local galtyp=gtyps[i]
		galpos[#galpos+1]={galtyp,galtyp,galtyp,galtyp,galtyp,galtyp,galtyp,galtyp,galtyp,galtyp}
	end

	for y=1,#galpos do
		local gtyp=galpos[y]

		for x=1,#gtyp do
			if gtyp[x]!=0 then
				add(gals, new_gal(gtyp[x],(x-1)*galspc,(y-1)*galspc))
			end
		end
	end
end

function draw_laser(gal)
	if gal.lasers_fired_delay>0 then
		gal.lasers_fired_delay-=1
		local x,y=gal_coords(gal) -- ensure gal.x and gal.y are up to date for laser drawing
		line(x+3, y+7, base.x+3, 127, 12)
		sfx(sfx_flg_fire)
	else
		gal.fire_lasers=false
		gal.lasers_fired=true
	end
end

function draw_gals()
	for gal in all(gals) do
		local x,y,lspr
		if gal.state==gst_inform then
			x,y=gal.fx+flr(galx),gal.fy+galy
		else
			x,y=gal.x,gal.y
		end

		if gal.state==gst_explod then
			lspr=gal.expspr
		else
			if (gal.gt==gt_flg.gt) and (flag_attack or gal.fire_lasers) then
				lspr=gal.flgatckspr
			else
				lspr=gal.sprites
			end
		end

		spr(lspr[gal.spridx],x,y)
		if (gal.gt==gt_flg.gt) and (gal.state!=gst_explod) and gal.fire_lasers and gal.fire_delay<=0 and not gal.lasers_fired then
			draw_laser(gal)
			if base.state==bst_intact then
				base_explode()
			end
		end
	end
end

function flagship_fire_lasers()
	local fire_delay=0
	for flg in all(gals) do
		if (flg.gt==gt_flg.gt) and (flg.state!=gst_explod) then
			fire_delay+=flag_fire_lasers_delay
			flg.lasers_fired=false
			flg.lasers_fired_delay=30
			flg.fire_lasers=true
			flg.fire_delay=fire_delay
		end
	end
end

function update_gals_instructions()
	for gal in all(gals) do
		if gal.state==gst_instructions then
			gal.sprdcnt-=1

			if gal.sprdcnt<=0 then
				gal.sprdcnt=gal.sprdly
				gal.spridx+=1
				if (#gal.sprites<gal.spridx) gal.spridx=1
			end
		end
	end
end

function update_gals()
	if #gals==0 then
		next_wave_delay-=1
		if next_wave_delay<=0 then
			next_wave_delay=next_wave_delay_max
			setup_next_wave()
		end
		return
	end
	gal_attack_chance_ctr-=1
	if gal_attack_chance_ctr<=0 then
		gal_attack_chance_ctr=60
		gal_attack_chance_curr+=gal_attack_chance_incr
		if gal_attack_chance_curr<gal_attack_chance_min then
			gal_attack_chance_curr=gal_attack_chance_min
		end
	end
	
	if flag_attack and game_state==gs_playing then
		flag_attack_counter-=1
		if flag_attack_counter<=0 then
			flagship_fire_lasers()
			do_flag_attack(false)
		end
	end 

	for gal in all(gals) do
		if gal.gt==gt_flg.gt and gal.fire_lasers and not gal.lasers_fired and gal.fire_delay>0 then
			gal.fire_delay-=1
		end
		if gal.state==gst_inform then
			gal.sprdcnt-=1

			if gal.sprdcnt<=0 then
				gal.sprdcnt=gal.sprdly
				gal.spridx+=1
				if (#gal.sprites<gal.spridx) gal.spridx=1
			end

			if (base.state==bst_intact) and (gal.attackrate!=0) and (attackers<maxattackers) then
				local attack=rnd(gal_attack_chance_curr*gal.attackrate*#gals)
				if flr(attack)==0 then
					attackers+=1
					gal.state=gst_attack
					gal.yspd=0.5*gtf
					gal.x=gal.fx+flr(galx)
					gal.y=gal.fy+galy
					gal.deflect=make_attack_deflect(gal_attack_deflect_pts,gal_attack_deflect_max)
					gal.deflectctr=0

					if (gal.x>base.x) gal.xspd=-1
					if (gal.x<=base.x) gal.xspd=1

					if abs(gal.x - base.x) > gal_attack_range then
						gal.xspd=gal.maxspd * galspd * gal.xspd * gtf
					else
						gal.xspd=gal.speed * galspd * gal.xspd * gtf
					end

					gal.sprdly=(gal.gt != gt_flg.gt) and gal.sprdly/2 or gal.sprdly -- "flap" when attacking

					if (gal.gt==gt_flg.gt) then -- flagship, call guards
						local guard_count=0
						gal.points=1000
						for other_gal in all(gals) do
							if (other_gal.gt==gt_grd.gt) and (other_gal.state==gst_inform) and
							   ((other_gal.fx==gal.fx-galspc) or (other_gal.fx==gal.fx+galspc)) 
							then
								-- guard next to flagship
								other_gal.state=gst_attack
								attackers+=1
								other_gal.yspd=gal.yspd
								other_gal.xspd=gal.xspd
								other_gal.flgshp=gal -- guarding flagship
								other_gal.x=other_gal.fx+flr(galx)
								other_gal.y=other_gal.fy+galy
								other_gal.deflect=make_attack_deflect(gal_attack_deflect_pts,gal_attack_deflect_max)
								other_gal.deflectctr=0
								guard_count+=1
							end
						end
						gal.points+=guard_count*500
					end
				end
			end

			if game_state==gs_playing and (not flag_attack) and (flg_attack_chance>0) and (gal.gt==gt_flg.gt) then
				local flg_attack=rnd(flg_attack_chance)
				if flr(flg_attack)==0 then
					do_flag_attack(true)
				end
			end
		else
			local process_move=gal.state!=gst_explod
			if process_move and #gal.deflect>0 then
				gal.deflectctr+=1
				if gal.deflectctr<gal_attack_deflect_delay then
					process_move=false
				else
					gal.deflectctr=0
				end
			end

			if process_move then
				if gal.state==gst_return then
					gal.xspd=
						(gal.fx+flr(galx)-gal.x)/
						abs(gal.fy+galy-gal.y)/2 * gtf
				end

				--debug
				if (gal.y==nil) printh("@clip", tbl_to_str(gal)) stop("nil y")
				
				gal.y+=gal.yspd

				if (gal.flgshp!=nil) and ((gal.y>=gal.flgshp.y) and (gal.y<gal.flgshp.y+7)) then
					gal.y += 1 -- if guard is not below flagship, move down another pixel
				end

				if gal.y>127 then
					if (gal.state==gst_attack) and ((#gals>8) or (base.state==bst_spawn)) then
						gal.state=gst_return
						attackers-=1
					end
					gal.y=0
				end

				if gal.state==gst_attack then
					local endgame_jink=#gals<=8
					local jink_chance=gal.jink_chance
					if endgame_jink then
						local t=(8-max(#gals,1))/7 -- 0 at 8 remaining, 1 at 1 remaining
						jink_chance=flr(gal_endgame_jink_start + (gal_endgame_jink_min-gal_endgame_jink_start)*t + 0.5)
					end

					local xdir=(gal.xspd<0) and -1 or 1
					if xdir*(base.x-gal.x)>0 then -- only if moving towards base
						local spd=(abs(gal.x - base.x) > gal_attack_range) and gal.maxspd or gal.speed
						gal.xspd=spd * galspd * ((gal.xspd<0) and -1 or 1) * gtf
					end

					-- last few gals can jink at any attack height; otherwise only when not moving toward base
					local try_jink=endgame_jink or ((xdir*(base.x-gal.x)<=0) and (gal.y<100))
					if try_jink then
						local jink=rnd(jink_chance)
						if flr(jink)==0 then
							gal.xspd=-gal.xspd -- jink (move opposite direction)
						end
					end

					if (base.state==bst_intact) and (gal.y<=107) then
						local bomb=rnd(gal_bomb_chance)
						if flr(bomb)==0 then
							add(bombs,{
								x=gal.x+3,
								y=gal.y+6,
								spr=38
							})
						end
					end

					-- check collision with base
					if (base.state==bst_intact) and 
						collide_pixel(
							gal.sprites[gal.spridx],
							base.sprites[base.spridx],
							base.x-gal.x,
							base.y-gal.y) 
					then
						base_explode()
						gal_explode(gal)
					end
				end

				if #gal.deflect>0 then
					local deflect=gal.deflect[1]
					deli(gal.deflect, 1)
					gal.x+=gal.xspd + deflect * ((gal.xspd<0) and -1 or 1)
				else
					gal.x+=gal.xspd
					if (gal.x<-7) gal.x=127
					if (gal.x>127) gal.x=-7
				end

				if (gal.state==gst_return) then
					if ((gal.xspd<0) and (gal.x<=gal.fx+flr(galx))) or
						 ((gal.xspd>0) and (gal.x>=gal.fx+flr(galx))) then
						gal.xspd=0
					end

					if (gal.y>=gal.fy+galy) and
						 (gal.yspd>0)
					then
						gal.y=gal.fy+galy
						gal.yspd=0
					end

					if (gal.xspd==0) and (gal.yspd==0) then
						gal.state=gst_inform
						gal.flgshp=nil
						gal.points=gal.basepoints
						gal.sprdly=(gal.gt != gt_flg.gt) and gal.sprdly*2 or gal.sprdly -- "flap" when attacking

						for other_gal in all(gals) do
							if (other_gal.gt==gal.gt) and (other_gal.state==gst_inform) and (other_gal != gal) then
								gal.spridx = other_gal.spridx
								gal.sprdcnt = other_gal.sprdcnt
								break
							end
						end
						
						--stop("inform")
					end
				end
			end

			if gal.state==gst_explod then
				gal.sprdcnt-=1

				if gal.sprdcnt<=0 then
					gal.sprdcnt=gal.sprdly
					gal.spridx+=1
					if (#gal.expspr<gal.spridx) then
						del(gals,gal)
						if gal.gt==gt_flg.gt then
							gal_attack_chance_curr=gal_attack_chance -- reset attack chance when flagship dies

							-- check guards are next to a flagship
							for grd in all(gals) do
								if grd.gt==gt_grd.gt then
									if (grd.flgshp==gal) grd.flgshp=nil
									local nextto_flgshp=false
									for flg in all(gals) do
										if (flg.gt==gt_flg.gt) and
										((flg.fx==grd.fx-galspc) or (flg.fx==grd.fx+galspc)) then
											nextto_flgshp=true
											break
										end
									end
									if not nextto_flgshp then
										-- lone guard, can attack
										grd.attackrate=gt_flg.attackrate
									end
								end
							end
						end

					end
				end
			elseif (gal.gt==gt_flg.gt) or (abs(gal.xspd)>gal.speed*galspd) then
				gal.sprdcnt-=1

				if gal.sprdcnt<=0 then
					gal.sprdcnt=gal.sprdly
					gal.spridx+=1
					if (#gal.sprites<gal.spridx) gal.spridx=1
				end
			end
		end
	end
	for grd in all(gals) do
		if grd.flgshp!=nil then
			grd.xspd=grd.flgshp.xspd
			grd.yspd=grd.flgshp.yspd
		end
	end
end
-->8
-- utils --
function merge(t1, t2)
	for k, v in pairs(t2) do
		t1[k] = v
	end
	return t1
end

-- return object with x,y pixel
-- coords on sprite sheet of
-- given sprite number
function shtcoord(sp)
	local sh = {}
	sh.x = (sp%16)*8
	sh.y = flr(sp/16)*8
	return sh
end

-- pixel-perfect collsion:
-- takes two sprite sheet 
-- numbers and a pixel offset
-- in x and y of the second
-- sprite from the first.
-- return true if any pixels in
-- sprites overlap, false
-- otherwise
function collide_pixel(sp1,sp2,xoff,yoff)	
	local sh1 = shtcoord(sp1)
	local sh2 = shtcoord(sp2)
	
	local a = nil
	local b = nil
	
	local xstart = 0
	local xend = 7
	local ystart = 0
	local yend = 7

	local x1off = 0
	local x2off = 0
	local y1off = 0
	local y2off = 0
	
	-- narrow range of collision
	-- test based on offset of
	-- two sprites
	if(xoff > 0) then
		xend = 7-xoff
		x1off = xoff
	elseif(xoff < 0) then
		xend = 7+xoff
		x2off = -xoff
	end
	
	if(yoff > 0) then
		yend = 7-yoff
		y1off = yoff
	elseif(yoff < 0) then
		yend = 7+yoff
		y2off = -yoff
	end

 	-- do the actual test over
 	-- the overlap rectangle
 	for x=xstart,xend do
  		for y=ystart,yend do
   			a = sget(sh1.x+x+x1off,sh1.y+y+y1off)
   			b = sget(sh2.x+x+x2off,sh2.y+y+y2off)
   			if(a!=0 and b!=0) then
   		 		-- pixel overlap means we collided
				return true
  			end
 		end
 	end

	return false
end

function shprint(txt,x,y,c,sc,cl)
	sc=sc or 0
	if cl then
		rectfill(x,y,x+(#txt*4)+1,y+6,0)
	end
	print(txt,x+1,y+1,sc)
	print(txt,x,y,c)
end

function addscore(s)
	score+=0x.0001*s
	free_life_cntdwn-=s
	while free_life_cntdwn<=0 do
		lives+=1
		sfx(sfx_free_life)
		free_life_cntdwn+=free_life_points
	end
end

function tbl_to_str(t)
	local parts={}

	for k, v in pairs(t) do
		local value=tostr(v)
		if type(v)=="table" then
			value=tbl_to_str(v)
		end
		add(parts,tostr(k)..": "..value)
	end

	local out="{"
	for i=1,#parts do
		out..=parts[i]
		if i<#parts then
			out..=", "
		end
	end

	return out.."}"
end

function log_tbl(t)
	local out="--- table contents ---\n"..tbl_to_str(t)
	printh(out)
	printh(out,"@clip")
end

-->8
-- blocks --
function init_blocks()
	blst_idle=0
	blst_on=1
	blst_hold=2
	blst_off=3

	block_tile_w=2
	block_tile_h=3
	block_step=200
	block_on_time=10
	block_on_counter=0
	block_count=0
	block_sfx_delay=2
	block_sfx_counter=0
	block_src_x=(53%16)*8
	block_src_y=(53\16)*8

	blocks={}
	for py=0,127,block_tile_h do
		for px=0,127,block_tile_w do
			add(blocks,{
				x=px,
				y=py,
				w=min(block_tile_w,128-px),
				h=min(block_tile_h,128-py)
			})
		end
	end

	block_on={}
	for i=1,#blocks do
		block_on[i]=false
	end

	block_state=blst_idle
end

function start_block_wipe()
	block_state=blst_on
	block_count=0
	block_on_counter=0
	block_sfx_counter=0
	for i=1,#blocks do
		block_on[i]=false
	end
end

function find_next_block(target_on)
	local start=flr(rnd(#blocks))+1
	for o=0,#blocks-1 do
		local idx=((start+o-1)%#blocks)+1
		if block_on[idx]==target_on then
			return idx
		end
	end
	return nil
end

function update_blocks()
	if block_state==blst_idle then
		return
	end

	if block_sfx_counter>0 then
		block_sfx_counter-=1
	end

	if block_state==blst_on then
		local prev_count=block_count
		local changed=false
		for i=1,block_step do
			local idx=flr(rnd(#blocks))+1
			if not block_on[idx] then
				block_on[idx]=true
				block_count+=1
				changed=true
			end
		end
		if not changed and block_count<#blocks then
			for i=1,20 do
				local idx=find_next_block(false)
				if idx then
					block_on[idx]=true
					block_count+=1
					changed=true
				end
			end
		end
		if block_count>prev_count and block_sfx_counter<=0 then
			sfx(sfx_block)
			block_sfx_counter=block_sfx_delay
		end
		if block_count>=#blocks then
			block_state=blst_hold
			block_on_counter=block_on_time
		end
	elseif block_state==blst_hold then
		block_on_counter-=1
		if block_on_counter<=0 then
			block_on_counter=0
			block_state=blst_off
		end
	elseif block_state==blst_off then
		local prev_count=block_count
		local changed=false
		for i=1,block_step do
			local idx=flr(rnd(#blocks))+1
			if block_on[idx] then
				block_on[idx]=false
				block_count-=1
				changed=true
			end
		end
		if not changed and block_count>0 then
			for i=1,20 do
				local idx=find_next_block(true)
				if idx then
					block_on[idx]=false
					block_count-=1
					changed=true
				end
			end
		end
		if block_count<prev_count and block_sfx_counter<=0 then
			sfx(sfx_block)
			block_sfx_counter=block_sfx_delay
		end
		if block_count<=0 then
			block_state=blst_idle
			if game_state==gs_title and not title_sfx_played then
				sfx(sfx_title,title_sfx_ch)
				title_sfx_played=true
				title_sfx_active=true
			end
		end
	end
end

function stop_title_sfx()
	if title_sfx_active then
		sfx(-1,title_sfx_ch)
		title_sfx_active=false
	end
end

function draw_blocks()
	for i=1,#blocks do
		if block_on[i] then
			local b=blocks[i]
			sspr(block_src_x,block_src_y,b.w,b.h,b.x,b.y,b.w,b.h)
		end
	end
end

-->8
-- stars --

function init_stars()
	star_count=50

	stars={}

 	for i=1,star_count do
  		local layer=flr(rnd(3))+1 -- 1=far,2=middle,3=near
  		add(stars,{
			x=rnd(127), -- random x position
			y=rnd(127), -- random y position
			layer=layer, -- star layer
			col=(layer==1 and 1) or (layer==2 and 5) or 13, -- color based on layer
  		})
	end
end

function update_stars(dx,dy)
	for star in all(stars) do

		local speed=(star.layer==1 and 0) 
			or (star.layer==2 and 0.1)
			or 0.2

		star.y+=speed

		if star.y>127 then
			star.y=0
		end
	end
end

function draw_stars()
	for star in all(stars) do
 	    pset(star.x,star.y,star.col)
	end
end

-->8
-- hi scores --
function init_hiscores()
	hsname={".",".","."}
	hsentpos=1
	hschars=" abcdefghijklmnopqrstuvwxyz!&-+=./"

	hiscores,
	hiscore_delay,
	hiscore_timer,
	hiscore_idx={},150,150,4

	load_hiscores()
end

function reset_hiscores()
	hiscores={}
	for i=1,10 do
		local _score=(11000-(i*1000))*0x.0001
		add(hiscores,{
			score=_score,
			name=chr(96+i,96+i,96+i)
		})
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
			local _name=chr(dget(10+i),dget(20+i),dget(30+i))
			add(hiscores,{score=_score,name=_name})
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
	local n=#hiscores
	for i=1,n-1 do
		for j=1,n-i do
			if hiscores[j].score<hiscores[j+1].score then
				hiscores[j],hiscores[j+1]=hiscores[j+1],hiscores[j]
			end
		end
	end
end

function print_hiscores(idx,cnt,y)
	idx=idx or 4
	cnt=cnt or 6
	y=y or 72

	local x=34
	local step=6
	local title="hIGH sCORES"
	local title_x=64-flr((#title*4)/2)

	shprint(title,title_x,y,10,5,false)

	for i=1,3 do
		local hs=hiscores[i]
		local row_y=y+i*step
		local dscr=tostr(hs.score,0x2)
		while #dscr<6 do
			dscr="0"..dscr
		end
		shprint(i..".",x,row_y,10,0,false)
		shprint(hs.name,x+10,row_y,10,0,false)
		shprint(dscr,x+34,row_y,10,0,false)
	end

	local scroll_rows=max(cnt-3,0)
	local max_idx=max(10-scroll_rows+1,4)
	if idx<4 then idx=4 end
	if idx>max_idx then idx=4 end
	for n=0,scroll_rows-1 do
		local i=idx+n
		local hs=hiscores[i]
		local rank=i
		local row_y=y+(4+n)*step
		local dscr=tostr(hs.score,0x2)
		while #dscr<6 do
			dscr="0"..dscr
		end
		shprint(rank..".",x,row_y,7,5,false)
		shprint(hs.name,x+10,row_y,7,5,false)
		shprint(dscr,x+34,row_y,7,5,false)
	end
end

function new_hiscore()
	return score>hiscores[#hiscores].score
end

function charpos(hschar)
	local result=0
	for i=1,#hschars do
		if hschars[i]==hschar then
			result=i
			break
		end
	end
	return result
end

function enter_new_hiscore()
	local dirv=0
	if (btnp(⬆️)) dirv=1
	if (btnp(⬇️)) dirv=-1

	local hscharidx=charpos(hsname[hsentpos])
	hscharidx=hscharidx+dirv
	if (hscharidx<1) hscharidx=#hschars
	if (hscharidx>#hschars) hscharidx=1
	hsname[hsentpos]=hschars[hscharidx]

	local dirh=0
	if (btnp(⬅️)) dirh=-1
	if (btnp(➡️)) dirh=1
	hsentpos=max((hsentpos+dirh)%4,1)

	if btnp(🅾️) then
		add(hiscores,{score=score,name=hsname[1]..hsname[2]..hsname[3]})
		sort_hiscores()
		del(hiscores,hiscores[11])
		save_hiscores()
		new_game()
		game_state=gs_title
	end
end

function draw_new_hiscore()
	cls()
	map()
	draw_title_edge_blocks()
	shprint("nEW hIGH sCORE!",34,56,10,5,false)
	shprint("eNTER nAME",44,66,7,5,false)

	local bx=46
	local by=82
	if (flr(time()*6)%2)==0 then
		if hsentpos==1 then rect(bx-2,by-2,bx+9,by+8,10) end
		if hsentpos==2 then rect(bx+12,by-2,bx+23,by+8,10) end
		if hsentpos==3 then rect(bx+26,by-2,bx+37,by+8,10) end
	end

	shprint(hsname[1],bx,by,10,0,false)
	shprint(hsname[2],bx+14,by,10,0,false)
	shprint(hsname[3],bx+28,by,10,0,false)

	shprint("⬆️⬇️ cHAR, ⬅️➡️ pOS",27,96,7,5,false)
	shprint("🅾️ tO cONFIRM",36,106,7,5,false)
end

__gfx__
0aaaaa000aaaaa000aaaaa000aaaaa000aaaaa0090888090000a00000000000000ccc00000ccc00c00c9c0000009400000094000bb0000000000000000000000
0aaaaa000aaaaa000aaaaa000aaaaa000aaaaa0090888090000a00000000000000c9c00000c99000009a9000049a940004000000bb0000000000000000000000
a00008a0a80000a0a08000a0a00800a0a00080a0088888000077700000777000099a9c00099a9c0009aaac0009a0a90009000900000000000000000000000000
a00008a0a80000a0a08000a0a00800a0a00080a00888880000777000007770000c9a990009aaa90009a0a9000900094000000040000000000000000000000000
0aaaaa000aaaaa000aaaaa000aaaaa000aaaaa0090888090077777000777770000c9c000099a900009aaaa0049aa0a0049000000000000000000000000000000
0aaaaa000aaaaa000aaaaa000aaaaa000aaaaa0090888090077777000777770000ccc00000c9c9c000ca99c0044a990004000900000000000000000000000000
000000000000000000000000000000000000000000000000777777707777777000000000c0000000009000000094004000940040000000000000000000000000
00000000000000000000000000000000000000000000000077777770777777700000000000000000000000000000000000000000000000000000000000000000
c08880c000888000002220c0c0222000003330000033300030ccc03000ccc0000088800000888008400980004009900000049000000000000000000000000000
c08880c000888000002220c0c0222000003330000033300030ccc03000ccc000008980000009800009a9a9400900094009000940000000000000000000000000
88a8a88088a8a880228882202288822033333330033333000cc8cc000cc8cc00899a9880809a9080000000800000009000000000000000000000000000000000
88a8a88088a8a880228882202288822033333330033333000cc8cc000cc8cc00889a998008aaa88000a00a400000004009000040000000000000000000000000
00888000c08880c0c0222000002220c0c00c00c0c00c00c000ccc00030ccc03000898000009a9000099a9a900990909004909000000000000000000000000000
00888000c08880c0c0222000002220c0c00c00c0c00c00c000ccc00030ccc0300088800000888000004840400049400000404000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000080000080000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0aaaaa000aaaaa000aaaaa000aaaaa000aaaaa00a000000060000000075000000022200000222000400920004009900000049000000000000000000000000000
0aaaaa000aaaaa000aaaaa000aaaaa000aaaaa00a00000006000000077700000002920000009200009a9a9400900094009000940000000000000000000000000
ac4444a0a4c444a0a44c44a0a444c4a0a4444ca0000000000000000007550000299a9220209a9020000000200000009000000000000000000000000000000000
ac4444a0a4c444a0a44c44a0a444c4a0a4444ca0000000000000000007500000229a992002aaa22000a00a400000004009000040000000000000000000000000
0aaaaa000aaaaa000aaaaa000aaaaa000aaaaa0000000000000000000750000000292000009a9000099a9a900990909004909000000000000000000000000000
0aaaaa000aaaaa000aaaaa000aaaaa000aaaaa000000000000000000005000000022200000222000004240400049400000404000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0aaaaa000a9a9a0a0090900000900000009000006600000063300000680000000033300000303000004040000040400000404000000000000000000000000000
0a9a9a0000999a000099a90000000aa0000009006600000063330000688000000039300000999030009a9040009a9040009a9040000000000000000000000000
a9aaa0a0a9a0a0a009a00aa009a000a00a000000660000006330000068000000399a933009aa900009aa90000900900009000090000000000000000000000000
a99a99a009a0a90009a0090900a0000900000000000000006000000060000000339a993030aaa90040a0a9004000090040000004000000000000000000000000
0a99aa00aa9999a0009aa9a0000009a0000009a0000000006000000060000000c00900c0099a990009aa9a0009a09a9000000090000000000000000000000000
0aaaaa0000a99a0000999a90009aaa9000900000000000000000000000000000c00c00c0000c090000040900009409000090a000000000000000000000000000
000000000a00000000000900000009000000090000000000000000000000000000000000c000000cc00000040000000004004000000000000000000000000000
000000000000000a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
90888090908980090099800000940000009400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
908a8090009a900000aaa90004a99400040004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
088aa80009a0aa0009a0aa000900a900000090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08aa880008aaa8000aa0a0009a000000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
90888090009a800009aa090009a00900000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
90888090008990000099900004990000040900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000900000000000040900000409000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000007007000700000000000400000004004000040040000400400000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000004999000049990400499904004909040000090000000000000000000000000000000000000000000000000000000000000000000
0077700000777070009990700999997049a999404990099444000094400000040000000000000000000000000000000000000000000000000000000000000000
0077700009997900099a790009aa9a9009900a400900004009000040000000000000000000000000000000000000000000000000000000000000000000000000
077a770009aaa70079aaa90099a0aa9499900a949900009490000044900000440000000000000000000000000000000000000000000000000000000000000000
077a770007aaa90009aaaa9009aaaa904499a9904990099049000090400000000000000000000000000000000000000000000000000000000000000000000000
7777777009999770099aa79049aaa99049a999404999994044090940400000400000000000000000000000000000000000000000000000000000000000000000
77777770770770707099090700994900004949000449490404494404040940040000000000000000000000000000000000000000000000000000000000000000
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
00000000000000077777700000000770000007700000000000000770000007700000077007700000077000000000000000000000000000000000000000000000
00000000000000077777700000000770000007700000000000000770000007700000077007700000077000000000000000000000000000000000000000000000
00000000000007700000077000077007700007700000000000077007700007700000077007700000077000000000000000000000000000000000000000000000
00000000000007700000077000077007700007700000000000077007700007700000077007700000077000000000000000000000000000000000000000000000
00000000000007700000000007700000077007700000000007700000077007700000077007700000077000000000000000000000000000000000000000000000
00000000000007700000000007700000077007700000000007700000077007700000077007700000077000000000000000000000000000000000000000000000
00000000000007700000000007700000077007700000000007700000077000077007700000077007700000000000000000000000000000000000000000000000
00000000000007700000000007700000077007700000000007700000077000077007700000077007700000000000000000000000000000000000000000000000
00000000000007700777777007777777777007700000000007777777777000000770000000000770000000000000000000000000000000000000000000000000
00000000000007700777777007777777777007700000000007777777777000000770000000000770000000000000000000000000000000000000000000000000
00000000000007700000077007700000077007700000000007700000077000077007700000000770000000000000000000000000000000000000000000000000
00000000000007700000077007700000077007700000000007700000077000077007700000000770000000000000000000000000000000000000000000000000
00000000000007700000077007700000077007700000000007700000077007700000077000000770000000000000000000000000000000000000000000000000
00000000000007700000077007700000077007700000000007700000077007700000077000000770000000000000000000000000000000000000000000000000
00000000000007700000077007700000077007700000000007700000077007700000077000000770000000000000000000000000000000000000000000000000
00000000000007700000077007700000077007700000000007700000077007700000077000000770000000000000000000000000000000000000000000000000
00000000000000077777700007700000077007777777770007700000077007700000077000000770000000000000000000000000000000000000000000000000
00000000000000077777700007700000077007777777770007700000077007700000077000000770000000000000000000000000000000000000000000000000
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
00007777770007700000077007700000077000000770000000077777700007777770000777777000077000000770000000000000000000000000000000000000
00007777770007700000077007700000077000000770000000077777700007777770000777777000077000000770000000000000000000000000000000000000
00000077000007777000077007700000077000077007700007700000077000077000077000000770077770000770000000000000000000000000000000000000
00000077000007777000077007700000077000077007700007700000077000077000077000000770077770000770000000000000000000000000000000000000
00000077000007777000077007700000077007700000077007700000000000077000077000000770077770000770000000000000000000000000000000000000
00000077000007777000077007700000077007700000077007700000000000077000077000000770077770000770000000000000000000000000000000000000
00000077000007700770077007700000077007700000077007700000000000077000077000000770077007700770000000000000000000000000000000000000
00000077000007700770077007700000077007700000077007700000000000077000077000000770077007700770000000000000000000000000000000000000
00000077000007700770077007700000077007777777777000077777700000077000077000000770077007700770000000000000000000000000000000000000
00000077000007700770077007700000077007777777777000077777700000077000077000000770077007700770000000000000000000000000000000000000
00000077000007700007777007700000077007700000077000000000077000077000077000000770077000077770000000000000000000000000000000000000
00000077000007700007777007700000077007700000077000000000077000077000077000000770077000077770000000000000000000000000000000000000
00000077000007700007777007700000077007700000077000000000077000077000077000000770077000077770000000000000000000000000000000000000
00000077000007700007777007700000077007700000077000000000077000077000077000000770077000077770000000000000000000000000000000000000
00000077000007700000077000077007700007700000077007700000077000077000077000000770077000000770000000000000000000000000000000000000
00000077000007700000077000077007700007700000077007700000077000077000077000000770077000000770000000000000000000000000000000000000
00007777770007700000077000000770000007700000077000077777700007777770000777777000077000000770000000000000000000000000000000000000
00007777770007700000077000000770000007700000077000077777700007777770000777777000077000000770000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77000000000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77000000000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
000000000bb000000000bb000000000bb000000000bb000000000bb000000000bb000000000bb000000000bb000000000bb000000000bb000000000bb0000000
000000000bb000000000bb000000000bb000000000bb000000000bb000000000bb000000000bb000000000bb000000000bb000000000bb000000000bb0000000
bb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bb
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bb
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000007777770000000077000000770000000000000077000000770000007700770000007700000000000000000000000000000
00000000000000000000000000000007777770000000077000000770000000000000077000000770000007700770000007700000000000000000000000000000
00000000000000000000000000000770000007700007700770000770000000000007700770000770000007700770000007700000000000000000000000000000
00000000000000000000000000000770000007700007700770000770000000000007700770000770000007700770000007700000000000000000000000000000
00000000000000000000000000000770000000000770000007700770000000000770000007700770000007700770000007700000000000000000000000000000
bb000000000000000000000000000770000000000770000007700770000000000770000007700770000007700770000007700000000000000000000000000000
bb000000000000000000000000000770000000000770000007700770000000000770000007700007700770000007700770000000000000000000000000000000
000000000000000000000000000007700000000007700000077007700000000007700000077000077007700000077007700000000000000000000000000000bb
000000000000000000000000000007700777777007777777777007700000000007777777777000000770000000000770000000000000000000000000000000bb
00000000000000000000000000000770077777700777777777700770000000000777777777700000077000000000077000000000000000000000000000000000
00000000000000000000000000000770000007700770000007700770000000000770000007700007700770000000077000000000000000000000000000000000
00000000000000000000000000000770000007700770000007700770000000000770000007700007700770000000077000000000000000000000000000000000
00000000000000000000000000000770000007700770000007700770000000000770000007700770000007700000077000000000000000000000000000000000
00000000000000000000000000000770000007700770000007700770000000000770000007700770000007700000077000000000000000000000000000000000
00000000000000000000000000000770000007700770000007700770000000000770000007700770000007700000077000000000000000000000000000000000
00000000000000000000000000000770000007700770000007700770000000000770000007700770000007700000077000000000000000000000000000000000
bb000000000000000000000000000007777770000770000007700777777777000770000007700770000007700000077000000000000000000000000000000000
bb000000000000000000000000000007777770000770000007700777777777000770000007700770000007700000077000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bb
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bb
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000777777000770000007700770000007700000077000000007777770000777777000077777700007700000077000000000000000000000
00000000000000000000777777000770000007700770000007700000077000000007777770000777777000077777700007700000077000000000000000000000
00000000000000000000007700000777700007700770000007700007700770000770000007700007700007700000077007777000077000000000000000000000
bb000000000000000000007700000777700007700770000007700007700770000770000007700007700007700000077007777000077000000000000000000000
bb000000000000000000007700000777700007700770000007700770000007700770000000000007700007700000077007777000077000000000000000000000
000000000000000000000077000007777000077007700000077007700000077007700000000000077000077000000770077770000770000000000000000000bb
000000000000000000000077000007700770077007700000077007700000077007700000000000077000077000000770077007700770000000000000000000bb
00000000000000000000007700000770077007700770000007700770000007700770000000000007700007700000077007700770077000000000000000000000
00000000000000000000007700000770077007700770000007700777777777700007777770000007700007700000077007700770077000000000000000000000
00000000000000000000007700000770077007700770000007700777777777700007777770000007700007700000077007700770077000000000000000000000
00000000000000000000007700000770000777700770000007700770000007700000000007700007700007700000077007700007777000000000000000000000
00000000000000000000007700000770000777700770000007700770000007700000000007700007700007700000077007700007777000000000000000000000
00000000000000000000007700000770000777700770000007700770000007700000000007700007700007700000077007700007777000000000000000000000
00000000000000000000007700000770000777700770000007700770000007700000000007700007700007700000077007700007777000000000000000000000
bb000000000000000000007700000770000007700007700770000770000007700770000007700007700007700000077007700000077000000000000000000000
bb000000000000000000007700000770000007700007700770000770000007700770000007700007700007700000077007700000077000000000000000000000
000000000000000000007777770007700000077000000770000007700000077000077777700007777770000777777000077000000770000000000000000000bb
000000000000000000007777770007700000077000000770000007700000077000077777700007777770000777777000077000000770000000000000000000bb
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bb007770000077700000000000000000000000000000000000000000777000000000000077700000000000000000077000000000000000000000000000000000
000075750000075577007770770070707770777000007770077000007575777007700000755577707070777000007055077077707770707007707700777000bb
000077750000075075700755775075750755775500000755707500007705075570550000770007557575775500007770707577550755757570757570775500bb
00007575000007507705075075707575075075500000075075750000757007507570000075500750777575500000057575757550075077757775770575500000
00007575000007507570777077750775075007700000075077050000777577707775000075007770075507700000770577057500075077757575757007700000
00000505000000500505055505550055005000550000005005500000055505550555000005000555005000550000055005500500005005550505050500550000
00000000000000777000000000000000007070000000000000000000000000000000000000777000000000000000007070000000000000000000000000000000
00000000000000757577707000700000007575077007707070777000000770770077000000075577707770777000007575077077007070707000000000000000
00000000000000770507557500750000007775707570557575775500007075757075700000075077557755775500007705707575707775757500000000000000
00000000000000757007507500750000007575757575707575755000007775757575750000075075507550755000007570757575750575757500000000000000
bb000000000000777577700770077000007575770577750775077000007575757577050000775007707500750000007575770575757705077500000000000000
bb000000000000055505550055005500000505055005550055005500000505050505500000055000550500050000000505055005050550005500000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bb
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bb
000000000000000000000000000000000000000000a0a000000000000000000aa000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000a5a5aaa00aa0a0a00000a0550aa00aa0aa00aaa00aa0000000000000000000000000000000000000000000
000000000000000000000000000000000000000000aaa50a55a055a5a50000aaa0a055a0a5a5a0aa55a055000000000000000000000000000000000000000000
000000000000000000000000000000000000000000a5a50a50a5a0aaa5000005a5a500a5a5aa05a55005a0000000000000000000000000000000000000000000
000000000000000000000000000000000000000000a5a5aaa0aaa5a5a50000aa050aa0aa05a5a00aa0aa05000000000000000000000000000000000000000000
00000000000000000000000000000000000000000005050555055505050000055000550550050500550550000000000000000000000000000000000000000000
0000000000000000000000000000000000aa00000000aaa0aaa00a00000000000000aaa0aaa0aa00a000aaa0aaa0000000000000000000000000000000000000
bb000000000000000000000000000000000a000000000a00a0a00a00000000000000a0a000a00a00a000a0a0a0a0000000000000000000000000000000000000
bb000000000000000000000000000000000a000000000a00aa000a00000000000000a0a00aa00a00aaa0a0a0a0a0000000000000000000000000000000000000
00000000000000000000000000000000000a000000000a00a0a00000000000000000a0a000a00a00a0a0a0a0a0a00000000000000000000000000000000000bb
0000000000000000000000000000000000aaa00a0000aa00aaa00a00000000000000aaa0aaa0aaa0aaa0aaa0aaa00000000000000000000000000000000000bb
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000aaa0000000aaa0aaa00a00000000000000aaa0aaa0aaa0aa00aaa0aaa0000000000000000000000000000000000000
000000000000000000000000000000000000a00000000a00a0a00a00000000000000a0a000a000a00a0000a0a0a0000000000000000000000000000000000000
0000000000000000000000000000000000aaa00000000a00aa000a00000000000000a0a0aaa000a00a00aaa0a0a0000000000000000000000000000000000000
0000000000000000000000000000000000a0000000000a00a0a00000000000000000a0a0a00000a00a00a000a0a0000000000000000000000000000000000000
0000000000000000000000000000000000aaa00a0000aa00aaa00a00000000000000aaa0aaa000a0aaa0aaa0aaa0000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bb00000000000000000000000000000000aaa0000000aaa0aaa00000000000000000aaa0aaa0aaa0aaa0aaa0aaa0000000000000000000000000000000000000
bb0000000000000000000000000000000000a00000000a00a0a00000000000000000a0a000a0a000a0a0a0a0a0a0000000000000000000000000000000000000
00000000000000000000000000000000000aa00000000a00aa000000000000000000a0a0aaa0aaa0aaa0a0a0a0a00000000000000000000000000000000000bb
000000000000000000000000000000000000a00000000a00a0a00000000000000000a0a0a00000a000a0a0a0a0a00000000000000000000000000000000000bb
0000000000000000000000000000000000aaa00a0000aa00aaa00000000000000000aaa0aaa0aaa000a0aaa0aaa0000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000007000000000777077707770000000000000777077007770777077707770000000000000000000000000000000000000
00000000000000000000000000000000007500000000757575757575000000000000757507507575757575757575000000000000000000000000000000000000
00000000000000000000000000000000007770000000777577757775000000000000757507507575757575757575000000000000000000000000000000000000
00000000000000000000000000000000007575000000757575757575000000000000757507507575757575757575000000000000000000000000000000000000
00000000000000000000000000000000007775070000757575757575000000000000777577707775777577757775000000000000000000000000000000000000
bb000000000000000000000000000000000555005000050505050505000000000000055505550555055505550555000000000000000000000000000000000000
bb000000000000000000000000000000007770000000777077707770000000000000777077707770777077707770000000000000000000000000000000000000
000000000000000000000000000000000005750000007575757575750000000000007575757575757575757575750000000000000000000000000000000000bb
000000000000000000000000000000000000750000007705770577050000000000007575757577757575757575750000000000000000000000000000000000bb
00000000000000000000000000000000000075000000757075707570000000000000757575750575757575757575000000000000000000000000000000000000
00000000000000000000000000000000000075070000777577757775000000000000777577750075777577757775000000000000000000000000000000000000
00000000000000000000000000000000000005005000055505550555000000000000055505550005055505550555000000000000000000000000000000000000
00000000000000000000000000000000007770000000077007700770000000000000777077707770777077707770000000000000000000000000000000000000
00000000000000000000000000000000007575000000705570557055000000000000757575757575757575757575000000000000000000000000000000000000
00000000000000000000000000000000007775000000750075007500000000000000757575757775757575757575000000000000000000000000000000000000
00000000000000000000000000000000007575000000750075007500000000000000757575757575757575757575000000000000000000000000000000000000
bb000000000000000000000000000000007775070000077007700770000000000000777577757775777577757775000000000000000000000000000000000000
bb000000000000000000000000000000000555005000005500550055000000000000055505550555055505550555000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bb
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bb
0000000bb000000000bb000000000bb000000000bb000000000bb000000000bb000000000bb000000000bb000000000bb000000000bb000000000bb000000000
0000000bb000000000bb000000000bb000000000bb000000000bb000000000bb000000000bb000000000bb000000000bb000000000bb000000000bb000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07777700000000000000000000777000000000000000000000000000000000000000000000000000077777000000000000000007700000000000000000000000
77575770007770077077000000075577000770777077007070077077707770077077000770000000775557700077700770000070557770077077007770000000
77707775007755707575700000075075707055075575707575705507550755707575707055000000775707750007557075000077700755707575700755000000
77570775007550757577050000075075750570075077057575750007500750757575750570070000775057750007507575000005750750777577050750000000
07777755007500770575700000777075757705075075700775077007507770770575757705705000077777550007507705000077050750757575700750000000
00555550000500055005050000055505050550005005050055005500500555055005050550050000005555500000500550000005500050050505050050000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__map__
0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0e0e808182838485868788898a0e0e0e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0e0e909192939495969798999a0e0e0e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0e0ea0a1a2a3a4a5a6a7a8a9000e0e0e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0e0ec0c1c2c3c4c5c6c7c8c9cacb0e0e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0e0ed0d1d2d3d4d5d6d7d8d9dadb0e0e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0e0ee0e1e2e3e4e5e6e7e8e9eaeb0e0e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0e0ef30e0e0e0e0e0e0e0e0e0e0e0e0e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
500000000e1101062015120167301c1301d0301f0301c630131301602012620071100c00008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9001000000000000000a6500c6500665005650106401564003650036500e650026600666016660076600866014660026500963007630066300b64015660066601665006650066300a63009650046500165000000
020600000f6502e6503365037650376503665034650316502f6502d6502a6502765023650226501f6501d6501b6401964018640166401563015630146201362012610106100f6100f6100e6100c6100b6100a610
2d0600001553015530065300653015530155300653006530155501555001000360000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001000000000014301133013430000000d320000001d5200000014330215300000018330000001c33000000000002752000000203300000018530295302a530000001e430295301743000000265200000000000
070800071225611256096560a25602656000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006
000a00000000329333293332933300333003332933329333283330033300333293332933328333003330033300003000030000300003000030000300003000030000300003000030000300003000030000300003
060100003b7473d7473e7473f7473f747007070070700707007070070700707007070070700707007070070700707007070070700707007070070700707007070070700707007070070700707007070070700707
480100003e0123961236002316022f612286220000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
170800002e056224561d056294562e056224562e04622046330062e05622456290561d4562e056224562e046220062e05622456290561d4562e0562245631056250562e45622456290561d4562e056224562e056
01080000204502c050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
