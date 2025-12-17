local loc
local vp

function rand(low,hi)
  return flr(low+rnd(hi-low))
end

function _init()
  -- viewport. It's a rectangle that moves around, printing the objects it "sees" in color
  vp={x=40,y=40,w=80,h=64,dx=2,dy=1}

  -- locus instance
  loc=locus()

  -- add 10 objects to locus
  for _=1,10 do
    local w=rand(5,15)
    local obj={
      x=rand(30,110),
      y=rand(30,110),
      w=w,
      h=w,
      av=rnd(),
      r=rnd(),
      col=rand(6,15)
    }
    loc.add(obj,obj.x,obj.y)
   end
end

function _update()
 
  t=time()

  -- move all the objects in locus
  -- we use a bigger box than just the screen so that we also update the objects that
  -- are outside of the visible screen
  for obj in loc.query(-128,-128,256,256) do
    obj.x+= sin(obj.av*t)*obj.r
    obj.y+= cos(obj.av*t)*obj.r
    loc.update(obj,obj.x,obj.y)
  end

  -- update the viewport
  vp.x+=vp.dx
  vp.y+=vp.dy
  -- make the viewport bounce when it touches the screen borders
  if vp.x < 0 or vp.x+vp.w > 128 then
    vp.dx*=-1
  end
  if vp.y < 0 or vp.y+vp.h > 128 then
    vp.dy*=-1
  end
end


function draw_locus(loc)
  local size=loc._size
  -- calculate grid bounds manually
  local cl,ct=1,1
  local cr,cb=(128\size)+1,(128\size)+1
  local cell
  -- draw the cells
  for cy=ct,cb do
    for cx=cl,cr do
      cell=loc._cells[cx|(cy>>>16)]
      if cell then
        local x,y=(cx-1)*size,(cy-1)*size
        rrect(x,y,size,size)
        local count=0
        for _ in pairs(cell) do count+=1 end
        print(count,x+2,y+2)
      end
    end
  end

  -- draw the positions of each object
  local objcount=0
  for obj in pairs(loc._px) do
    circfill(loc._px[obj],loc._py[obj],1)
    objcount+=1
  end
  -- print how many objects are in locus
  circ(7,120,5)
  print(objcount, 5,118)

  -- print the pool size
  local poolsize=0
  for _ in pairs(loc._pool) do poolsize+=1 end
  circ(120,120,5)
  print(poolsize, 118,118)
end

function _draw()
  cls()
  
  color(13)
  -- draw locus in magenta
  draw_locus(loc)

  -- draw the viewport
  color(10)
  rrect(vp.x,vp.y,vp.w,vp.h)

  -- draw he objects that are visible through the viewport with rectfill+color
  clip(vp.x,vp.y,vp.w,vp.h)
  for obj in loc.query(vp.x,vp.y,vp.w,vp.h) do
   rrectfill(obj.x,obj.y,obj.w,obj.h,0,obj.col)
  end
  clip()
end
