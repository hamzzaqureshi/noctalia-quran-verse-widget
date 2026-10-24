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

local function formatVerseCitation(v)
    if v == nil then return "" end
    local surahName = tostring(v.surah or "")
    if not surahName:match("^Surah%s+") and not surahName:match("^SURAH%s+") then
        surahName = "Surah " .. surahName
    end
    return string.format("%s %d:%d", surahName, v.surahNumber or 1, v.number or 1)
end

print("Test 4: Citation formatting without Surah prefix")
local c1 = formatVerseCitation({ surah = "Sad", surahNumber = 38, number = 88 })
assert(c1 == "Surah Sad 38:88", "Test 4 failed: " .. c1)
print("  Pass: " .. c1)

print("Test 5: Citation formatting with existing Surah prefix")
local c2 = formatVerseCitation({ surah = "Surah Al-Baqarah", surahNumber = 2, number = 255 })
assert(c2 == "Surah Al-Baqarah 2:255", "Test 5 failed: " .. c2)
print("  Pass: " .. c2)

print("Test 6: Copy formatted output verification")
local mockVerse = {
    surah = "Sad",
    surahNumber = 38,
    number = 88,
    text = "“And you shall certainly know the truth of it after a while.”",
    author = "Hilali-Khan",
    url = "https://quran.com/38:88",
}
local cleanMock = cleanTranslation(mockVerse.text)
local citationMock = formatVerseCitation(mockVerse)
local copyText = string.format("“%s”\n— %s", cleanMock, citationMock)
assert(string.find(copyText, "— Surah Sad 38:88"), "Test 6 missing citation: " .. copyText)
print("  Pass: Copy formatted output contains Surah name and verse number")

print("All edge case unit tests PASSED")
