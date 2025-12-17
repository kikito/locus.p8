_ENV.locus = function(size)
  size=size or 32
  local cells,ocx,ocy={},{},{}

  local function p2c(x,y)
    return (x\size)+1, (y\size)+1
  end

  local function addcell(obj,cx,cy)
    local idx=cx|(cy>>>16)
    if not cells[idx] then
      cells[idx]={}
    end
    add(cells[idx],obj)
    ocx[obj],ocy[obj]=cx,cy
  end

  local function delcell(obj,cx,cy)
    assert(cx,"unknown object")
    local idx=cx|(cy>>>16)
    local cell=cells[idx]
    if cell then
      del(cell,obj)
      if #cell==0 then
        cells[idx]=nil
      end
    end
    ocx[obj],ocy[obj]=nil,nil
  end

  local function query_iter(l,t,r,b)
    for cy=t,b do
      for cx=l,r do
        local cell=cells[cx|(cy>>>16)]
        if cell then
          for i=#cell,1,-1 do
            yield(cell[i])
          end
        end
      end
    end
  end

  local function query_next(co)
    local _,obj=coresume(co)
    return obj
  end

  return {
    _ocx=ocx,_cells=cells,_size=size,

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
      local co=cocreate(function() query_iter(l-1,t-1,r+1,b+1) end)
      return query_next,co
    end,
  }
end
