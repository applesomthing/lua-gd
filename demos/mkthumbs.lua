#!/usr/bin/env lua

-- Thumbnail generator, powered by lua and lua-gd
-- (c) 2004 Alexandre Erwin Ittner <aittner AT netuno DOT com DOT br>

-- Distributed under the terms of GNU GPL, version 2 or (at your option)
-- any later version. THERE IS NO WARRANTY OF ANY KIND!! 

-- This program runs under Unix only and requires the Luiz Henrique de
-- Figueiredo's POSIX extension for Lua, which can be donwloaded from
-- http://www.tecgraf.puc-rio.br/~lhf/ftp/lua/

-- $Id$


thumbsize = 120         -- thumbnail size
tablecols = 5           -- columns on table

header = [[
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
 <head>
  <title>Thumbnails for {DIRNAME}</title>
  <meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1">
  <style type="text/css">
<!--
H1 {
    font-family: Verdana, Arial, helvetica, sans-serif;
    font-size: 18px;
    color: black;
    background-color: white;
    text-align: center;
}    

BODY  {
    font-family: Verdana, Arial, helvetica, sans-serif;
    font-size: 11px;
    color: black;
    background : white;
}

TABLE {
    border: 0px;
}

TR, TD {
    font-family: Verdana, Arial, helvetica, sans-serif;
    font-size: 11px;
    border: 0px;
    background-color: white;
    padding: 0px;
    cell-spacing: 1px;
}

.small {
    font-size: 9px;
}

-->
  </style>
 </head>

 <body>
  <h1>Thumbnails for {DIRNAME}</h1>
  <center>
   <table>
]]

footer = [[
   </table>
  </center>
  <hr>
  <div class="small">Generated by mkthumbs.lua powered by
    <a href="http://lua-gd.luaforge.net/projects/">Lua-GD</a>.</div>
 </body>
</html>
]]



if arg[1] == nil then
  print("usage:  mkthumbs.lua <directory>")
  os.exit(1)
end

load_posix = loadlib("lposix.so", "luaopen_posix")
if load_posix == nil then
  print("Error:  Can't find the POSIX library. Do you have it, you don't?")
  os.exit(1)
end
load_posix()

load_gd = assert(loadlib("libluagd.so", "luaopen_gd"))
load_gd()



function makeThumb(dirname, fname)
  local im
  local tmpname = string.lower(fname)
  local s, e, name, tname
  local thumbname, fulltname
  local format
  local fullname = dirname .. "/" .. fname

  s, e, name = string.find(tmpname, "thumb_(.+)%.png")
  if name then 
    return nil
  end

  s, e, name = string.find(tmpname, "(.+)%.png")
  if name then
    im = gd.createFromPng(fullname)
    format = "PNG"
    tname = name
  end
  s, e, name = string.find(tmpname, "(.+)%.jpe?g")
  if name then
    im = gd.createFromJpeg(fullname)
    format = "JPEG"
    tname = name
  end
  s, e, name = string.find(tmpname, "(.+)%.gif")
  if name then
    im = gd.createFromGif(fullname)
    format = "GIF"
    tname = name
  end

  if im == nil then
    return nil
  end

  thumbname = "thumb_" .. tname .. ".png"
  fulltname = dirname .. "/" .. thumbname

  local sx, sy = im:sizeXY()
  local tsy, tsy, rtsy
  if sx <= thumbsize and sy <= thumbsize then
    tsx, tsy = sx, sy
  else
    local factor
    factor = math.max(1, sx/thumbsize, sy/thumbsize)
    tsx, tsy = math.floor(sx/factor), math.floor(sy/factor)
  end

  rtsy = tsy + 15
  tim = gd.createTrueColor(tsx, rtsy)
  tim:copyResampled(im, 0, 0, 0, 0, tsx, tsy, sx, sy)

  local black = tim:colorExact(0, 0, 0)
  local white = tim:colorExact(255, 255, 255)
  local info = format .. ", " .. sx .. "x" .. sy .. "px"
  tim:filledRectangle(0, tsy, tsx, rtsy, black)
  tim:string(gd.FONT_SMALL, 2, tsy+1, info, white)

  if tim:png(fulltname) then
    return thumbname, tsx, rtsy, fname
  end

  return nil
end



dirname = arg[1]
indexname = dirname .. "/index.html"

filelist = posix.dir(dirname)
if filelist == nil then
  print("Error: Can't access directory '" .. dirname .. "'")
  os.exit(1)
end

fp = io.open(indexname, "w")
if fp == nil then
  print("Error: Can't open '" .. indexname .. "' for writting.")
  os.exit(1)
end

nheader = string.gsub(header, "{DIRNAME}", dirname)
fp:write(nheader)
fp:write("    <tr>\n")

cols = 0
numtbs = 0
for i, name in ipairs(filelist) do
  tname, sx, sy, fname = makeThumb(dirname, name)
  if tname then
    print("Processing " .. fname .. " ...")
    fp:write("     <td> <a href=\"" .. fname .. "\"> <img src=\""
        .. tname .."\" width=\"" .. sx .. "\" height=\"" .. sy
        .."\" border=\"no\"> </a> </td>\n")
    cols = cols + 1
    if cols > tablecols then
      fp:write("    </tr>\n    <tr>\n")
      cols = 0
    end
    numtbs = numtbs + 1
  end
end

fp:write("    </tr>\n")
fp:write(footer)
fp:close()

print("DONE: " .. indexname .. " generated with " .. numtbs .. " thumbnails")

