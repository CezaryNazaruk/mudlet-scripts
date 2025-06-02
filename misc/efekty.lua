-- Script prepared by gnomidlo, edited by Riv
-- Version 1.3 
--------------------------------------------------------------------------------
local COMBINED_DEBUG = false 

--------------------------------------------------------------------------------
-- KONFIGURACJA: Kolory (Dla Efektow Postaci)
--------------------------------------------------------------------------------
local CHAR_EFFECT_COLOR = {
  positive = "pale_green",
  negative = "light_coral",
  neutral = "navajo_white",
  boolean = "pale_green",
  bracket = "dodger_blue",
  effectName = "cornflower_blue",
}

--------------------------------------------------------------------------------
-- KONFIGURACJA: Wartosci przymiotnikow (Dla Efektow Postaci)
--------------------------------------------------------------------------------
local CHAR_ADJ = {
  minimalnie = 1,  nieznacznie = 2,
  nieco = 3,  troche = 4,  zauwazalnie = 5,
  sporo = 6,  znacznie = 7,  bardzo = 8,  ogromnie = 9,
}

--------------------------------------------------------------------------------
-- KONFIGURACJA: Kolory (Dla Efektow Przedmiotow i Aur)
--------------------------------------------------------------------------------
local ITEM_COLOR = {
  positive      = "pale_green",
  negative      = "light_coral",
  neutral       = "navajo_white",
  boolean       = "pale_green",
  bracket       = "dodger_blue",
  effectTitleSplugawienie = "violet",
  effectTitleUmagicznienie = "sky_blue",
  specialEffect = "gold",
  defaultText   = "reset",
  propertyName  = "white"
}

--------------------------------------------------------------------------------
-- KONFIGURACJA: Wartosci poziomow efektow (przymiotnikow) (Dla Efektow Przedmiotow i Aur)
--------------------------------------------------------------------------------
local ITEM_EFFECT_LEVELS = {
  minimalnie  = 1, nieznacznie = 2,
  nieco       = 3, troche     = 4, zauwazalnie = 5,
  sporo       = 6, znacznie   = 7, bardzo     = 8, ogromnie    = 9,
}

local ITEM_PROTECTED_PREFIXES = {
    "umiejetnosc w",
    "odpornosc na",
    "odpornosci na",
    "obrazenia od"
}
local ITEM_PROTECTED_I_PLACEHOLDER = " _PROT_I_ "
local ITEM_PROTECTED_ORAZ_PLACEHOLDER = " _PROT_ORAZ_ "

local SPECIAL_EFFECT_EXCEPTION_PHRASES = {
  ["pozwala uzywac tarczy, parowac i unikac podczas czarowania"] = "[[PROTECTEDSPECCOMMA_001]]"
}
local REVERSE_SPECIAL_EFFECT_EXCEPTION_PHRASES = {}
for k, v in pairs(SPECIAL_EFFECT_EXCEPTION_PHRASES) do
  REVERSE_SPECIAL_EFFECT_EXCEPTION_PHRASES[v] = k
end

--------------------------------------------------------------------------------
-- NARZEDZIA POMOCNICZE
--------------------------------------------------------------------------------
local function stripAnsi_char(s) return s:gsub("\27%[[0-9;]*m", "") end
local function trim_char(s) return s:match("^%s*(.-)%s*$") end

local function stripAnsiCodes_item(text)
  if text then return text:gsub("\27%[[0-9;]*m", "") end; return ""
end
local function trimWhitespace_item(text)
  if text then return text:match("^%s*(.-)%s*$") end; return ""
end
local function normalizeSpaces_item(text)
  if text then text = text:gsub("\194\160", " ") end; return text
end

--------------------------------------------------------------------------------
-- Funkcja dodajaca kolorowe formatowanie do GLOWNEJ wartosci (Dla Efektow Postaci)
--------------------------------------------------------------------------------
local function colorValue_char(value)
  if value == "V" then
    return "<"..CHAR_EFFECT_COLOR.bracket..">[ <"..CHAR_EFFECT_COLOR.boolean..">!!<reset><"..CHAR_EFFECT_COLOR.bracket.."> ]<reset>"
  elseif value > 0 then
    return "<"..CHAR_EFFECT_COLOR.bracket..">[ <"..CHAR_EFFECT_COLOR.positive..">+"..value.."<reset><"..CHAR_EFFECT_COLOR.bracket.."> ]<reset>"
  elseif value < 0 then
    return "<"..CHAR_EFFECT_COLOR.bracket..">[ <"..CHAR_EFFECT_COLOR.negative..">"..value.."<reset><"..CHAR_EFFECT_COLOR.bracket.."> ]<reset>"
  else -- value == 0
    return "<"..CHAR_EFFECT_COLOR.bracket..">[ <"..CHAR_EFFECT_COLOR.neutral..">0 <reset><"..CHAR_EFFECT_COLOR.bracket.."> ]<reset>"
  end
end

--------------------------------------------------------------------------------
-- Funkcja do parsowania efektow postaci (effects_replacer.lua)
--------------------------------------------------------------------------------
function parseCharacterEffects(line)
  line = stripAnsi_char(line)
  local effect, description = line:match("^(.-):%s*(.-)%.$")
  if not effect or not description then return nil end
  local coloredEffectName = "<"..CHAR_EFFECT_COLOR.effectName..">" .. effect .. "<reset>"
  if not description:find("podnosi") and not description:find("obniza") then
    return colorValue_char("V") .. " " .. coloredEffectName .. ": (" .. description .. ")"
  end
  description = description:gsub(" oraz ", ", "):gsub("%s+natomiast%s+", ";")
  local total = 0; local parts = {}
  for section in description:gmatch("[^;]+") do
    section = trim_char(section)
    local direction = nil
    if section:sub(1, 8) == "podnosi " then direction = "podnosi"; section = section:sub(9)
    elseif section:sub(1, 7) == "obniza " then direction = "obniza"; section = section:sub(8) end
    if direction then
      for item in section:gmatch("[^,]+") do
        item = trim_char(item); local found = false
        for adj_name, adj_value in pairs(CHAR_ADJ) do
          local pattern = "%s+" .. adj_name .. "$"
          if item:match(pattern) or item == adj_name then
            local item_name = item:gsub(pattern, ""); item_name = trim_char(item_name)
            local value = adj_value; if direction == "obniza" then value = -value end
            total = total + value
            local color = (value > 0) and CHAR_EFFECT_COLOR.positive or CHAR_EFFECT_COLOR.negative
            local sign = (value > 0) and "+" or ""
            parts[#parts+1] = "<"..color..">"..sign..value.."<reset>" .. " " .. item_name
            found = true; break
          end
        end
        if not found then
          for adj_name, adj_value in pairs(CHAR_ADJ) do
            if item:find(" " .. adj_name .. "$") then
              local item_name = item:sub(1, -(#adj_name + 2)); item_name = trim_char(item_name)
              local value = adj_value; if direction == "obniza" then value = -value end
              total = total + value
              local color = (value > 0) and CHAR_EFFECT_COLOR.positive or CHAR_EFFECT_COLOR.negative
              local sign = (value > 0) and "+" or ""
              parts[#parts+1] = "<"..color..">"..sign..value.."<reset>" .. " " .. item_name
              found = true; break
            end
          end
        end
        if not found and item ~= "" then parts[#parts+1] = "<"..CHAR_EFFECT_COLOR.neutral..">?<reset> " .. item end
      end
    end
  end
  return colorValue_char(total) .. " " .. coloredEffectName .. ": (" .. table.concat(parts, ", ") .. ")"
end

--------------------------------------------------------------------------------
-- Funkcja sprawdzajaca, czy linia wyglada jak efekt postaci (effects_replacer.lua)
--------------------------------------------------------------------------------
function isCharacterEffectLine(line)
    line = stripAnsi_char(line)
    if #line > 300 then 
        return false 
    end
    local effect, description = line:match("^(.-):%s*(.-)%.$")
    if not effect or not description then 
        return false 
    end
    if description:match("^%(.-%)$") and description:find(",") then 
        return false 
    end
    if effect:find("widzisz") then 
        return false 
    end
    
    local knownSources = {"osiagniecia", "slowa runiczne", "kula na lancuchu", "zombie", "totem", "okolica", "obraczka", "kaftan", "aketon", "kaftan z ludzkiej skory"}
    if description:find("podnosi") or description:find("obniza") then 
        return true 
    end
    for _, source in ipairs(knownSources) do 
        if trim_char(description) == source then 
            return true 
        end 
    end
    local boolKeywords = {"pozwala", "widz", "energi", "runy"}; local contextKeywords = {"obraczka", "okolica"}
    local foundBoolKeyword, foundContextKeyword = false, false
    for _, keyword in ipairs(boolKeywords) do 
        if effect:find(keyword) or description:find(keyword) then 
            foundBoolKeyword = true
            break 
        end 
    end
    if foundBoolKeyword then 
        for _, keyword in ipairs(contextKeywords) do 
            if description:find(keyword) 
                then foundContextKeyword = true
                break 
            end 
        end 
    end
    if foundBoolKeyword and foundContextKeyword then 
        return true 
    end
    local effectNamePatterns = {"^ilosc", "^szczescie", "^regeneracje", "^szybkosc", "^prawdopodobienstwo", "^odpornosc", "^wielkosc", "^pozwala", "^sprawia ze", "^nie pozwala na sprzedaz przedmiotu", "^nikt nie zapyta cie o kompetencje"}
    for _, pattern in ipairs(effectNamePatterns) do 
        if effect:lower():match(pattern) then 
            return true 
        end 
    end
    return false
end

--------------------------------------------------------------------------------
-- GLOWNA FUNKCJA PARSUJACA (Dla Efektow Przedmiotow i Aur - MagicItemFormatter_v18.lua)
--------------------------------------------------------------------------------
function formatMagicItemProperties_v18(line)
    local originalLine = line; local processedLine = stripAnsiCodes_item(line); processedLine = normalizeSpaces_item(processedLine)
    local effectType, effectTitleText, effectTitleColor, prefixToRemove = nil, "", ITEM_COLOR.defaultText, ""
    local emanujeMatch = {processedLine:match("^(Emanuj[ae] ciemna energia, ktora%s*)")}
    local wyczuwaszItemMatch = {processedLine:match("^(Wyczuwasz, ze posiada aure, ktora%s*)")}
    local wyczuwaszAuraOkolicyMatch = {processedLine:match("^(Wyczuwasz ze ta okolica posiada aure ktora%s*)")}

    if emanujeMatch[1] then
        effectType = "splugawienie"; prefixToRemove = emanujeMatch[1]
        effectTitleText = "EFEKTY SPLUGAWIENIA"
        effectTitleColor = ITEM_COLOR.effectTitleSplugawienie
    elseif wyczuwaszItemMatch[1] then
        effectType = "umagicznienie"; prefixToRemove = wyczuwaszItemMatch[1]
        effectTitleText = "EFEKTY PRZEDMIOTU"
        effectTitleColor = ITEM_COLOR.effectTitleUmagicznienie
    elseif wyczuwaszAuraOkolicyMatch[1] then
        effectType = "umagicznienie_okolicy"
        prefixToRemove = wyczuwaszAuraOkolicyMatch[1]
        effectTitleText = "EFEKTY AURY OKOLICY"; effectTitleColor = ITEM_COLOR.effectTitleUmagicznienie
    else
        return nil
    end
    local propertiesString = processedLine:sub(#prefixToRemove + 1)
    propertiesString = propertiesString:gsub("%.?$", "")
    propertiesString = trimWhitespace_item(propertiesString)
    propertiesString = propertiesString:gsub("%s+natomiast%s+", " ponadto ")
    local formattedLines, clauses, tempPropertiesString = {}, {}, propertiesString
    if tempPropertiesString ~= "" then 
        repeat
            local s, e = tempPropertiesString:find(" ponadto ", 1, true)
            if s then 
                table.insert(clauses, trimWhitespace_item(tempPropertiesString:sub(1, s - 1)))
                tempPropertiesString = trimWhitespace_item(tempPropertiesString:sub(e + 1))
            else 
                table.insert(clauses, trimWhitespace_item(tempPropertiesString)); tempPropertiesString = "" 
            end
        until tempPropertiesString == "" 
    end

    for clause_idx, clause in ipairs(clauses) do
        if clause ~= "" then
            local podnosiPrefix = "podnosi "
            local obnizaPrefix = "obniza "
            local numericEffectsString, effectSign, effectValueColor = nil, "+", ITEM_COLOR.positive
            if clause:sub(1, #podnosiPrefix) == podnosiPrefix then 
                numericEffectsString = trimWhitespace_item(clause:sub(#podnosiPrefix + 1))
                effectSign = "+"
                effectValueColor = ITEM_COLOR.positive
            elseif clause:sub(1, #obnizaPrefix) == obnizaPrefix then 
                numericEffectsString = trimWhitespace_item(clause:sub(#obnizaPrefix + 1))
                effectSign = "-"; effectValueColor = ITEM_COLOR.negative 
            end
            if numericEffectsString == "" then 
                numericEffectsString = nil 
            end

            if numericEffectsString then
                local tempNumEffects = numericEffectsString
                for _, prefix in ipairs(ITEM_PROTECTED_PREFIXES) do
                    local pattern_i = "(" .. prefix .. "%s*[^,]+)%s+i%s+([^,]+)"; local pattern_oraz = "(" .. prefix .. "%s*[^,]+)%s+oraz%s+([^,]+)"
                    local function cr_i(c1,c2) 
                        local pa_i=trimWhitespace_item(c2) 
                        for l,_ in pairs(ITEM_EFFECT_LEVELS) do 
                            if pa_i:sub(1,#l)==l and pa_i:match("^"..l.."%s") then 
                                return c1.." i "..c2 
                            end 
                        end 
                        return c1..ITEM_PROTECTED_I_PLACEHOLDER..c2 
                    end
                    local function cr_o(c1,c2) 
                        local pa_o=trimWhitespace_item(c2) 
                        for l,_ in pairs(ITEM_EFFECT_LEVELS) do 
                            if pa_o:sub(1,#l)==l and pa_o:match("^"..l.."%s") then 
                                return c1.." oraz "..c2 
                            end 
                        end 
                        return c1..ITEM_PROTECTED_ORAZ_PLACEHOLDER..c2 
                    end
                    tempNumEffects = tempNumEffects:gsub(pattern_i, cr_i)
                    tempNumEffects = tempNumEffects:gsub(pattern_oraz, cr_o)
                end
                tempNumEffects = tempNumEffects:gsub("%s+oraz%s+", ", ")
                tempNumEffects = tempNumEffects:gsub("%s+i%s+", ", ")
                tempNumEffects = tempNumEffects:gsub(ITEM_PROTECTED_I_PLACEHOLDER, " i ")
                tempNumEffects = tempNumEffects:gsub(ITEM_PROTECTED_ORAZ_PLACEHOLDER, " oraz ")
                local individualNumericEffects = {}
                for effect in tempNumEffects:gmatch("([^,]+)") do 
                    local trEf=trimWhitespace_item(effect) 
                    if trEf~="" then 
                        table.insert(individualNumericEffects,trEf) 
                    end 
                end
                for _,effectItem in ipairs(individualNumericEffects) do 
                    local foundLvl=false 
                    for lvlNm,lvlVal in pairs(ITEM_EFFECT_LEVELS) do 
                        local patt="^"..lvlNm.."%s+(.+)"
                        local pNmMatch={effectItem:match(patt)} 
                        if pNmMatch[1] then 
                            local pNm=trimWhitespace_item(pNmMatch[1])
                            local dVal="<"..ITEM_COLOR.bracket..">[ <"..effectValueColor..">"..effectSign..lvlVal.."<"..ITEM_COLOR.defaultText.."><"..ITEM_COLOR.bracket.."> ]<"..ITEM_COLOR.defaultText..">"
                            table.insert(formattedLines,dVal.." <"..ITEM_COLOR.propertyName..">"..pNm.."<"..ITEM_COLOR.defaultText..">"); foundLvl=true
                            break 
                        end 
                    end 
                    if not foundLvl then 
                        local dBool="<"..ITEM_COLOR.bracket..">[ <"..ITEM_COLOR.boolean..">??<"..ITEM_COLOR.defaultText.."><"..ITEM_COLOR.bracket.."> ]<"..ITEM_COLOR.defaultText..">"
                        table.insert(formattedLines,dBool.." <"..ITEM_COLOR.specialEffect..">"..effectItem.."<"..ITEM_COLOR.defaultText..">") 
                    end 
                end
            else -- Efekty specjalne (nie numeryczne)
                local currentSpecialClause = clause; currentSpecialClause = currentSpecialClause:gsub("^sprawia ze%s+", ""); currentSpecialClause = trimWhitespace_item(currentSpecialClause)
                if currentSpecialClause ~= "" then
                    local tempSpecialClauseForProcessing = currentSpecialClause
                    -- KROK 1: Ochrona fraz-wyjatkow
                    for phrase, placeholder in pairs(SPECIAL_EFFECT_EXCEPTION_PHRASES) do
                        local search_from = 1
                        local built_clause = ""
                        local original_len = #tempSpecialClauseForProcessing
                        local made_replacement = false
                        while search_from <= original_len do
                            local s, e = tempSpecialClauseForProcessing:find(phrase, search_from, true) -- true for plain search
                            if s then 
                                built_clause = built_clause .. tempSpecialClauseForProcessing:sub(search_from, s - 1) .. placeholder; search_from = e + 1
                                made_replacement = true
                            else 
                                built_clause = built_clause .. tempSpecialClauseForProcessing:sub(search_from)
                                break 
                            end
                        end
                        if made_replacement then 
                            tempSpecialClauseForProcessing = built_clause 
                        end
                    end

                    -- KROK 2: Normalizacja separatorow i podzial
                    local specialSubClauses = {}
                    local stringToSplit = tempSpecialClauseForProcessing
                    stringToSplit = stringToSplit:gsub("%s+oraz%s+", ", ")
                    stringToSplit = stringToSplit:gsub("%s+i%s+", ", ")
                    local anything_added_to_subclauses = false
                    for subClausePart in stringToSplit:gmatch("([^,]+)") do
                        local trimmedSubClausePart = trimWhitespace_item(subClausePart)
                        if trimmedSubClausePart ~= "" then 
                            table.insert(specialSubClauses, trimmedSubClausePart)
                            anything_added_to_subclauses = true 
                        end
                    end
                    if not anything_added_to_subclauses and trimWhitespace_item(stringToSplit) ~= "" then -- Jeśli gmatch nic nie znalazł, a string nie był pusty (np. był to tylko placeholder)
                        table.insert(specialSubClauses, trimWhitespace_item(stringToSplit))
                    end
                
                    -- KROK 3: Przywracanie placeholderow i dodawanie do wyniku
                    for _, subClauseItem in ipairs(specialSubClauses) do
                        if subClauseItem ~= "" then
                            local finalSubClauseText = subClauseItem
                            if REVERSE_SPECIAL_EFFECT_EXCEPTION_PHRASES[subClauseItem] then -- Sprawdz, czy to placeholder
                                finalSubClauseText = REVERSE_SPECIAL_EFFECT_EXCEPTION_PHRASES[subClauseItem] -- Przywroc oryginalna fraze
                            end
                            local prefix_display = "<"..ITEM_COLOR.bracket..">[ <"..ITEM_COLOR.boolean..">!!<"..ITEM_COLOR.defaultText.."><"..ITEM_COLOR.bracket.."> ]<"..ITEM_COLOR.defaultText..">"
                            table.insert(formattedLines, prefix_display .. " <"..ITEM_COLOR.specialEffect..">"..finalSubClauseText.."<"..ITEM_COLOR.defaultText..">")
                        end
                    end
                end
            end
        end
    end

    if #formattedLines == 0 and propertiesString ~= "" then
        local dBool = "<"..ITEM_COLOR.bracket..">[ <"..ITEM_COLOR.boolean..">??<"..ITEM_COLOR.defaultText.."><"..ITEM_COLOR.bracket.."> ]<"..ITEM_COLOR.defaultText..">"
        table.insert(formattedLines, dBool .. " <"..ITEM_COLOR.specialEffect..">"..propertiesString.."<"..ITEM_COLOR.defaultText..">")
    elseif #formattedLines == 0 and propertiesString == "" and effectType then
        return nil
    end
    local title = "<"..effectTitleColor..">"..effectTitleText.."<"..ITEM_COLOR.defaultText..">:"; local finalOutput = "\n" .. title
    for _, partLine in ipairs(formattedLines) do 
        finalOutput = finalOutput .. "\n  " .. partLine 
    end
    return finalOutput
end

--------------------------------------------------------------------------------
-- TRIGGERY (Dla Efektow Postaci - effects_replacer.lua)
--------------------------------------------------------------------------------
local char_capturing = false; local char_original_lines = {}

if char_ef_repl_hdr then 
    killTrigger(char_ef_repl_hdr) 
end

if char_ef_repl_line then 
    killTrigger(char_ef_repl_line) 
end

if char_capture_timer then 
    killTimer(char_capture_timer)
end

char_ef_repl_hdr = tempTrigger("Efekty specjalne dzialajace na ciebie.", function() 
    char_capturing = true
    char_original_lines = {}
    disableTimer(char_capture_timer) 
end)

char_ef_repl_line = tempRegexTrigger("^([^:]+):.*\\.$", function()
    if not char_capturing then 
        return 
    end
    local currentLine = getCurrentLine()
    if isCharacterEffectLine(currentLine) then
        char_original_lines[#char_original_lines + 1] = currentLine 
        local parsed = parseCharacterEffects(currentLine)
        if parsed then 
            selectCurrentLine()
            creplaceLine(parsed)
        end
        enableTimer(char_capture_timer)
        resetTimer(char_capture_timer)
    else
        if trim_char(stripAnsi_char(currentLine)) == "" or currentLine:match("^%[") or currentLine:match("^> ") then 
            stopCharacterEffectCapturing()
        else 
            enableTimer(char_capture_timer)
            resetTimer(char_capture_timer) 
        end
    end
end)

local CHAR_CAPTURE_TIMEOUT = 2

function stopCharacterEffectCapturing() 
    if char_capturing then 
        char_capturing = false
        disableTimer(char_capture_timer)
    end 
end

char_capture_timer = tempTimer(CHAR_CAPTURE_TIMEOUT, function() 
    stopCharacterEffectCapturing() 
end)

disableTimer(char_capture_timer)
if char_ef_repl_timer_reset then 
    killTrigger(char_ef_repl_timer_reset)
    char_ef_repl_timer_reset = nil 
end

--------------------------------------------------------------------------------
-- TRIGGERY (Dla Efektow Przedmiotow, Aur Okolicy i Ksiazek - MagicItemFormatter_v18.lua)
--------------------------------------------------------------------------------
if item_book_level_trigger then 
    killTrigger(item_book_level_trigger) 
end
item_book_level_trigger = tempRegexTrigger("^Ta ksiazka zawiera (.+) stron\.$", function() 
    creplaceLine("<white>POZIOM: <pale_green>"..matches[2].."<reset>\n") 
end)
if item_magic_item_trigger_v18 then 
    killTrigger(item_magic_item_trigger_v18) 
end
item_magic_item_trigger_v18 = tempRegexTrigger("^(Emanuj[ae] ciemna energia, ktora|Wyczuwasz, ze posiada aure, ktora|Wyczuwasz ze ta okolica posiada aure ktora).*", function()
  local currentLine = getCurrentLine()
  local formatted = formatMagicItemProperties_v18(currentLine)
  if formatted then 
    selectCurrentLine()
    deleteLine()
    cecho(formatted.."\n")
  end
end)