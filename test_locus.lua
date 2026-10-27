local loc
local vp

function rand(low,hi)
  return flr(low+rnd(hi-low))
end

function _init()
  vp={x=40,y=40,w=80,h=64,dx=2,dy=1}

  -- locus instance
  loc=locus()

  for _=1,10 do
    loc.add({
      x=rand(30,110),
      y=rand(30,110),
      av=rnd(),
      r=rnd(),
      col=rand(6,15)
    })
  end
end

function _update()
 
  t=time()

  -- move all the objects in locus
  -- we use a bigger box than just the screen so that we also update the objects that
  -- are outside of the visible screen
  loc.each(-128,-128,256,256,function(obj)
    obj.x+= sin(obj.av*t)*obj.r
    obj.y+= cos(obj.av*t)*obj.r
    loc.update(obj,obj.x,obj.y)
  end)

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


function draw_locus(loc,size)
  size=size or 32 -- matches locus() default
  local cells={}
  local objcount=0
  -- visit every object: gray it out and count it per cell
  loc.each(-128,-128,256,256,function(obj)
    objcount+=1
    circfill(obj.x,obj.y,1,6)
    local cx,cy=(obj.x\size)+1,(obj.y\size)+1
    local col=cells[cx]
    if not col then col={} cells[cx]=col end
    col[cy]=(col[cy] or 0)+1
  end)
  -- draw each non-empty cell + its count
  for cx,col in pairs(cells) do
    for cy,n in pairs(col) do
      local x,y=(cx-1)*size,(cy-1)*size
      rrect(x,y,size,size)
      print(n,x+2,y+2)
    end
  end
  -- print how many objects are in locus
  circ(7,120,5)
  print(objcount,5,118)
end

function _draw()
  cls()

  color(13)
  -- draw the locus grid and its objects grayed out
  draw_locus(loc)

  color(10)
  rrect(vp.x,vp.y,vp.w,vp.h)

  clip(vp.x,vp.y,vp.w,vp.h)
  loc.each(vp.x,vp.y,vp.w,vp.h,function(obj)
   circfill(obj.x,obj.y,1,obj.col)
  end)
  clip()
end
