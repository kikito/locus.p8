local loc
local vp
local objs

function rand(low,hi)
  return flr(low+rnd(hi-low))
end

function _init()
  -- viewport. It's a rectangle that moves around, printing the objects it "sees" in color
  vp={x=40,y=40,w=80,h=64,dx=2,dy=1}

  -- locus instance
  loc=locus()

  -- add 10 objects to locus
  objs={}
  for i=1,10 do
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
    objs[i]=obj
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

  -- count objects in locus
  local objcount=0
  for _ in pairs(loc._ocx) do
    objcount+=1
  end
  -- print how many objects are in locus
  circ(7,120,5)
  print(objcount,5,118)
end

function _draw()
  cls()

  color(13)
  -- draw locus in magenta
  draw_locus(loc)

  -- draw all objects as outlines
  color(6)
  for obj in all(objs) do
    rrect(obj.x,obj.y,obj.w,obj.h)
  end

  -- draw the viewport
  color(10)
  rrect(vp.x,vp.y,vp.w,vp.h)

  -- draw the objects that are visible through the viewport with rectfill+color
  clip(vp.x,vp.y,vp.w,vp.h)
  for obj in loc.query(vp.x,vp.y,vp.w,vp.h) do
   rrectfill(obj.x,obj.y,obj.w,obj.h,0,obj.col)
  end
  clip()
end
