-- vendored locus spatial hash. plain-array cells via builtin add/del/all
-- (del(t,value) is iteration-safe on pico-8, so no deferred-kill needed).
_ENV.locus = function(size)
 size=size or 32
 local bkts,index={},{}

 local function p2c(x,y)
  return x\size+1, y\size+1
 end

 local function getk(obj,x,y)
  local cx,cy=p2c(x or obj.x,y or obj.y)
  return cx|(cy>>>16)
 end

 local function add2bkt(obj,k)
  bkts[k]=bkts[k] or {}
  add(bkts[k],obj)
  index[obj]=k
 end

 local function delfrombkt(obj,k)
  assert(k,"unknown object")
  del(bkts[k],obj)
  index[obj]=nil
 end

 return {
  has=function(obj) return index[obj]~=nil end,

  add=function(obj,x,y)
   add2bkt(obj,getk(obj,x,y))
   return obj
  end,

  del=function(obj)
   delfrombkt(obj,index[obj])
   return obj
  end,

  update=function(obj,x,y)
   local k,nk=index[obj],getk(obj,x,y)
   if k~=nk then
    delfrombkt(obj,k)
    add2bkt(obj,nk)
   end
   return obj
  end,

  each=function(x,y,w,h,fn,...)
   local l,t=p2c(x,y)
   local r,b=p2c(x+w,y+h)
   for cy=t-1,b+1 do
    for cx=l-1,r+1 do
     for obj in all(bkts[cx|(cy>>>16)]) do fn(obj,...) end
    end
   end
  end
 }
end
