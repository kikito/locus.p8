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
    loc.add(obj,obj.x,obj.y,obj.w,obj.h)
   end
end

function _update()
 
  t=time()

  -- move all the objects in locus
  -- we use a bigger box than just the screen so that we also update the objects that
  -- are outside of the visible screen
  for obj in pairs(loc.query(-128,-128,256,256)) do
    obj.x+= sin(obj.av*t)*obj.r
    obj.y+= cos(obj.av*t)*obj.r
    loc.update(obj,obj.x,obj.y,obj.w,obj.h)
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
  local cl,ct,cr,cb=loc._box2grid(0,0,128,128)
  local size=loc._size
  local row,cell
  -- draw the cells
  for cy=ct,cb do
    row=loc._rows[cy]
    if row then
      for cx=cl,cr do
        cell=row[cx]
        if cell then
          local x,y=(cx-1)*size,(cy-1)*size
          rect(x,y,x+size,y+size)
          local count=0
          for _ in pairs(cell) do count+=1 end
          print(count,x+2,y+2)
        end
      end
    end
  end

  -- draw the boxes containing each object
  local objcount=0
  for _,box in pairs(loc._boxes) do
    rect(box[1],box[2],box[1]+box[3],box[2]+box[4])
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
  rect(vp.x,vp.y,vp.x+vp.w,vp.y+vp.h)

  -- draw he objects that are visible through the viewport with rectfill+color
  clip(vp.x,vp.y,vp.w,vp.h)
  for obj in pairs(loc.query(vp.x,vp.y,vp.w,vp.h)) do
   rectfill(obj.x,obj.y,obj.x+obj.w,obj.y+obj.h,obj.col)
  end
  clip()
end
