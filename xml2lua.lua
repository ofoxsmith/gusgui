---@diagnostic disable
-- This is a version of https://github.com/manoelcampos/xml2lua combined into one file with unused components removed
-- The MIT License (MIT)

-- Copyright (c) 2016 Manoel Campos da Silva Filho

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--@author Paul Chakravarti (paulc@passtheaardvark.com)
--@author Manoel Campos da Silva Filho
local xml2lua = { _VERSION = "1.6-1" }
local function GetParser()
  local function decimalToHtmlChar(code)
      local num = tonumber(code)
      if num >= 0 and num < 256 then
        return string.char(num)
      end

      return "&#" .. code .. ";"
  end

  local function hexadecimalToHtmlChar(code)
      local num = tonumber(code, 16)
      if num >= 0 and num < 256 then
          return string.char(num)
      end

      return "&#x" .. code .. ";"
  end

  local XmlParser = {
      _XML        = '^([^<]*)<(%/?)([^>]-)(%/?)>',
      _ATTR1      = '([%w-:_]+)%s*=%s*"(.-)"',
      _ATTR2      = '([%w-:_]+)%s*=%s*\'(.-)\'',
      _CDATA      = '<%!%[CDATA%[(.-)%]%]>',
      _PI         = '<%?(.-)%?>',
      _COMMENT    = '<!%-%-(.-)%-%->',
      _TAG        = '^(.-)%s.*',
      _LEADINGWS  = '^%s+',
      _TRAILINGWS = '%s+$',
      _WS         = '^%s*$',
      _DTD1       = '<!DOCTYPE%s+(.-)%s+(SYSTEM)%s+["\'](.-)["\']%s*(%b[])%s*>',
      _DTD2       = '<!DOCTYPE%s+(.-)%s+(PUBLIC)%s+["\'](.-)["\']%s+["\'](.-)["\']%s*(%b[])%s*>',
      _DTD3       = '<!DOCTYPE%s+(.-)%s+%[%s+.-%]>',
      _DTD4       = '<!DOCTYPE%s+(.-)%s+(SYSTEM)%s+["\'](.-)["\']%s*>',
      _DTD5       = '<!DOCTYPE%s+(.-)%s+(PUBLIC)%s+["\'](.-)["\']%s+["\'](.-)["\']%s*>',
      _DTD6       = '<!DOCTYPE%s+(.-)%s+(PUBLIC)%s+["\'](.-)["\']%s*>',

      _ATTRERR1   = '=+?%s*"[^"]*$',
      _ATTRERR2   = '=+?%s*\'[^\']*$',
      _TAGEXT     = '(%/?)>',

      _errstr     = {
          xmlErr = "Error Parsing XML",
          declErr = "Error Parsing XMLDecl",
          declStartErr = "XMLDecl not at start of document",
          declAttrErr = "Invalid XMLDecl attributes",
          piErr = "Error Parsing Processing Instruction",
          commentErr = "Error Parsing Comment",
          cdataErr = "Error Parsing CDATA",
          dtdErr = "Error Parsing DTD",
          endTagErr = "End Tag Attributes Invalid",
          unmatchedTagErr = "Unbalanced Tag",
          incompleteXmlErr = "Incomplete XML Document",
      },

      _ENTITIES   = {
          ["&lt;"] = "<",
          ["&gt;"] = ">",
          ["&amp;"] = "&",
          ["&quot;"] = '"',
          ["&apos;"] = "'",
          ["&#(%d+);"] = decimalToHtmlChar,
          ["&#x(%x+);"] = hexadecimalToHtmlChar,
      },
  }

  function XmlParser.new(_handler, _options)
      local obj = {
          handler = _handler,
          options = _options,
          _stack  = {}
      }

      setmetatable(obj, XmlParser)
      obj.__index = XmlParser
      return obj;
  end

  local function fexists(table, elementName)
      if table == nil then
          return false
      end

      if table[elementName] == nil then
          return fexists(getmetatable(table), elementName)
      else
          return true
      end
  end

  local function err(self, errMsg, pos)
      if self.options.errorHandler then
          self.options.errorHandler(errMsg, pos)
      end
  end

  local function stripWS(self, s)
      if self.options.stripWS then
          s = string.gsub(s, '^%s+', '')
          s = string.gsub(s, '%s+$', '')
      end
      return s
  end

  local function parseEntities(self, s)
      if self.options.expandEntities then
          for k, v in pairs(self._ENTITIES) do
              s = string.gsub(s, k, v)
          end
      end

      return s
  end

  local function parseTag(self, s)
      local tag = {
          name = string.gsub(s, self._TAG, '%1'),
          attrs = {}
      }

      local parseFunction = function(k, v)
          tag.attrs[k] = parseEntities(self, v)
          tag.attrs._ = 1
      end

      string.gsub(s, self._ATTR1, parseFunction)
      string.gsub(s, self._ATTR2, parseFunction)

      if tag.attrs._ then
          tag.attrs._ = nil
      else
          tag.attrs = nil
      end

      return tag
  end

  local function parseXmlDeclaration(self, xml, f)
      f.match, f.endMatch, f.text = string.find(xml, self._PI, f.pos)
      if not f.match then
          err(self, self._errstr.declErr, f.pos)
      end
      if f.match ~= 1 then
          err(self, self._errstr.declStartErr, f.pos)
      end
      local tag = parseTag(self, f.text)
      if tag.attrs and tag.attrs.version == nil then
          err(self, self._errstr.declAttrErr, f.pos)
      end
      if fexists(self.handler, 'decl') then
          self.handler:decl(tag, f.match, f.endMatch)
      end
      return tag
  end

  local function parseXmlProcessingInstruction(self, xml, f)
      local tag = {}
      f.match, f.endMatch, f.text = string.find(xml, self._PI, f.pos)
      if not f.match then
          err(self, self._errstr.piErr, f.pos)
      end
      if fexists(self.handler, 'pi') then
          tag = parseTag(self, f.text)
          local pi = string.sub(f.text, string.len(tag.name) + 1)
          if pi ~= "" then
              if tag.attrs then
                  tag.attrs._text = pi
              else
                  tag.attrs = { _text = pi }
              end
          end
          self.handler:pi(tag, f.match, f.endMatch)
      end
      return tag
  end

  local function parseComment(self, xml, f)
      f.match, f.endMatch, f.text = string.find(xml, self._COMMENT, f.pos)
      if not f.match then
          err(self, self._errstr.commentErr, f.pos)
      end
      if fexists(self.handler, 'comment') then
          f.text = parseEntities(self, stripWS(self, f.text))
          self.handler:comment(f.text, next, f.match, f.endMatch)
      end
  end

  local function _parseDtd(self, xml, pos)
      local dtdPatterns = { self._DTD1, self._DTD2, self._DTD3, self._DTD4, self._DTD5, self._DTD6 }
      for _, dtd in pairs(dtdPatterns) do
          local m, e, r, t, n, u, i = string.find(xml, dtd, pos)
          if m then
              return m, e, { _root = r, _type = t, _name = n, _uri = u, _internal = i }
          end
      end
      return nil
  end

  local function parseDtd(self, xml, f)
      f.match, f.endMatch, _ = _parseDtd(self, xml, f.pos)
      if not f.match then
          err(self, self._errstr.dtdErr, f.pos)
      end
      if fexists(self.handler, 'dtd') then
          local tag = { name = "DOCTYPE", value = string.sub(xml, f.match + 10, f.endMatch - 1) }
          self.handler:dtd(tag, f.match, f.endMatch)
      end
  end

  local function parseCdata(self, xml, f)
      f.match, f.endMatch, f.text = string.find(xml, self._CDATA, f.pos)
      if not f.match then
          err(self, self._errstr.cdataErr, f.pos)
      end

      if fexists(self.handler, 'cdata') then
          self.handler:cdata(f.text, nil, f.match, f.endMatch)
      end
  end

  local function parseNormalTag(self, xml, f)
      while 1 do
          f.errStart, f.errEnd = string.find(f.tagstr, self._ATTRERR1)

          if f.errEnd == nil then
              f.errStart, f.errEnd = string.find(f.tagstr, self._ATTRERR2)
              if f.errEnd == nil then
                  break
              end
          end

          f.extStart, f.extEnd, f.endt2 = string.find(xml, self._TAGEXT, f.endMatch + 1)
          f.tagstr = f.tagstr .. string.sub(xml, f.endMatch, f.extEnd - 1)
          if not f.match then
              err(self, self._errstr.xmlErr, f.pos)
          end
          f.endMatch = f.extEnd
      end

      local tag = parseTag(self, f.tagstr)

      if (f.endt1 == "/") then
          if fexists(self.handler, 'endtag') then
              if tag.attrs then
                  err(self, string.format("%s (/%s)", self._errstr.endTagErr, tag.name), f.pos)
              end
              if table.remove(self._stack) ~= tag.name then
                  err(self, string.format("%s (/%s)", self._errstr.unmatchedTagErr, tag.name), f.pos)
              end
              self.handler:endtag(tag, f.match, f.endMatch)
          end
      else
          table.insert(self._stack, tag.name)

          if fexists(self.handler, 'starttag') then
              self.handler:starttag(tag, f.match, f.endMatch)
          end

          if (f.endt2 == "/") then
              table.remove(self._stack)
              if fexists(self.handler, 'endtag') then
                  self.handler:endtag(tag, f.match, f.endMatch)
              end
          end
      end

      return tag
  end

  local function parseTagType(self, xml, f)
      if string.find(string.sub(f.tagstr, 1, 5), "?xml%s") then
          parseXmlDeclaration(self, xml, f)
      elseif string.sub(f.tagstr, 1, 1) == "?" then
          parseXmlProcessingInstruction(self, xml, f)
      elseif string.sub(f.tagstr, 1, 3) == "!--" then
          parseComment(self, xml, f)
      elseif string.sub(f.tagstr, 1, 8) == "!DOCTYPE" then
          parseDtd(self, xml, f)
      elseif string.sub(f.tagstr, 1, 8) == "![CDATA[" then
          parseCdata(self, xml, f)
      else
          parseNormalTag(self, xml, f)
      end
  end

  local function getNextTag(self, xml, f)
      f.match, f.endMatch, f.text, f.endt1, f.tagstr, f.endt2 = string.find(xml, self._XML, f.pos)
      if not f.match then
          if string.find(xml, self._WS, f.pos) then
              if #self._stack ~= 0 then
                  err(self, self._errstr.incompleteXmlErr, f.pos)
              else
                  return false
              end
          else
              err(self, self._errstr.xmlErr, f.pos)
          end
      end

      f.text = f.text or ''
      f.tagstr = f.tagstr or ''
      f.match = f.match or 0

      return f.endMatch ~= nil
  end

  function XmlParser:parse(xml, parseAttributes)
      if type(self) ~= "table" or getmetatable(self) ~= XmlParser then
          error("You must call xmlparser:parse(parameters) instead of xmlparser.parse(parameters)")
      end

      if parseAttributes == nil then
          parseAttributes = true
      end

      self.handler.parseAttributes = parseAttributes
      local f = {
          match = 0,
          endMatch = 0,
          pos = 1,
      }

      while f.match do
          if not getNextTag(self, xml, f) then
              break
          end

          f.startText = f.match
          f.endText = f.match + string.len(f.text) - 1
          f.match = f.match + string.len(f.text)
          f.text = parseEntities(self, stripWS(self, f.text))
          if f.text ~= "" and fexists(self.handler, 'text') then
              self.handler:text(f.text, nil, f.match, f.endText)
          end

          parseTagType(self, xml, f)
          f.pos = f.endMatch + 1
      end
  end

  XmlParser.__index = XmlParser
  return XmlParser
end

local XmlParser = GetParser()
local function printableInternal(tb, level)
  if tb == nil then
     return
  end

  level = level or 1
  local spaces = string.rep(' ', level*2)
  for k,v in pairs(tb) do
      if type(v) == "table" then
         print(spaces .. k)
         printableInternal(v, level+1)
      else
         print(spaces .. k..'='..v)
      end
  end
end

function xml2lua.parser(handler)
    if handler == xml2lua then
        error("You must call xml2lua.parse(handler) instead of xml2lua:parse(handler)")
    end

    local options = {
            --Indicates if whitespaces should be striped or not
            stripWS = 1,
            expandEntities = 1,
            errorHandler = function(errMsg, pos)
                error(string.format("%s [char=%d]\n", errMsg or "Parse Error", pos))
            end
          }

    return XmlParser.new(handler, options)
end

function xml2lua.printable(tb)
    printableInternal(tb)
end

function xml2lua.toString(t)
    local sep = ''
    local res = ''
    if type(t) ~= 'table' then
        return t
    end

    for k,v in pairs(t) do
        if type(v) == 'table' then
            v = xml2lua.toString(v)
        end
        res = res .. sep .. string.format("%s=%s", k, v)
        sep = ','
    end
    res = '{'..res..'}'

    return res
end

function xml2lua.loadFile(xmlFilePath)
    local f, e = io.open(xmlFilePath, "r")
    if f then
        local content = f:read("*a")
        f:close()
        return content
    end

    error(e)
end

local function attrToXml(attrTable)
  local s = ""
  attrTable = attrTable or {}

  for k, v in pairs(attrTable) do
      s = s .. " " .. k .. "=" .. '"' .. v .. '"'
  end
  return s
end

local function getSingleChild(tb)
  local count = 0
  for _ in pairs(tb) do
    count = count + 1
  end
  if (count == 1) then
      for k, _ in pairs(tb) do
          return k
      end
  end
  return nil
end

local function getFirstValue(tb)
  if type(tb) == "table" then
    for _, v in pairs(tb) do
      return v
    end
      return nil
   end

   return tb
end

xml2lua.pretty = true

function xml2lua.getSpaces(level)
  local spaces = ''
  if (xml2lua.pretty) then
    spaces = string.rep(' ', level * 2)
  end
  return spaces
end

function xml2lua.addTagValueAttr(tagName, tagValue, attrTable, level)
  local attrStr = attrToXml(attrTable)
  local spaces = xml2lua.getSpaces(level)
  if (tagValue == '') then
    table.insert(xml2lua.xmltb, spaces .. '<' .. tagName .. attrStr .. '/>')
  else
    table.insert(xml2lua.xmltb, spaces .. '<' .. tagName .. attrStr .. '>' .. tostring(tagValue) .. '</' .. tagName .. '>')
  end
end

function xml2lua.startTag(tagName, attrTable, level)
  local attrStr = attrToXml(attrTable)
  local spaces = xml2lua.getSpaces(level)
  if (tagName ~= nil) then
    table.insert(xml2lua.xmltb, spaces .. '<' .. tagName .. attrStr .. '>')
  end
end

function xml2lua.endTag(tagName, level)
  local spaces = xml2lua.getSpaces(level)
  if (tagName ~= nil) then
    table.insert(xml2lua.xmltb, spaces .. '</' .. tagName .. '>')
  end
end

function xml2lua.isChildArray(obj)
  for tag, _ in pairs(obj) do
    if (type(tag) == 'number') then
      return true
    end
  end
  return false
end

function xml2lua.isTableEmpty(obj)
  for k, _ in pairs(obj) do
    if (k ~= '_attr') then
      return false
    end
  end
  return true
end

function xml2lua.parseTableToXml(obj, tagName, level)
  if (tagName ~= '_attr') then
    if (type(obj) == 'table') then
      if (xml2lua.isChildArray(obj)) then
        for _, value in pairs(obj) do
          xml2lua.parseTableToXml(value, tagName, level)
        end
      elseif xml2lua.isTableEmpty(obj) then
        xml2lua.addTagValueAttr(tagName, "", obj._attr, level)
      else
        xml2lua.startTag(tagName, obj._attr, level)
        for tag, value in pairs(obj) do
          xml2lua.parseTableToXml(value, tag, level + 1)
        end
        xml2lua.endTag(tagName, level)
      end
    else
      xml2lua.addTagValueAttr(tagName, obj, nil, level)
    end
  end
    end

---Converts a Lua table to a XML String representation.
--@param tb Table to be converted to XML
--@param tableName Name of the table variable given to this function,
--                 to be used as the root tag. If a value is not provided
--                 no root tag will be created.
--@param level Only used internally, when the function is called recursively to print indentation
--
--@return a String representing the table content in XML
function xml2lua.toXml(tb, tableName, level)
  xml2lua.xmltb = {}
  level = level or 0
  local singleChild = getSingleChild(tb)
  tableName = tableName or singleChild

  if (singleChild) then
    xml2lua.parseTableToXml(getFirstValue(tb), tableName, level)
            else
    xml2lua.parseTableToXml(tb, tableName, level)
  end

  if (xml2lua.pretty) then
    return table.concat(xml2lua.xmltb, '\n')
  end
  return table.concat(xml2lua.xmltb)
end

local function getTree()
    local function init()
        local obj = {
            root = {},
            options = { noreduce = {} }
        }

        obj._stack = { obj.root }
        return obj
    end

    local tree = init()
    function tree:new()
        local obj = init()

        obj.__index = self
        setmetatable(obj, self)

        return obj
    end

    function tree:reduce(node, key, parent)
        for k, v in pairs(node) do
            if type(v) == 'table' then
                self:reduce(v, k, node)
            end
        end
        if #node == 1 and not self.options.noreduce[key] and
            node._attr == nil then
            parent[key] = node[1]
        end
    end

    local function convertObjectToArray(obj)
        if #obj == 0 then
            local array = {}
            table.insert(array, obj)
            return array
        end

        return obj
    end

    function tree:starttag(tag)
        local node = {}
        if self.parseAttributes == true then
            node._attr = tag.attrs
        end

        local current = self._stack[#self._stack]

        if current[tag.name] then
            local array = convertObjectToArray(current[tag.name])
            table.insert(array, node)
            current[tag.name] = array
        else
            current[tag.name] = { node }
        end

        table.insert(self._stack, node)
    end

    function tree:endtag(tag, s)
        local prev = self._stack[#self._stack - 1]
        if not prev[tag.name] then
            error("XML Error - Unmatched Tag [" .. s .. ":" .. tag.name .. "]\n")
        end
        if prev == self.root then
            self:reduce(prev, nil, nil)
        end

        table.remove(self._stack)
    end

    function tree:text(text)
        local current = self._stack[#self._stack]
        table.insert(current, text)
    end

    tree.cdata = tree.text
    tree.__index = tree
    return tree
end

xml2lua.getTree = getTree
return xml2lua
