_ENV.locus = function(size)
  size=size or 32
  local cells,ocx,ocy,pool={},{},{},{}

  local function p2c(x,y)
    return (x\size)+1, (y\size)+1
  end

  local function addcell(obj,cx,cy)
    local idx=cx|(cy>>>16)
    local c=cells[idx]
    if not c then
      c=next(pool) or {}
      cells[idx],pool[c]=c,nil
    end
    add(c,obj)
    ocx[obj],ocy[obj]=cx,cy
  end

  local function delcell(obj,cx,cy)
    assert(cx,"unknown object")
    local idx=cx|(cy>>>16)
    local c=cells[idx]
    if c then
      del(c,obj)
      if #c==0 then
        cells[idx],pool[c]=nil,true
      end
    end
    ocx[obj],ocy[obj]=nil,nil
  end

  return {
    _ocx=ocx,_cells=cells,_pool=pool,_size=size,

    add=function(obj,x,y)
      addcell(obj,p2c(x or obj.x,y or obj.y))
      return obj
    end,

    del=function(obj)
      delcell(obj,ocx[obj],ocy[obj])
      return obj
    end,

    update=function(obj,x,y)
      local cx0,cy0=ocx[obj],ocy[obj]
      local cx1,cy1=p2c(x or obj.x,y or obj.y)
      if cx0~=cx1 or cy0~=cy1 then
        delcell(obj,cx0,cy0)
        addcell(obj,cx1,cy1)
      end
      return obj
    end,

    query=function(x,y,w,h)
      local l,t=p2c(x,y)
      local r,b=p2c(x+w,y+h)
      l,t,r,b=l-1,t-1,r+1,b+1
      local cx,cy,i,c=l-1,t,0,nil

      return function()
        while true do
          if i>0 then
            local obj=c[i]
            i-=1
            return obj
          end

          cx+=1
          if cx>r then
            cx,cy=l,cy+1
            if cy>b then return nil end
          end
          c=cells[cx|(cy>>>16)]
          i=c and #c or 0
        end
      end
    end,
  }
end
