--!nonstrict

-- Daily Quran Verse Desktop Widget
-- Author: Hamza Qureshi (hamzzaqureshi)
-- License: MIT

local QURAN_COM_API = "https://api.quran.com/api/v4/verses/by_key"
local QURANENC_API = "https://quranenc.com/api/v1/translation/aya/english_hilali_khan"
local USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64) Noctalia-Quran-Verse-Widget/1.0"

local TOTAL_QURAN_VERSES = 6236
local FETCH_DEBOUNCE = 30
local REFRESH_COOLDOWN = 1
local ERROR_RETRY_AFTER = 90
local NOTICE_SECONDS = 2
local WIDTH, HEIGHT = 420, 260

math.randomseed(os.time())

-- 114 Surah transliterations
local SURAH_NAMES = {
    "Al-Fatihah", "Al-Baqarah", "Ali 'Imran", "An-Nisa", "Al-Ma'idah", "Al-An'am",
    "Al-A'raf", "Al-Anfal", "At-Tawbah", "Yunus", "Hud", "Yusuf",
    "Ar-Ra'd", "Ibrahim", "Al-Hijr", "An-Nahl", "Al-Isra", "Al-Kahf",
    "Maryam", "Taha", "Al-Anbiya", "Al-Hajj", "Al-Mu'minun", "An-Nur",
    "Al-Furqan", "Ash-Shu'ara", "An-Naml", "Al-Qasas", "Al-'Ankabut", "Ar-Rum",
    "Luqman", "As-Sajdah", "Al-Ahzab", "Saba", "Fatir", "Ya-Sin",
    "As-Saffat", "Sad", "Az-Zumar", "Ghafir", "Fussilat", "Ash-Shura",
    "Az-Zukhruf", "Ad-Dukhan", "Al-Jathiyah", "Al-Ahqaf", "Muhammad", "Al-Fath",
    "Al-Hujurat", "Qaf", "Adh-Dhariyat", "At-Tur", "An-Najm", "Al-Qamar",
    "Ar-Rahman", "Al-Waqi'ah", "Al-Hadid", "Al-Mujadila", "Al-Hashr", "Al-Mumtahanah",
    "As-Saff", "Al-Jumu'ah", "Al-Munafiqun", "At-Taghabun", "At-Talaq", "At-Tahrim",
    "Al-Mulk", "Al-Qalam", "Al-Haqqah", "Al-Ma'arij", "Nuh", "Al-Jinn",
    "Al-Muzzammil", "Al-Muddaththir", "Al-Qiyamah", "Al-Insan", "Al-Mursalat", "An-Naba",
    "An-Nazi'at", "'Abasa", "At-Takwir", "Al-Infitar", "Al-Mutaffifin", "Al-Inshiqaq",
    "Al-Buruj", "At-Tariq", "Al-A'la", "Al-Ghashiyah", "Al-Fajr", "Al-Balad",
    "Ash-Shams", "Al-Layl", "Ad-Duha", "Ash-Sharh", "At-Tin", "Al-'Alaq",
    "Al-Qadr", "Al-Bayyinah", "Az-Zalzalah", "Al-'Adiyat", "Al-Qari'ah", "At-Takathur",
    "Al-'Asr", "Al-Humazah", "Al-Fil", "Quraysh", "Al-Ma'un", "Al-Kawthar",
    "Al-Kafirun", "An-Nasr", "Al-Masad", "Al-Ikhlas", "Al-Falaq", "An-Nas",
}

-- 114 Surah verse counts (sum = 6,236)
local SURAH_VERSE_COUNTS = {
    7, 286, 200, 176, 120, 165, 206, 75, 129, 109,
    123, 111, 43, 52, 99, 128, 111, 110, 98, 135,
    112, 78, 118, 64, 77, 227, 93, 88, 69, 60,
    34, 30, 73, 54, 45, 83, 182, 88, 75, 85,
    54, 53, 89, 59, 37, 35, 38, 29, 18, 45,
    60, 49, 62, 55, 78, 96, 29, 22, 24, 13,
    14, 11, 11, 18, 12, 12, 30, 52, 52, 44,
    28, 28, 20, 56, 40, 31, 50, 40, 46, 42,
    29, 19, 36, 25, 22, 17, 19, 26, 30, 20,
    15, 21, 11, 8, 8, 19, 5, 8, 8, 11,
    11, 8, 3, 9, 5, 4, 7, 3, 6, 3,
    5, 4, 5, 6,
}

local ERROR_TEXTS = {
    network = "Network error",
    http429 = "Rate limited — please wait",
    http503 = "Server busy",
    http = "API error",
    json = "Malformed response",
    invalid = "Invalid response",
    start = "Failed to start request",
}

-- State
local verse = nil
local todayVerse = nil
local isRandomMode = false
local loading = false
local cachedDay = nil
local lastFetchClock = nil
local lastPollClock = nil
local lastErrorTime = nil
local errorKind = nil
local notice = nil
local noticeUntil = nil
local manualPending = false
local dataFile = nil

-- Instant Refresh Prefetch Pool
local prefetchPool = {}
local isPrefetching = false

local render -- forward declaration
local refillPrefetchPool -- forward declaration

local function todayKey()
    return os.date("%Y-%j")
end

local function verseForDate(key)
    local yearStr, ydayStr = tostring(key):match("^(%d+)%-(%d+)$")
    local year = tonumber(yearStr) or 2026
    local yday = tonumber(ydayStr) or 1
    local leaps = math.floor((year - 1) / 4) - math.floor((year - 1) / 100) + math.floor((year - 1) / 400)
    local dayNum = (year - 1) * 365 + leaps + yday
    local remaining = ((dayNum - 1) % TOTAL_QURAN_VERSES) + 1

    for surah = 1, 114 do
        local count = SURAH_VERSE_COUNTS[surah]
        if remaining <= count then
            return surah, remaining
        end
        remaining = remaining - count
    end
    return 1, 1
end

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

local function saveVerse(key)
    if dataFile == nil or verse == nil then return end
    local dir = noctalia.pluginDataDir()
    if dir ~= nil and noctalia.mkdirAll ~= nil then
        noctalia.mkdirAll(dir)
    end
    local encoded = noctalia.json.encode({ day = key, verse = verse })
    if encoded ~= nil then
        noctalia.writeFile(dataFile, encoded)
    end
end

local function loadCachedVerse()
    if dataFile == nil then return end
    local raw = noctalia.readFile(dataFile)
    if raw == nil then return end
    local decoded = noctalia.json.decode(raw)
    if decoded == nil or decoded.verse == nil then return end

    verse = decoded.verse
    cachedDay = decoded.day
    if cachedDay == todayKey() then
        todayVerse = decoded.verse
        isRandomMode = false
    end
end

local function setNotice(text)
    notice = tostring(text)
    noticeUntil = os.time() + NOTICE_SECONDS
end

local function clearNotice()
    notice = nil
    noticeUntil = nil
end

-- Global Action Handlers (invoked by UI callbacks)
function copyVerseAction()
    if verse == nil or verse.text == nil or tostring(verse.text) == "" then return end
    if noctalia.copyToClipboard(cleanTranslation(verse.text), "text/plain") then
        setNotice("Verse copied")
        render()
    end
end

function copyShareAction()
    if verse == nil then return end
    local clean = cleanTranslation(verse.text)
    local ref = string.format("%s %d:%d · %s", verse.surah or "", verse.surahNumber or 1, verse.number or 1, verse.author or "Hilali-Khan")
    local share = string.format("“%s”\n%s", clean, ref)
    if verse.url and tostring(verse.url) ~= "" then
        share = share .. "\n" .. tostring(verse.url)
    end
    if noctalia.copyToClipboard(share, "text/plain") then
        setNotice("Share citation copied")
        render()
    end
end

-- Instant 0ms refresh handler: consumes pre-fetched verse if available
function manualRefreshAction()
    clearNotice()
    if #prefetchPool > 0 then
        local nextVerse = table.remove(prefetchPool, 1)
        verse = nextVerse
        isRandomMode = true
        errorKind = nil
        lastFetchClock = os.time()
        setNotice("Random verse")
        render()
        refillPrefetchPool()
        return
    end

    lastPollClock = nil
    manualPending = true
    update()
end

function showTodayVerseAction()
    clearNotice()
    if todayVerse ~= nil then
        verse = todayVerse
        isRandomMode = false
        setNotice("Today's verse")
        render()
    else
        isRandomMode = false
        fetchDailyVerse(todayKey())
    end
end

function openVerse()
    if verse == nil or verse.url == nil or tostring(verse.url) == "" then return end
    noctalia.runAsync({ "xdg-open", tostring(verse.url) }, nil)
end

local function pickRandomVerse(curSurah, curAyah)
    local surah = math.random(1, 114)
    local maxAyah = SURAH_VERSE_COUNTS[surah] or 1
    local ayah = math.random(1, maxAyah)
    if curSurah ~= nil and curAyah ~= nil and surah == curSurah and ayah == curAyah and maxAyah > 1 then
        ayah = (ayah % maxAyah) + 1
    end
    return surah, ayah
end

local function applyVerseSuccess(verseData, isRandom, key)
    verse = verseData
    errorKind = nil
    lastErrorTime = nil
    lastFetchClock = os.time()

    if isRandom then
        isRandomMode = true
        setNotice("Random verse")
    else
        isRandomMode = false
        todayVerse = verseData
        cachedDay = key
        saveVerse(key)
    end
    render()
end

local function httpGet(url, callback)
    return noctalia.http({
        url = url,
        method = "GET",
        headers = { "Accept: application/json", "User-Agent: " .. USER_AGENT },
    }, callback)
end

-- Unified fetch abstraction with Quran.com v4 + QuranEnc fallback
local function fetchVerseData(surah, ayah, callback)
    local surahName = SURAH_NAMES[surah] or ("Surah " .. tostring(surah))
    local browseUrl = string.format("https://quran.com/%d:%d", surah, ayah)

    local function tryQuranEncFallback()
        local encUrl = string.format("%s/%d/%d", QURANENC_API, surah, ayah)
        local started = httpGet(encUrl, function(res)
            if not res.ok or res.status < 200 or res.status >= 300 then
                callback(nil, res.status)
                return
            end

            local decoded = noctalia.json.decode(res.body)
            if decoded == nil or decoded.result == nil or decoded.result.translation == nil then
                callback(nil, "invalid")
                return
            end

            callback({
                surah = surahName,
                surahNumber = surah,
                number = ayah,
                text = cleanTranslation(decoded.result.translation),
                author = "Hilali-Khan",
                url = browseUrl,
            }, nil)
        end)

        if not started then
            callback(nil, "start")
        end
    end

    local primaryUrl = string.format("%s/%d:%d?translations=203", QURAN_COM_API, surah, ayah)
    local started = httpGet(primaryUrl, function(res)
        if res.ok and res.status >= 200 and res.status < 300 then
            local decoded = noctalia.json.decode(res.body)
            if decoded and decoded.verse and decoded.verse.translations and #decoded.verse.translations > 0 then
                local transText = decoded.verse.translations[1].text or ""
                for _, t in ipairs(decoded.verse.translations) do
                    if t.resource_id == 203 and t.text then
                        transText = t.text
                        break
                    end
                end
                callback({
                    surah = surahName,
                    surahNumber = surah,
                    number = ayah,
                    text = cleanTranslation(transText),
                    author = "Hilali-Khan",
                    url = browseUrl,
                }, nil)
                return
            end
        end
        tryQuranEncFallback()
    end)

    if not started then
        tryQuranEncFallback()
    end
end

-- Asynchronously keeps 2 random verses in memory for instantaneous (0ms) clicks
refillPrefetchPool = function()
    if isPrefetching or #prefetchPool >= 2 then return end
    isPrefetching = true
    local randSurah, randAyah = pickRandomVerse(verse and verse.surahNumber, verse and verse.number)
    fetchVerseData(randSurah, randAyah, function(verseData, err)
        isPrefetching = false
        if verseData ~= nil then
            table.insert(prefetchPool, verseData)
            if #prefetchPool < 2 then
                refillPrefetchPool()
            end
        end
    end)
end

local function fetchVerse(surah, ayah, isRandom, key)
    if loading then return end
    loading = true
    render()

    fetchVerseData(surah, ayah, function(verseData, err)
        loading = false
        if verseData ~= nil then
            applyVerseSuccess(verseData, isRandom, key)
            refillPrefetchPool()
        else
            local st = tonumber(err) or 0
            errorKind = (st == 429 and "http429") or (st == 503 and "http503") or (st == 0 and "network") or tostring(err or "http")
            lastErrorTime = os.time()
            render()
        end
    end)
end

local function fetchDailyVerse(key)
    local surah, ayah = verseForDate(key)
    fetchVerse(surah, ayah, false, key)
end

local function makeButton(glyph, tip, fn)
    return ui.button({
        glyph = glyph,
        glyphSize = 14,
        width = 30,
        height = 28,
        variant = "ghost",
        enabled = not loading,
        onClick = fn,
        tooltip = tip,
    })
end

render = function()
    local bodyContent
    if verse == nil then
        local msg = loading and "Loading verse…" or (errorKind and ("Unable to load: " .. (ERROR_TEXTS[errorKind] or "unknown error")) or "Daily Quran verse")
        bodyContent = ui.column({ flexGrow = 1, justify = "center", align = "center" }, {
            ui.label({ text = msg, fontSize = 15, color = "on_surface", maxWidth = 370 }),
        })
    else
        local cleanText = cleanTranslation(verse.text)
        bodyContent = ui.column({ onClick = "copyVerseAction", flexGrow = 1, width = 384, align = "stretch" }, {
            ui.scroll({ flexGrow = 1, align = "stretch" }, {
                ui.markdown({ text = "**“" .. cleanText .. "”**", width = 368 }),
            }),
        })
    end

    local surahTitle = "DAILY QURAN VERSE"
    local verseNumbers = nil
    if verse ~= nil then
        surahTitle = "SURAH " .. string.upper(verse.surah or "")
        verseNumbers = string.format("%d:%d", verse.surahNumber or 1, verse.number or 1)
    end

    -- Consolidated single-row footer: status/attribution on the left, essential actions on the right
    local leftFooter
    if notice ~= nil then
        leftFooter = ui.label({
            text = notice,
            fontSize = 11,
            fontWeight = "bold",
            color = "primary",
        })
    elseif loading then
        leftFooter = ui.label({
            text = "Refreshing…",
            fontSize = 11,
            color = "primary",
        })
    elseif errorKind ~= nil then
        leftFooter = ui.label({
            text = (ERROR_TEXTS[errorKind] or "Error") .. " · cached",
            fontSize = 11,
            color = "on_surface_variant",
        })
    elseif isRandomMode then
        leftFooter = ui.button({
            text = "Back to Today",
            variant = "ghost",
            controlSize = "xs",
            onClick = "showTodayVerseAction",
        })
    else
        leftFooter = ui.label({
            text = "English · Hilali-Khan",
            fontSize = 11,
            color = "on_surface_variant",
        })
    end

    desktopWidget.render(
        ui.column(
            {
                width = WIDTH,
                height = HEIGHT,
                gap = 6,
                padding = 14,
                fill = "surface_variant/0.82",
                radius = 20,
                justify = "start",
                align = "stretch",
            },
            {
                -- Header Row: Book Icon + SURAH <NAME> on left, citation on right
                ui.row(
                    { gap = 10, align = "center", justify = "space_between" },
                    {
                        ui.row({ gap = 10, align = "center", flexGrow = 1 }, {
                            ui.glyph({ name = "book", size = 22, color = "primary" }),
                            ui.label({
                                text = surahTitle,
                                fontSize = 18,
                                fontWeight = "bold",
                                color = "primary",
                            }),
                        }),
                        verseNumbers and ui.label({
                            text = verseNumbers,
                            fontSize = 15,
                            fontWeight = "bold",
                            color = "on_surface_variant",
                        }),
                    }
                ),

                ui.separator({ thickness = 1, color = "outline", spacing = 2 }),

                -- Verse Content (Expanded scroll container)
                bodyContent,

                ui.separator({ thickness = 1, color = "outline", spacing = 2 }),

                -- Consolidated Single Footer Row: No double rows, no redundant chain link
                ui.row(
                    { align = "center", justify = "space_between" },
                    {
                        leftFooter,
                        ui.row(
                            { gap = 4, align = "center" },
                            {
                                makeButton("copy", "Copy verse text", "copyVerseAction"),
                                makeButton("share", "Copy share citation", "copyShareAction"),
                                makeButton("refresh", "Random verse", "manualRefreshAction"),
                                ui.button({ text = "Open", variant = "secondary", controlSize = "sm", onClick = "openVerse", tooltip = "Open on Quran.com" }),
                            }
                        ),
                    }
                ),
            }
        )
    )
end

desktopWidget.setWantsSecondTicks(true)

function update()
    local now = os.time()

    if notice ~= nil then
        noctalia.setUpdateInterval(1000)
        if now >= (noticeUntil or 0) then
            clearNotice()
            render()
        end
        return
    else
        noctalia.setUpdateInterval(30000)
    end

    local manual = manualPending
    if not manual and (now - (lastPollClock or 0)) < 60 then
        return
    end
    lastPollClock = now

    local key = todayKey()

    if dataFile == nil then
        local dir = noctalia.pluginDataDir()
        if dir == nil then
            render()
            return
        end
        dataFile = dir .. "/verse.json"
        loadCachedVerse()
    end

    if loading then
        render()
        return
    end

    local cacheValid = (todayVerse ~= nil or (verse ~= nil and not isRandomMode)) and (cachedDay == key)

    if cacheValid and not manualPending and not isRandomMode then
        refillPrefetchPool()
        render()
        return
    end

    local minGap = manualPending and REFRESH_COOLDOWN or FETCH_DEBOUNCE
    local timingOk = (lastFetchClock == nil) or ((now - lastFetchClock) >= minGap)
    local backoffActive = (errorKind ~= nil and lastErrorTime ~= nil and (now - lastErrorTime) < ERROR_RETRY_AFTER)

    if manualPending then
        manualPending = false
        if timingOk then
            local randSurah, randAyah = pickRandomVerse(verse and verse.surahNumber, verse and verse.number)
            fetchVerse(randSurah, randAyah, true, nil)
        else
            setNotice("Please wait a moment")
            render()
        end
        return
    end

    if (not cacheValid) and timingOk and not backoffActive then
        isRandomMode = false
        fetchDailyVerse(key)
    else
        refillPrefetchPool()
        render()
    end
end

update()
