# locus.p8

Locus is a *Two-dimensional*, *unbounded*, *sparse*, *efficient*, *grid* spatial hash for Pico-8.

* Two-Dimensional: The cell grids are squared, and organized in rows and columns.
* Spatial Hash: Locus can be used to *store* objects on it, potentially moving them around, and then *making queries* related with where those objects are.
* Unbounded: A locus grid does not need any initial/final dimensions. It grows or shrinks depending on the objects it contains.
* Sparse: Cells inside the grid are allocated only when they contain an object.
* Efficient: Locus minimizes table allocations and uses efficient bit-shifting operations.

Objects in locus are stored by their position. Objects are usually Lua tables representing game objects like enemies, bullets, coins, etc. They can be added, updated, and removed.

The library uses a grid of squared cells and keeps track of which objects are in each cell.

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
- `size`: An optional parameter that specifies the maximum width or height of the largest object that will be stored in the grid. Defaults to `32` when not specified. Internally, this also determines the cell size.

Return values:
- `loc`: The newly created locus instance, containing a spatial grid

Each object occupies exactly one cell based on its position. The `size` parameter should be set to accommodate your largest object. Query operations automatically search neighboring cells (with a 1-cell border) to detect potential interactions.

You can try experimenting with several sizes in order to arrive to the most optimal one for your game. In general either 16 or 32 should be good defaults.

**Coordinate Limits:** Due to the bit-shifting cell indexing implementation, cell coordinates are limited to PICO-8's 16-bit integer range. This means world coordinates can range from approximately -32768 to 32767 in each dimension (multiplied by your cell size). For typical PICO-8 games this is more than sufficient.


## Adding an object to an existing grid:

``` lua
local o=loc.add(obj[,x,y])
```
Parameters:
- `obj`: the object to be added (usually, a table representing a game object)
- `x,y`: The position coordinates of the object (optional if `obj.x` and `obj.y` exist)

Return values:
- `o`: the object being added (same as `obj`)

Note: If `x` and `y` are not provided, the function will use `obj.x` and `obj.y` instead.

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
local o=loc.update(obj[,x,y])
```
Parameters:
- `obj`: the object to be updated (usually, represented by a table)
- `x,y`: The new position coordinates of the object (optional if `obj.x` and `obj.y` exist)

Return values:
- `o`: the object being updated (same as `obj`)

Throws:
- The error `"unknown object"` if `obj` was not previously added to locus

Note: If `x` and `y` are not provided, the function will use `obj.x` and `obj.y` instead.

## Querying an area for objects:

``` lua
for obj in loc.query(x,y,w,h) do
  -- use obj
end
```
Parameters:
- `x,y`: The `left` and `top` coordinates of the axis-aligned rectangle being queried
- `w,h`: The `width` and `height` of the axis-aligned rectangle being queried

Return values:
- An iterator that yields objects in the queried area

Notes:
- The iterator returns objects in no particular order.
- The query automatically includes a 1-cell border in all directions to account for objects in neighboring cells.
- The objects returned are *the objects contained in cells that touch the specified rectangle* (plus border). They are *not guaranteed to actually be intersecting with the given rectangle*. You might need an extra check in order to have this guarantee (see example with `rectintersect` in the FAQ section).
- If you need to filter objects, use an `if` statement inside the loop.


# Usage

Save locus to a single file (locus.lua) and then

```
#include locus.lua
```

# Example

``` lua

-- game objects
local coin={x=0,y=0}
local enemy={x=32,y=32}
local player={x=10,y=10}

-- create a grid with max object size of 16
local loc=locus(16)

-- add objects to the grid (coordinates can be omitted if obj has x,y properties)
loc.add(coin)
loc.add(player)
loc.add(enemy)

-- move the player
player.x=20
loc.update(player)

-- delete the coin
loc.del(coin)

-- query and draw all the visible objects
for obj in loc.query(0,0,128,128) do
  -- call your draw functions like drawplayer(obj)
end

-- query only the visible enemies with filtering
for obj in loc.query(0,0,128,128) do
  if obj==enemy then
    -- handle enemy
  end
end

```

See `test_locus.p8` and test_locus.lua for a more complete example about how to use locus. 


# Cost

Locus costs approximately 320 tokens.

Performance-wise, it uses integer divisions and bit-shifting operations. Query operations use coroutines to provide an iterator interface with minimal memory allocation.

# Preemptive FAQ

## How does it work?

Internally, locus uses a sparse table of cells indexed using bit-shifting operations. Each cell coordinate `(cx, cy)` is encoded as a single number using `cx|(cy>>>16)`, where cx is in the integer part and cy is in the fractional part of PICO-8's 16.16 fixed-point numbers.

Locus stores the cell coordinates for each object (not world coordinates), which eliminates redundant conversions during updates and deletions.

Query operations use coroutines to provide an iterator interface with minimal memory allocation.

## When should I *not* use locus?

There's several reasons not to use locus:

* Your game world is fixed in size and densely populated. In this case a non-sparse grid will make more sense; the code will be smaller and faster since it doesn't have to deal with sparse data.
* Your objects are larger than the cell size. Since each object occupies exactly one cell, objects larger than the cell size won't be tracked properly. Set the `size` parameter to accommodate your largest object.
* Your world is already extremely sparse. The main advantage of using locus is that it allows for very fast local queries in an area. If your game has very few interactive objects, it might be simpler to just check all of the objects on every frame.

## Can I use locus to accelerate collision detection?

Yes. You can use the `query` iterator to get a "fast rough list of candidate objects for collision", and then apply a "more expensive collision detection algorithm" (like [hit.p8](https://github.com/kikito/hit.p8/tree/main)) to use a more costly collision detection algorithm only to the list of candidates.

## Could you show me how to use it in combination with hit.p8?

Here's a partial example:


``` lua
loc = locus()
...

function createbullet(x,y)
  local b={x=x,y=y,w=3,h=3}
  loc.add(b,b.x,b.y)
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
  for e in loc.query(l,t,w,h) do
    if is_enemy(e) then
      local t=hit(b.x,b.y,b.w,b.h,
                  e.x,e.y,e.w,e.h,
                  b.x+dx,b.y+dy)
      -- we could hit several enemies in transit. We only want the first one (minimum t)
      if t and t<first_t then
        first_t=t
        first_e=e
      end
    end
  end

  if first_e then
    -- collision with an enemy detected
    damageenemy(first_e, 1)
    loc.del(b) -- destroy the bullet. Might need to remove it from other places besides loc
  else
    -- no collision. advance bullet
    b.x,b.y=nx,ny
    loc.update(b,b.x,b.y)
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
  loc.add(p,p.x,p.y)
end

function rectintersect(x0,y0,w0,h0,x1,y1,w1,h1)
  return x0+w0>=x1 and x1+w1>=x0 and y0+h0>=y1 and y1+h1>=y0
end

function updateplayer(p)
  local nx,ny=getnextposition(p)
  p.x,p.y=nx,ny
  loc.update(p,p.x,p.y)

  for c in loc.query(p.x,p.y,p.w,p.h) do
    if is_coin(c) and rectintersect(p.x,p.y,p.w,p.h,
                                     c.x,c.y,c.w,c.h) then
      score+=1
      loc.del(c) -- delete coin. We might need to remove it from other places too
    end
  end
end
```

In this case, we immediately move the player to a new position and then use query on the new player's coordinates to detect coins that might be touching the player.

Notes:
* With this method, if the player is moving fast enough, they will "tunnel" through coins and other objects. With this method the velocity of the player must be limited, or we must split the movement into smaller steps and do a check on every step. The method above (using hit.p8) does not have this problem
* Notice that eventhough we gave the player's bounding rectangle to `query`, we still need to call `rectintersect` to properly detect that a coin is actually intersecting with the player. This is because `query` will return the *objects that are on the cells that intersect with the given rectangle* (plus a 1-cell border), *but will not guarantee that the objects intersect the rectangle*.
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

# Changelog

## Version 1.0

Major rewrite with breaking API changes:

**Breaking Changes:**
- `add(obj,x,y,w,h)` → `add(obj,x,y)` - no longer stores object dimensions
- `update(obj,x,y,w,h)` → `update(obj,x,y)` - no longer stores object dimensions
- `query(x,y,w,h,filter)` → `query(x,y,w,h)` returns iterator instead of table, removed filter parameter
- `size` parameter now represents maximum object size instead of just cell size
- Query automatically includes 1-cell border in all directions

**Improvements:**
- Reduced token count from ~500 to ~320
- Eliminated table pool system (simpler code)
- Uses bit-shifting for efficient cell indexing
- Iterator-based queries with coroutines (zero table allocations)
- Stores cell coordinates directly (fewer conversions)
- Each object occupies exactly one cell
- Cells use arrays instead of hash tables, allowing safe deletion during query iteration
- `add()` and `update()` now accept optional coordinates, defaulting to `obj.x` and `obj.y`

**Migration Guide:**
- Remove `w,h` parameters from `add()` and `update()` calls
- Change `for obj in pairs(loc.query(...))` to `for obj in loc.query(...)`
- Move filter logic from query parameter into loop body: `if condition then ... end`
- Ensure your `size` parameter accommodates your largest object

## Version 0.1

Initial release

