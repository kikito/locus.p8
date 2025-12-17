_ENV.locus = function(size)
  size=size or 32
  local cells,cx,cy={},{},{}

  local function p2c(x,y)
    return (x\size)+1, (y\size)+1
  end

  local function addcell(cx,cy,obj)
    local idx=cx|(cy>>>16)
    if not cells[idx] then
      cells[idx]={}
    end
    cells[idx][obj]=true
  end

  local function delcell(cx,cy,obj)
    local idx=cx|(cy>>>16)
    local cell=cells[idx]
    if cell then
      cell[obj]=nil
      if not next(cell) then
        cells[idx]=nil
      end
    end
  end

  local function query_iter(l,t,r,b)
    for cy=t,b do
      for cx=l,r do
        local cell=cells[cx|(cy>>>16)]
        if cell then
          for obj in pairs(cell) do
            yield(obj)
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
    _cx=cx,_cy=cy,_p2c=p2c,_cells=cells,_size=size,

    add=function(obj,x,y)
      local cellx,celly=p2c(x,y)
      cx[obj],cy[obj]=cellx,celly
      addcell(cellx,celly,obj)
      return obj
    end,

    del=function(obj)
      local cellx,celly=assert(cx[obj],"unknown object"),cy[obj]
      delcell(cellx,celly,obj)
      cx[obj],cy[obj]=nil,nil
      return obj
    end,

    update=function(obj,x,y)
      local cx0,cy0=assert(cx[obj],"unknown object"),cy[obj]
      local cx1,cy1=p2c(x,y)
      if cx0~=cx1 or cy0~=cy1 then
        delcell(cx0,cy0,obj)
        addcell(cx1,cy1,obj)
        cx[obj],cy[obj]=cx1,cy1
      end
    end,

    query=function(x,y,w,h)
      local l,t=p2c(x,y)
      local r,b=p2c(x+w,y+h)
      local co=cocreate(function() query_iter(l-1,t-1,r+1,b+1) end)
      return query_next,co
    end,
  }
end
