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
        return {
            options = {commentNode=1, piNode=1, dtdNode=1, declNode=1},
            current = { _children = {}, _type = "ROOT" },
            _stack = {}
        }
    end
    
    --@author Paul Chakravarti (paulc@passtheaardvark.com)
    --@author Manoel Campos da Silva Filho
    local dom = init()
    
    ---Instantiates a new handler object.
    --Each instance can handle a single XML.
    --By using such a constructor, you can parse
    --multiple XML files in the same application.
    --@return the handler instance
    function dom:new()
        local obj = init()
    
        obj.__index = self
        setmetatable(obj, self)
    
        return obj
    end
    
    ---Parses a start tag.
    -- @param tag a {name, attrs} table
    -- where name is the name of the tag and attrs
    -- is a table containing the attributes of the tag
    function dom:starttag(tag)
        local node = { _type = 'ELEMENT',
                       _name = tag.name,
                       _attr = tag.attrs,
                       _children = {}
                     }
    
        if not self.root then
            self.root = node
        end
    
        table.insert(self._stack, node)
    
        table.insert(self.current._children, node)
        self.current = node
    end
    
    ---Parses an end tag.
    -- @param tag a {name, attrs} table
    -- where name is the name of the tag and attrs
    -- is a table containing the attributes of the tag
    function dom:endtag(tag)
        --Table representing the containing tag of the current tag
        local prev = self._stack[#self._stack]
    
        if tag.name ~= prev._name then
            error("XML Error - Unmatched Tag ["..s..":"..tag.name.."]\n")
        end
    
        table.remove(self._stack)
        self.current = self._stack[#self._stack]
        if not self.current then
           local node = { _children = {}, _type = "ROOT" }
           if self.decl then
          table.insert(node._children, self.decl)
          self.decl = nil
           end
           if self.dtd then
          table.insert(node._children, self.dtd)
          self.dtd = nil
           end
           if self.root then
          table.insert(node._children, self.root)
          self.root = node
           end
           self.current = node
        end
    end
    
    ---Parses a tag content.
    -- @param text text to process
    function dom:text(text)
        local node = { _type = "TEXT",
                       _text = text
                     }
        table.insert(self.current._children, node)
    end
    
    ---Parses a comment tag.
    -- @param text comment text
    function dom:comment(text)
        if self.options.commentNode then
            local node = { _type = "COMMENT",
                           _text = text
                         }
            table.insert(self.current._children, node)
        end
    end
    
    --- Parses a XML processing instruction (PI) tag
    -- @param tag a {name, attrs} table
    -- where name is the name of the tag and attrs
    -- is a table containing the attributes of the tag
    function dom:pi(tag)
        if self.options.piNode then
            local node = { _type = "PI",
                           _name = tag.name,
                           _attr = tag.attrs,
                         }
            table.insert(self.current._children, node)
        end
    end
    
    ---Parse the XML declaration line (the line that indicates the XML version).
    -- @param tag a {name, attrs} table
    -- where name is the name of the tag and attrs
    -- is a table containing the attributes of the tag
    function dom:decl(tag)
       if self.options.declNode then
          self.decl = { _type = "DECL",
                _name = tag.name,
                _attr = tag.attrs,
          }
       end
    end
    
    ---Parses a DTD tag.
    -- @param tag a {name, value} table
    -- where name is the name of the tag and value
    -- is a table containing the attributes of the tag
    function dom:dtd(tag)
       if self.options.dtdNode then
          self.dtd = { _type = "DTD",
               _name = tag.name,
               _text = tag.value
          }
       end
    end
    
    --- XML escape characters for a TEXT node.
    -- @param s a string
    -- @return @p s XML escaped.
    local function xmlEscape(s)
       s = string.gsub(s, '&', '&amp;')
       s = string.gsub(s, '<', '&lt;')
       return string.gsub(s, '>', '&gt;')
    end
    
    --- return a string of XML attributes
    -- @param tab table with XML attribute pairs. key and value are supposed to be strings.
    -- @return a string.
    local function attrsToStr(tab)
       if not tab then
          return ''
       end
       if type(tab) == 'table' then
          local s = ''
          for n,v in pairs(tab) do
         -- determine a safe quote character
         local val = tostring(v)
         local found_single_quote = string.find(val, "'")
         local found_double_quote = string.find(val, '"')
         local quot = '"'
         if found_single_quote and found_double_quote then
            -- XML escape both quote characters
            val = string.gsub(val, '"', '&quot;')
            val = string.gsub(val, "'", '&apos;')
         elseif found_double_quote then
            quot = "'"
         end
         s = ' ' .. tostring(n) .. '=' .. quot .. val .. quot
          end
          return s
       end
       return 'BUG:unknown type:' .. type(tab)
    end
    
    --- return a XML formatted string of @p node.
    -- @param node a Node object (table) of the xml2lua DOM tree structure.
    -- @return a string.
    local function toXmlStr(node, indentLevel)
       if not node then
          return 'BUG:node==nil'
       end
       if not node._type then
          return 'BUG:node._type==nil'
       end
    
       local indent = ''
       for i=0, indentLevel+1, 1 do
          indent = indent .. ' '
       end
    
       if node._type == 'ROOT' then
          local s = ''
          for i, n in pairs(node._children) do
         s = s .. toXmlStr(n, indentLevel+2)
          end
          return s
       elseif node._type == 'ELEMENT' then
          local s = indent .. '<' .. node._name .. attrsToStr(node._attr)
    
          -- check if ELEMENT has no children
          if not node._children or
         #node._children == 0 then
         return s .. '/>\n'
          end
    
          s = s .. '>\n'
    
          for i, n in pairs(node._children) do
         local xx = toXmlStr(n, indentLevel+2)
         if not xx then
            print('BUG:xx==nil')
         else
            s = s .. xx
         end
          end
    
          return s .. indent .. '</' .. node._name .. '>\n'
    
       elseif node._type == 'TEXT' then
          return indent .. xmlEscape(node._text) .. '\n'
       elseif node._type == 'COMMENT' then
          return indent .. '<!--' .. node._text .. '-->\n'
       elseif node._type == 'PI' then
          return indent .. '<?' .. node._name .. ' ' .. node._attr._text .. '?>\n'
       elseif node._type == 'DECL' then
          return indent .. '<?' .. node._name .. attrsToStr(node._attr) .. '?>\n'
       elseif node._type == 'DTD' then
          return indent .. '<!' .. node._name .. ' ' .. node._text .. '>\n'
       end
       return 'BUG:unknown type:' .. tostring(node._type)
    end
    
    ---create a string in XML format from the dom root object @p node.
    -- @param node a root object, typically created with `dom` XML parser handler.
    -- @return a string, XML formatted.
    function dom:toXml(node)
       return toXmlStr(node, -4)
    end
    
    ---Parses CDATA tag content.
    dom.cdata = dom.text
    dom.__index = dom
    return dom
end

xml2lua.getTree = getTree
return xml2lua
