_ENV.locus = function(size)
  size=size or 32
  local rows,boxes,pool={},{},{}

  local function frompool()
    local tbl=next(pool)
    if tbl then
      pool[tbl]=nil
      return tbl
    end
    return {}
  end

  local function box2grid(x,y,w,h)
    return (x\size)+1, --l
      (y\size)+1,      --t
      ((x+w)\size)+1,  --r
      ((y+h)\size)+1   --b
  end

  local function each(op,p1,l,t,r,b,filter)
    local row,cell
    for cy=t,b do
      if op=="add" and not rows[cy] then
        rows[cy]=frompool()
      end
      row=rows[cy]
      if row then
        for cx=l,r do
          if op=="add" and not row[cx] then
            row[cx]=frompool()
          end
          cell=row[cx]
          if cell then
            if op=="add" then
              cell[p1]=true
            elseif op=="del" then
              cell[p1]=nil
            elseif op=="free" and not next(cell) then
              row[cx],pool[cell]=nil,true
            elseif op=="query" then
              for obj in pairs(cell) do
                if not p1[obj] and (not filter or filter(obj)) then
                  p1[obj]=true
                end
              end
            end
          end
        end
        if op=="free" and not next(row) then
          rows[cy],pool[row]=nil,true
        end
      end
    end
  end

  return {
    _boxes=boxes,_box2grid=box2grid,_pool=pool,_rows=rows,_size=size,

    add=function(obj,x,y,w,h)
      local box=frompool()
      box[1],box[2],box[3],box[4]=x,y,w,h
      boxes[obj]=box
      each("add",obj,box2grid(x,y,w,h))
      return obj
    end,

    del=function(obj)
      local box=assert(boxes[obj],"unknown object")
      local l,t,r,b=box2grid(unpack(box))
      each("del",obj,l,t,r,b)
      each("free",obj,l,t,r,b)
      box[1],box[2],box[3],box[4]=nil,nil,nil,nil
      boxes[obj],pool[box]=nil,true
      return obj
    end,

    update=function(obj,x,y,w,h)
      local box=assert(boxes[obj],"unknown object")
      local l0,t0,r0,b0=box2grid(unpack(box))
      local l1,t1,r1,b1=box2grid(x,y,w,h)
      if l0~=l1 or t0~=t1 or r0~=r1 or b0~=b1 then
        each("del",obj,l0,t0,r0,b0)
        each("add",obj,l1,t1,r1,b1)
        each("free",obj,l0,t0,r0,b0)
      end
      box[1],box[2],box[3],box[4]=x,y,w,h
    end,

    query=function(x,y,w,h,filter)
      local res=frompool()
      local l,t,r,b=box2grid(x,y,w,h)
      each("query",res,l,t,r,b,filter)
      return res
    end,
  }
end
