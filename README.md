# locus.p8

Locus is a *Two-dimensional*, *unbounded*, *sparse*, *efficient*, *grid* spatial hash for Pico-8.

* Two-Dimensional: The cell grids are squared, and organized in rows and columns.
* Spatial Hash: Locus can be used to *store* objects on it, potentially moving them around, and then *making queries* related with where those objects are.
* Unbounded: A locus grid does not need any initial/final dimensions. It grows or shrinks depending on the objects it contains.
* Sparse: Cells inside the grid are allocated only when they contain an object. Otherwise they are recycled.
* Efficient: Locus tries very hard to limit the number of table allocations and deallocations it does in order to minimize garbage collection

Objects in locus are represented by "axis-aligned bounding boxes", which we will refer to as "boxes". Objects are usually Lua tables representing game objects like enemies, bullets, coins, etc. They can be added, updated, and removed.

The library uses a grid of squared cells and keeps track of which objects "touch" each cell.

This is useful in several scenarios:
* It can tell "Which objects are in a given rectangular section" quite efficiently
* This is useful for collision detection; instead of checking n-to-n interactions, locus can be used to restrict the amount of objects to be checked, sometimes dramatically reducing the number of checks.
* Given that the query area is rectangular, locus can be used to optimize the draw stage, by "only rendering objects that intersect with the screen"


[![locus demo](https://www.lexaloffle.com/bbs/cposts/te/test_locus-1.p8.png)](https://www.lexaloffle.com/bbs/cart_info.php?cid=test_locus-1)


# API

## Creating a locus instance

``` lua
local loc=locus([size])
```
Parameters:
- `size`: An optional parameter that specifies the dimensions (with and height) of the squared cells inside this locus instance. Defaults to `32` when not specified.

Return values:
- `loc`: The newly created locus instance, containing a spatial grid

It is recommended that the grid size is at least as big as one of the "typical" objects in a game, or a multiple of it. For Pico-8 this may be 8,16 or 32.

The ideal situation is that each cell contains 1 (and only 1) game object.

A too small size will make the cells not very efficient, because every object will appear in more than one cell grid.

Making the size too big will have the opposite problem: too many objects on a single grid cell.

You can try experimenting with several sizes in order to arrive to the most optimal one for your game. In general either 16 or 32 should be good defaults.


## Adding an object to an existing grid:

``` lua
local o=loc.add(obj,x,y,w,h)
```
Parameters:
- `obj`: the object to be added (usually, a table representing a game object)
- `x,y`: The `left` and `top` coordinates of the axis-aligned bounding box containing the object
- `w,h`: The `width` and `height` of the axis-aligned bounding box containing the object

Return values:
- `o`: the object being added (same as `obj`)

Note that objects are *not* represented by "2 corners", but instead by a top-left corner plus width and height.

## Removing an object from locus:

``` lua
local o=loc.del(obj)
```
Parameters:
- `obj` the object to be removed from locus

Return values:
- `o`: the object being removed (same as `obj`)

Throws:
- The error `"unknown object"` if `obj` was not previously added to locus

Locus keeps (strong) references to the objects added to it. If you want to remove an object, you *must* call `del`.


## Updating an object inside locus:

``` lua
local o=loc.update(obj,x,y,w,h)
```
Parameters:
- `obj`: the object to be updated (usually, represented by a table)
- `x,y`: The `left` and`top` coordinates of the axis-aligned bounding box containing the object
- `w,h`: The `width` and `height` of the axis-aligned bounding box containing the object

Return values:
- `o`: the object being updated (same as `obj`)

Throws:
- The error `"unknown object"` if `obj` was not previously added to locus

## Querying an area for objects:

``` lua
local res=loc.query(x,y,w,h,[filter])
```
Parameters:
- `x,y`: The `left` and`top` coordinates of the axis-aligned rectangle being queried
- `w,h`: The `width` and `height` of the axis-aligned rectangle being queried
- `filter`: An optional function which can be used to "exclude" or include object from the result. `filter` is a function which takes an object as parameter and returns "truthy" when the object should be included in the result, or "falsy" to not include it. If no filter is specified `locus` will include all objects it encounters on the rectangle

Return values:
- res: A table of the form `{[obj1]=true, [obj2]=true}` containing all the objects whose boxes intersecting with the specified axis-aligned bounding box.

Notes:
- The table returned is *not ordered* in any way. You might need to sort it out in order for it to make sense in your game.
- The objects returned are *the objects contained in cells that touch the specified rectangle*. They are *not guaranteed to actually be intersecting with the given rectangle*. You might need an extra check in order to have this guarantee (see example with `rectintersect` in the FAQ section)


# Usage

Save locus to a single file (locus.lua) and then

```
#include locus.lua
```

# Example

``` lua

-- game objects
local coin={}
local enemy={}
local player={}

-- filter function
function is_enemy(obj)
  return obj==enemy
end

-- create a grid of 16x16 cells
local loc=locus(16)

-- add objects to the grid
loc.add(coin, 0,0,8,8)
loc.add(player, 10,10,8,8)
loc.add(enemy,32,32,8,8)

-- move the player
loc.update(player,20,10,8,8)

-- delete the coin
loc.del(coin)

-- query all the visible objects
local visible=loc.query(0,0,128,128)

--you can then draw the objects by iterating like so:
for obj in pairs(visible) do
  ... call your draw functions like drawplayer(obj)
end


-- query only the visible enemies
local enemies=loc.query(0,0,128,128,is_enemy)

```

See `test_locus.p8` and test_locus.lua for a more complete example about how to use locus. 


# Cost

Locus costs 500 tokens approximately.

The function has several comments which can be stripped in order to save characters if necessary.

Performance-wise, it does several integer divisions and table manipulations per operation. Locus uses an internal table pool to minimize garbage collection.

# Preemptive FAQ

## How does hit work?

Internally, locus has a sparse list of "rows" (representing the `y` axis). Each row can have one or more cells (on the `x` axis).

locus also "remembers" all of the bounding boxes it has seen in a separate table called `boxes`. `boxes` contains one axis-aligned-bounding-box per object added to locus.

Finally, there is also an internal "table pool". When a table is no longer needed(cell depleted of objects, row doesn't have any cells left, box for object which was removed) the tables are added to the pool table instead of being garbage collected. Then the tables can be reused for other purposes, minimizing garbage collection.

While the other methods are "symmetric" with regards to pool usage (`add` takes objects from the pool, `del` adds objects to the pool, `update` adds and removes) the `query` method isn't. It acts as a "pool sink", only taking tables from the pool. This ensures that the pool won't grow too much as long as `query` is used from time to time.

## Why does `query` return a table? Wouldn't it be more efficient to use a callback, or an iterator?

Objects in locus, even small ones, can touch multiple cells as they move. As a result, while querying the cells, we might encounter the same object more than once. The only way to detect this by introducing a `visited` table, which contains the already visited objects. A callback or an iterator would need to be built *on top* of that `visited` table in order to avoid calling the same callback multiple times for the same object. I think this will be undesirable more often than not. So `query` just returns the `visited` table, which is used internally *also* to avoid duplicated objects in the results.

## When should I *not* use locus?

There's several reasons not to use locus:

* Your game world is fixed in size and densely populated. In this case a non-sparse grid will make more sense; the code will be smaller and faster since it doesn't have to deal with sparse data. Since the world is densely populated, you don't have zones without objects, where locus could save up memory.
* Your objects can not be represented properly by axis-aligned bounding boxes. Perhaps you have very long, very thin objects that are often "arranged diagonally". This is the worst case scenario for using locus. You might need a different hash map entirely.
* Your world is already extremely sparse. The main advantage of using locus is that it allows for very fast local queries in an area. If your game has very few interactive objects, it might be simpler to just check all of the objects on every frame. (Take into account that tiles with collision do count as "game objects")

## Can I use locus to accelerate collision detection?

Yes. You can use the `query` object to get a "fast rough list of candidate objects for collision", and then apply a "more expensive collision detection algorithm" (like [hit.p8](https://github.com/kikito/hit.p8/tree/main)) to do use a more costly collision detection algorithm only to the list of candidates.

## Could you show me how to use it in combination with hit.p8?

Here's a partial example:


``` lua
loc = locus()
...

-- filter for only looking at enemies
function is_enemy(obj)
  ...
end


function createbullet(x,y)
  local b={x=x,y=y,w=3,h=3}
  loc.add(b,b.x,b.y,b.w,b.h)
end

function updatebullet(b)
  -- note: bullet will move to nx,ny unless it finds an enemy
  local nx,ny=getnextposition(b)

  -- calculate the query box for the bullet moving towards nx,ny
  local l=b.x+b.vx+min(0,nx)
  local t=b.y+b.vy+min(0,ny)
  local w,h=b.w+abs(nx), b.h+abs(ny)
  -- check the querybox for enemies
  local first_e=nil
  local first_t=32767 --max integer
  for e in pairs(loc.query(l,t,w,h,is_enemy)) do
    local t=hit(b.x,b.y,b.w,b.h,
                e.x,e.y,e.w,e.h,
                b.x+dx,b.y+dy)
    -- we could hit several enemies in transit. We only want the first one (minimum t)
    if t and t<first_t then
      first_t=t
      first_e=e
    end
  end

  if first_e then
    -- collision with an enemy detected
    damageenemy(first_e, 1)
    loc.del(b) -- destroy the bullet. Might need to remove it from other places besides loc
  else
    -- no collision. advance bullet
    b.x,b.y=nx,ny
    loc:update(b,b.x,b.y,b.w,b.h)
  end
end
```

## I don't need continuous collision detection in my game. Can I use locus to accelerate simple (rectangle intersection-based) collision detection?

Yes, `hit` and `locus` can be used separately and they don't need each other to work. Here's an example using collision based on rectangle intersection:

```lua
local loc=locus()
...

function createplayer(x,y)
  local p={x=x,y=y,w=8,h=16}
  loc.add(p,p.x,p.y,p.w,p.h)
end

function rectintersect(x0,y0,w0,h0,x1,y1,w1,h1)
  return x0+w0>=x1 and x1+w1>=x0 and y0+h0>=y1 and y1+h1>=y0
end

function updateplayer(p)
  local nx,ny=getnextposition(p)
  p.x,p.y=nx,ny
  loc.update(p,p.x,p.y,p.w,p.h)

  for c in pairs(loc.query(p.x,p.y,p.w,p.h,is_coin)) do
    if rectintersect(p.x,p.y,p.w,p.h,
                     c.x,c.y,c.w,c.h) then
      score+=1
      loc.del(c) -- delete coin. We might need to remove it from other places too
    end
  end
end
```

In this case, we immediately move the player to a new position and then use query on the new player's coordinates to detect coins that might be touching the player.

Notes:
* With this method, if the player is moving fast enough, they will "tunnel" through coins and other objects. With this method the velocity of the player must be limited, or we must split the movement into smaller step and do a check on every step. The method above (using hit.p8) does not have this problem
* Notice that eventhough we gave the player's bounding rectangle to `query`, we still need to call `rectintersect` to properly detect that a coin is actually intersecting with the player. This is because `query` will return the *objects that are on the cells that intersect with the given rectangle, but will not guarantee that the objects intersect the rectangle*. For example, on a grid of 32 pixels, the player might be touching 1 grid cell by only 1 pixel on the left, and a coin might be starting on pixel 22 from the left. That coin will still be returned by `query`, eventhough it is not touched by the player.
* `query` will return the objects in random order. There's no way to detect which coins get "touched" first. It is not important on this example, but it might be important in more complex games (e.g. if there's an enemy before the coins, then the player might get hurt and not pick up the coins). With hit.p8 you can know which objects go first (smaller `t`).

## Can I use locus in picotron?

Locus should be compatible with picotron, but some sacrifices needed to be made in order to preserve the token count contained for pico-8. In particular, the `each` internal function sacrifices (a small amount of) speed in order to reduce token usage. In an unconstrained environment like picotron, it might make more sense to expand `each` into 4 functions, costing more tokens but also being slightly faster.

## Can locus have rectangular (non-squared) grid cells?

No, only squared grid cells are supported. It would be very easy to add support for rectangular cells, but it would cost some tokens that I didn't want to spend. Feel free to fork and add support for that if you need to.

## Why not use the colon syntax? (`loc:add` instead of `loc.add`)

It's a token-saving decision. Coding in a "self-less" way where the instance variables are inside a function closure instead of in a table that gets passed everywhere saves some tokens.
 
## I am having trouble with locus, it does not seem to work. How can I debug it?

You could try drawing it on the screen, on top or below your game objects. The included test_locus file has an example function (`draw_locus`) which does just this. You may need to tweak it to suit your needs.

## Where have you done this kind of thing before?

I am the original author of the [bump.lua](https://github.com/kikito/bump.lua) library, used for collision detection in Lua/LÖVE , which is quite famous. There's some things I learned while writing that library, that I have tried to avoid/simplify while doing this Pico8 version.

## Have you used this on an actual videogame?

I am building one, this is but one of the pieces. 

