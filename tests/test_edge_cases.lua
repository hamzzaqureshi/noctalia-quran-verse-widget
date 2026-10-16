local function cleanTranslation(text)
    if text == nil then return "" end
    local s = tostring(text):gsub("<sup[^>]*>.-</sup>", ""):gsub("<[^>]+>", "")
    s = s:gsub("^%d+%.%s*", ""):gsub("%s+", " ")
    s = s:gsub("^%s+", ""):gsub("%s+$", "")
    -- Strip existing surrounding quotes to prevent double-quote artifacts
    s = s:gsub('^["\'“”]+', ""):gsub('["\'“”]+$', "")
    s = s:gsub('["\'“”]%.$', ".")
    return s:gsub("^%s+", ""):gsub("%s+$", "")
end

print("Test 1: Normal translation")
local t1 = cleanTranslation('“In the Name of Allah, the Most Beneficent, the Most Merciful.”')
assert(t1 == "In the Name of Allah, the Most Beneficent, the Most Merciful.", "Test 1 failed: " .. t1)
print("  Pass: " .. t1)

print("Test 2: Surah Al-Mu'minun 23:72 with Arabic calligraphy")
local raw23_72 = '“Or is it that you (O Muhammad صلى الله عليه وسلم) ask them for some wages? But the recompense of your Lord is better, and He is the Best of those who give sustenance.”'
local t2 = cleanTranslation(raw23_72)
assert(string.find(t2, "صلى الله عليه وسلم"), "Test 2 missing Arabic")
print("  Pass: Length " .. #t2 .. " chars")

print("Test 3: Footnotes and tags")
local t3 = cleanTranslation('<sup foot_note=1>1</sup>23. Some verse text<span class="arabic">test</span>.')
assert(t3 == "Some verse texttest.", "Test 3 failed: " .. t3)
print("  Pass: " .. t3)

print("All edge case unit tests PASSED")
