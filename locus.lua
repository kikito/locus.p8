_ENV.locus = function(size)
  size=size or 32
  local cells,px,py,pool={},{},{},{}

  local function frompool()
    local tbl=next(pool)
    if tbl then
      pool[tbl]=nil
      return tbl
    end
    return {}
  end

  local function p2c(x,y)
    return (x\size)+1, (y\size)+1
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

  local function each(op,p1,l,t,r,b)
    local cell,idx
    for cy=t,b do
      for cx=l,r do
        idx=cx|(cy>>>16)
        if op=="add" and not cells[idx] then
          cells[idx]=frompool()
        end
        cell=cells[idx]
        if cell then
          if op=="add" then
            cell[p1]=true
          elseif op=="del" then
            cell[p1]=nil
          elseif op=="free" and not next(cell) then
            cells[idx],pool[cell]=nil,true
          end
        end
      end
    end
  end

  return {
    _px=px,_py=py,_p2c=p2c,_pool=pool,_cells=cells,_size=size,

    add=function(obj,x,y)
      px[obj],py[obj]=x,y
      local cx,cy=p2c(x,y)
      each("add",obj,cx,cy,cx,cy)
      return obj
    end,

    del=function(obj)
      local x,y=assert(px[obj],"unknown object"),py[obj]
      local cx,cy=p2c(x,y)
      each("del",obj,cx,cy,cx,cy)
      each("free",obj,cx,cy,cx,cy)
      px[obj],py[obj]=nil,nil
      return obj
    end,

    update=function(obj,x,y)
      local x0,y0=assert(px[obj],"unknown object"),py[obj]
      local cx0,cy0=p2c(x0,y0)
      local cx1,cy1=p2c(x,y)
      if cx0~=cx1 or cy0~=cy1 then
        each("del",obj,cx0,cy0,cx0,cy0)
        each("add",obj,cx1,cy1,cx1,cy1)
        each("free",obj,cx0,cy0,cx0,cy0)
      end
      px[obj],py[obj]=x,y
    end,

    query=function(x,y,w,h)
      local l,t=p2c(x,y)
      local r,b=p2c(x+w,y+h)
      local co=cocreate(function() query_iter(l-1,t-1,r+1,b+1) end)
      return query_next,co
    end,
  }
end
