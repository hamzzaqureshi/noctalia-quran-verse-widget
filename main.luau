--!nonstrict

-- Daily Quran Verse (English Hilali-Khan Translation)
-- Noctalia desktop widget created by Hamza Qureshi.
--
-- Features:
--   * Exclusively uses the authoritative English Hilali-Khan translation (Quran.com ID 203 & QuranEnc fallback).
--   * Complete 114 Surah English transliteration table (e.g. Al-Fatihah, Al-Baqarah).
--   * Deterministic date-to-verse sequence across all 6,236 Quran verses.
--   * Random verse exploration mode with instant "Back to Today" return action.
--   * Midnight turnover: automatically detects day changes and loads today's verse.
--   * Local persistent cache (verse.json) for instant cold startup and offline resilience.
--   * Scrollable text container preserving fixed 420x260 widget layout without layout shift.
--   * Action bar: Copy verse text, Copy formatted share citation, Copy Quran.com link, Random verse, Open in browser.
--   * Hover tooltips and dynamic update interval (30s idle / 1s active) for ultra-low resource usage.

local QURAN_COM_API = "https://api.quran.com/api/v4/verses/by_key"
local QURANENC_API = "https://quranenc.com/api/v1/translation/aya/english_hilali_khan"

local TOTAL_QURAN_VERSES = 6236
local FETCH_DEBOUNCE = 30        -- at least 30s between automatic requests
local REFRESH_COOLDOWN = 3       -- at least 3s between manual refreshes
local ERROR_RETRY_AFTER = 90     -- backoff 90s after failed request before auto-retry
local NOTICE_SECONDS = 2         -- duration for confirmation badges (seconds)

math.randomseed(os.time())

-- ══ 114 SURAH NAMES (ENGLISH TRANSLITERATIONS) ═════════════════════════════
local SURAH_NAMES = {
    [1] = "Al-Fatihah",
    [2] = "Al-Baqarah",
    [3] = "Ali 'Imran",
    [4] = "An-Nisa",
    [5] = "Al-Ma'idah",
    [6] = "Al-An'am",
    [7] = "Al-A'raf",
    [8] = "Al-Anfal",
    [9] = "At-Tawbah",
    [10] = "Yunus",
    [11] = "Hud",
    [12] = "Yusuf",
    [13] = "Ar-Ra'd",
    [14] = "Ibrahim",
    [15] = "Al-Hijr",
    [16] = "An-Nahl",
    [17] = "Al-Isra",
    [18] = "Al-Kahf",
    [19] = "Maryam",
    [20] = "Taha",
    [21] = "Al-Anbiya",
    [22] = "Al-Hajj",
    [23] = "Al-Mu'minun",
    [24] = "An-Nur",
    [25] = "Al-Furqan",
    [26] = "Ash-Shu'ara",
    [27] = "An-Naml",
    [28] = "Al-Qasas",
    [29] = "Al-'Ankabut",
    [30] = "Ar-Rum",
    [31] = "Luqman",
    [32] = "As-Sajdah",
    [33] = "Al-Ahzab",
    [34] = "Saba",
    [35] = "Fatir",
    [36] = "Ya-Sin",
    [37] = "As-Saffat",
    [38] = "Sad",
    [39] = "Az-Zumar",
    [40] = "Ghafir",
    [41] = "Fussilat",
    [42] = "Ash-Shura",
    [43] = "Az-Zukhruf",
    [44] = "Ad-Dukhan",
    [45] = "Al-Jathiyah",
    [46] = "Al-Ahqaf",
    [47] = "Muhammad",
    [48] = "Al-Fath",
    [49] = "Al-Hujurat",
    [50] = "Qaf",
    [51] = "Adh-Dhariyat",
    [52] = "At-Tur",
    [53] = "An-Najm",
    [54] = "Al-Qamar",
    [55] = "Ar-Rahman",
    [56] = "Al-Waqi'ah",
    [57] = "Al-Hadid",
    [58] = "Al-Mujadila",
    [59] = "Al-Hashr",
    [60] = "Al-Mumtahanah",
    [61] = "As-Saff",
    [62] = "Al-Jumu'ah",
    [63] = "Al-Munafiqun",
    [64] = "At-Taghabun",
    [65] = "At-Talaq",
    [66] = "At-Tahrim",
    [67] = "Al-Mulk",
    [68] = "Al-Qalam",
    [69] = "Al-Haqqah",
    [70] = "Al-Ma'arij",
    [71] = "Nuh",
    [72] = "Al-Jinn",
    [73] = "Al-Muzzammil",
    [74] = "Al-Muddaththir",
    [75] = "Al-Qiyamah",
    [76] = "Al-Insan",
    [77] = "Al-Mursalat",
    [78] = "An-Naba",
    [79] = "An-Nazi'at",
    [80] = "'Abasa",
    [81] = "At-Takwir",
    [82] = "Al-Infitar",
    [83] = "Al-Mutaffifin",
    [84] = "Al-Inshiqaq",
    [85] = "Al-Buruj",
    [86] = "At-Tariq",
    [87] = "Al-A'la",
    [88] = "Al-Ghashiyah",
    [89] = "Al-Fajr",
    [90] = "Al-Balad",
    [91] = "Ash-Shams",
    [92] = "Al-Layl",
    [93] = "Ad-Duha",
    [94] = "Ash-Sharh",
    [95] = "At-Tin",
    [96] = "Al-'Alaq",
    [97] = "Al-Qadr",
    [98] = "Al-Bayyinah",
    [99] = "Az-Zalzalah",
    [100] = "Al-'Adiyat",
    [101] = "Al-Qari'ah",
    [102] = "At-Takathur",
    [103] = "Al-'Asr",
    [104] = "Al-Humazah",
    [105] = "Al-Fil",
    [106] = "Quraysh",
    [107] = "Al-Ma'un",
    [108] = "Al-Kawthar",
    [109] = "Al-Kafirun",
    [110] = "An-Nasr",
    [111] = "Al-Masad",
    [112] = "Al-Ikhlas",
    [113] = "Al-Falaq",
    [114] = "An-Nas",
}

-- ══ 114 SURAH VERSE COUNTS (SUM = 6,236) ══════════════════════════════════
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

-- ══ STATE ═════════════════════════════════════════════════════════════════
local verse = nil                -- { surah, surahNumber, number, text, arabic, author, url }
local todayVerse = nil           -- in-memory copy of today's verse
local isRandomMode = false       -- true when currently displaying a random verse
local loading = false
local cachedDay = nil            -- day key from verse.json (e.g. "2026-256")
local savedAtClock = nil         -- os.time() when cache was written
local lastFetchClock = nil       -- os.time() of last successful or initiated fetch
local lastPollClock = nil        -- os.time() of last poll
local lastErrorTime = nil        -- os.time() of last error for backoff
local errorKind = nil            -- "network"|"http429"|"http503"|"http"|"json"|"invalid"|"start"
local notice = nil               -- temporary status banner (e.g. "Verse copied")
local noticeUntil = nil          -- os.time() when notice expires
local manualPending = false      -- true when manual refresh was triggered
local dataFile = nil

local render                     -- forward declaration

-- ══ DATE & VERSE MAPPING ══════════════════════════════════════════════════
local function todayKey()
    return os.date("%Y-%j")
end

local function verseForDate(key)
    local yearStr, ydayStr = tostring(key):match("^(%d+)%-(%d+)$")
    local year = tonumber(yearStr) or 2026
    local yday = tonumber(ydayStr) or 1

    local leaps = math.floor((year - 1) / 4) - math.floor((year - 1) / 100) + math.floor((year - 1) / 400)
    local dayNum = (year - 1) * 365 + leaps + yday

    local verseIndex = ((dayNum - 1) % TOTAL_QURAN_VERSES) + 1
    local remaining = verseIndex

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
    if text == nil then
        return ""
    end
    local cleaned = tostring(text)
    -- Remove footnote tags like <sup foot_note=123>1</sup>
    cleaned = cleaned:gsub("<sup[^>]*>.-</sup>", "")
    -- Remove any remaining HTML tags
    cleaned = cleaned:gsub("<[^>]+>", "")
    -- Remove redundant leading ayah number prefix (e.g. "54. (It will be said...)")
    cleaned = cleaned:gsub("^%d+%.%s*", "")
    -- Normalize whitespace
    cleaned = cleaned:gsub("%s+", " ")
    return cleaned:gsub("^%s+", ""):gsub("%s+$", "")
end

-- ══ VERSE CACHE ═══════════════════════════════════════════════════════════
local function saveVerse(key)
    if dataFile == nil or verse == nil then
        return
    end

    local encoded = noctalia.json.encode({
        day = key,
        savedAt = savedAtClock,
        verse = verse,
    })

    if encoded ~= nil then
        noctalia.writeFile(dataFile, encoded)
    end
end

local function loadCachedVerse()
    if dataFile == nil then
        return
    end

    local raw = noctalia.readFile(dataFile)
    if raw == nil then
        return
    end

    local decoded = noctalia.json.decode(raw)
    if decoded == nil or decoded.verse == nil then
        return
    end

    verse = decoded.verse
    cachedDay = decoded.day
    savedAtClock = tonumber(decoded.savedAt)
    if cachedDay == todayKey() then
        todayVerse = decoded.verse
        isRandomMode = false
    end
end

-- ══ NOTICES & FEEDBACK ════════════════════════════════════════════════════
local function setNotice(text)
    notice = tostring(text)
    noticeUntil = os.time() + NOTICE_SECONDS
end

local function clearNotice()
    notice = nil
    noticeUntil = nil
end

-- ══ USER ACTIONS (invoked via onClick handlers) ══════════════════════════
function copyVerseAction()
    if verse == nil or verse.text == nil or tostring(verse.text) == "" then
        return
    end
    if noctalia.copyToClipboard(tostring(verse.text), "text/plain") then
        setNotice("Verse copied")
        render()
    end
end

function copyShareAction()
    if verse == nil then
        return
    end

    local refStr = tostring(verse.surah or "") .. " "
        .. tostring(verse.surahNumber or "") .. ":" .. tostring(verse.number or "")
        .. " · " .. tostring(verse.author or "Hilali-Khan")

    local shareText = "“" .. tostring(verse.text or "") .. "”\n" .. refStr
    if verse.url ~= nil and tostring(verse.url) ~= "" then
        shareText = shareText .. "\n" .. tostring(verse.url)
    end

    if noctalia.copyToClipboard(shareText, "text/plain") then
        setNotice("Share text copied")
        render()
    end
end

function copyUrlAction()
    if verse == nil or verse.url == nil or tostring(verse.url) == "" then
        return
    end
    if noctalia.copyToClipboard(tostring(verse.url), "text/plain") then
        setNotice("Link copied")
        render()
    end
end

function manualRefreshAction()
    clearNotice()
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
        local key = todayKey()
        fetchDailyVerse(key)
    end
end

function openVerse()
    if verse == nil or verse.url == nil or tostring(verse.url) == "" then
        return
    end
    noctalia.runAsync({ "xdg-open", tostring(verse.url) }, nil)
end

-- ══ ERROR MESSAGES ════════════════════════════════════════════════════════
local function errorText(kind)
    if kind == "network" then
        return "Network error"
    elseif kind == "http429" then
        return "Rate limited — please wait"
    elseif kind == "http503" then
        return "Server busy"
    elseif kind == "http" then
        return "API error"
    elseif kind == "json" then
        return "Malformed response"
    elseif kind == "invalid" then
        return "Invalid response"
    elseif kind == "start" then
        return "Failed to start request"
    end
    return nil
end

-- ══ VERSE FETCH (Hilali-Khan Translation) ═══════════════════════════════════
local function pickRandomVerse(curSurah, curAyah)
    local surah = math.random(1, 114)
    local maxAyah = SURAH_VERSE_COUNTS[surah] or 1
    local ayah = math.random(1, maxAyah)
    if curSurah ~= nil and curAyah ~= nil and surah == curSurah and ayah == curAyah and maxAyah > 1 then
        ayah = (ayah % maxAyah) + 1
    end
    return surah, ayah
end

local function applyVerseSuccess(surah, ayah, surahName, transText, arabicText, url, isRandom, key)
    local cleanText = cleanTranslation(transText)
    local v = {
        surah = surahName,
        surahNumber = surah,
        number = ayah,
        text = cleanText,
        arabic = tostring(arabicText or ""),
        author = "Hilali-Khan",
        url = url,
    }

    verse = v
    errorKind = nil
    lastErrorTime = nil
    lastFetchClock = os.time()

    if isRandom then
        isRandomMode = true
        setNotice("Random verse")
    else
        isRandomMode = false
        todayVerse = v
        cachedDay = key
        savedAtClock = os.time()
        saveVerse(key)
    end

    render()
end

local function fetchVerse(surah, ayah, isRandom, key)
    if loading then
        return
    end

    local surahName = SURAH_NAMES[surah] or ("Surah " .. tostring(surah))

    loading = true
    render()

    local quranComUrl = QURAN_COM_API .. "/" .. tostring(surah) .. ":" .. tostring(ayah) .. "?translations=203&fields=text_uthmani"

    local function tryQuranEncFallback()
        local encUrl = QURANENC_API .. "/" .. tostring(surah) .. "/" .. tostring(ayah)
        local encAccepted = noctalia.http(
            {
                url = encUrl,
                method = "GET",
                headers = {
                    "Accept: application/json",
                    "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
                },
            },
            function(response)
                loading = false
                if not response.ok or response.status < 200 or response.status >= 300 then
                    local st = tonumber(response.status) or 0
                    if st == 429 then
                        errorKind = "http429"
                    elseif st == 503 then
                        errorKind = "http503"
                    elseif st == 0 then
                        errorKind = "network"
                    else
                        errorKind = "http"
                    end
                    lastErrorTime = os.time()
                    noctalia.log("Quran verse API error: " .. tostring(response.status))
                    render()
                    return
                end

                local decoded = noctalia.json.decode(response.body)
                if decoded == nil or decoded.result == nil or decoded.result.translation == nil then
                    errorKind = "invalid"
                    lastErrorTime = os.time()
                    noctalia.log("Verse response invalid")
                    render()
                    return
                end

                local browseUrl = "https://quran.com/" .. tostring(surah) .. ":" .. tostring(ayah)
                applyVerseSuccess(
                    surah,
                    ayah,
                    surahName,
                    decoded.result.translation,
                    decoded.result.arabic_text or "",
                    browseUrl,
                    isRandom,
                    key
                )
            end
        )

        if not encAccepted then
            loading = false
            errorKind = "start"
            lastErrorTime = os.time()
            noctalia.log("Fallback request could not be started.")
            render()
        end
    end

    local accepted = noctalia.http(
        {
            url = quranComUrl,
            method = "GET",
            headers = {
                "Accept: application/json",
                "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            },
        },
        function(response)
            if response.ok and response.status >= 200 and response.status < 300 then
                local decoded = noctalia.json.decode(response.body)
                if decoded ~= nil and decoded.verse ~= nil and decoded.verse.translations ~= nil and #decoded.verse.translations > 0 then
                    local transText = decoded.verse.translations[1].text or ""
                    for _, t in ipairs(decoded.verse.translations) do
                        if t.resource_id == 203 and t.text ~= nil then
                            transText = t.text
                            break
                        end
                    end

                    loading = false
                    local browseUrl = "https://quran.com/" .. tostring(surah) .. ":" .. tostring(ayah)
                    applyVerseSuccess(
                        surah,
                        ayah,
                        surahName,
                        transText,
                        decoded.verse.text_uthmani or "",
                        browseUrl,
                        isRandom,
                        key
                    )
                    return
                end
            end

            noctalia.log("Primary verse API failed, trying QuranEnc fallback...")
            tryQuranEncFallback()
        end
    )

    if not accepted then
        tryQuranEncFallback()
    end
end

local function fetchDailyVerse(key)
    local surah, ayah = verseForDate(key)
    fetchVerse(surah, ayah, false, key)
end

-- ══ RENDER ════════════════════════════════════════════════════════════════
render = function()
    local WIDTH = 420
    local HEIGHT = 260

    if verse == nil then
        local statusMessage = "Daily Quran verse"
        if loading then
            statusMessage = "Loading verse…"
        elseif errorKind ~= nil then
            statusMessage = "Unable to load: " .. (errorText(errorKind) or "unknown error")
        end

        desktopWidget.render(
            ui.column(
                {
                    width = WIDTH,
                    height = HEIGHT,
                    gap = 14,
                    padding = 22,
                    fill = "surface_variant/0.82",
                    radius = 20,
                    justify = "center",
                    align = "stretch",
                },
                {
                    ui.row(
                        { gap = 10, align = "center" },
                        {
                            ui.glyph({
                                name = "book",
                                size = 22,
                                color = "primary",
                            }),
                            ui.label({
                                text = "QURAN VERSE",
                                fontSize = 18,
                                fontWeight = "bold",
                                color = "primary",
                            }),
                        }
                    ),
                    ui.label({
                        text = statusMessage,
                        fontSize = 15,
                        color = "on_surface",
                        maxWidth = 370,
                    }),
                }
            )
        )
        return
    end

    -- ── Header: Book Icon + Title + Reference ─────────────────────────────
    local headerRow = ui.row(
        {
            gap = 8,
            align = "center",
            justify = "space_between",
        },
        {
            ui.row(
                { gap = 10, align = "center", flexGrow = 1 },
                {
                    ui.glyph({
                        name = "book",
                        size = 22,
                        color = "primary",
                    }),
                    ui.label({
                        text = "QURAN VERSE",
                        fontSize = 18,
                        fontWeight = "bold",
                        color = "primary",
                    }),
                }
            ),
            ui.label({
                text = verse.surah .. " " .. tostring(verse.surahNumber) .. ":" .. tostring(verse.number),
                fontSize = 13,
                fontWeight = "bold",
                color = "on_surface_variant",
            }),
        }
    )

    -- ── Status Row: Language · Status / Feedback Notice ───────────────────
    if notice ~= nil and os.time() >= (noticeUntil or 0) then
        notice = nil
        noticeUntil = nil
    end

    local editionLabel = isRandomMode and "English · Hilali-Khan · Random" or "English · Hilali-Khan"

    local statusChildren = {
        ui.label({
            text = editionLabel,
            fontSize = 11,
            color = "on_surface_variant",
        }),
    }

    local rightStatus = nil
    local rightStatusColor = "on_surface_variant"

    if notice ~= nil then
        rightStatus = notice
        rightStatusColor = "primary"
    elseif loading then
        rightStatus = "Refreshing…"
    elseif errorKind ~= nil then
        rightStatus = (errorText(errorKind) or "") .. " · cached"
    end

    if rightStatus ~= nil then
        table.insert(statusChildren, ui.label({
            text = rightStatus,
            fontSize = 11,
            color = rightStatusColor,
            flexGrow = 1,
            textAlign = "end",
        }))
    elseif isRandomMode then
        table.insert(statusChildren, ui.button({
            text = "Back to Today",
            variant = "ghost",
            controlSize = "xs",
            onClick = "showTodayVerseAction",
        }))
    end

    -- ── Action Buttons Row ─────────────────────────────────────────────────
    local actionButtons = {
        ui.button({
            glyph = "copy",
            glyphSize = 14,
            width = 30,
            height = 28,
            variant = "ghost",
            enabled = not loading,
            onClick = "copyVerseAction",
            tooltip = "Copy verse text",
        }),
        ui.button({
            glyph = "share",
            glyphSize = 14,
            width = 30,
            height = 28,
            variant = "ghost",
            enabled = not loading,
            onClick = "copyShareAction",
            tooltip = "Copy share text with reference",
        }),
        ui.button({
            glyph = "link",
            glyphSize = 14,
            width = 30,
            height = 28,
            variant = "ghost",
            enabled = not loading,
            onClick = "copyUrlAction",
            tooltip = "Copy Quran.com link",
        }),
        ui.button({
            glyph = "refresh",
            glyphSize = 14,
            width = 30,
            height = 28,
            variant = "ghost",
            enabled = not loading,
            onClick = "manualRefreshAction",
            tooltip = "Random verse",
        }),
        ui.button({
            text = "Open",
            variant = "secondary",
            controlSize = "sm",
            onClick = "openVerse",
            tooltip = "Open on Quran.com",
        }),
    }

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
                headerRow,

                ui.separator({
                    thickness = 1,
                    color = "outline",
                    spacing = 2,
                }),

                -- ── Verse Content (scrollable container) ──────────────────
                ui.column(
                    {
                        onClick = "copyVerseAction",
                        flexGrow = 1,
                        width = 384,
                        align = "stretch",
                        key = "verse-area",
                    },
                    {
                        ui.scroll(
                            { flexGrow = 1, align = "stretch" },
                            {
                                ui.markdown({
                                    text = "**“" .. verse.text .. "”**",
                                    width = 368,
                                }),
                            }
                        ),
                    }
                ),

                ui.row(
                    {
                        gap = 6,
                        align = "center",
                        justify = "space_between",
                    },
                    statusChildren
                ),

                ui.separator({
                    thickness = 1,
                    color = "outline",
                    spacing = 2,
                }),

                ui.row(
                    {
                        align = "center",
                        justify = "space_between",
                    },
                    {
                        ui.label({
                            text = isRandomMode and "Random Verse" or "Daily Verse",
                            fontSize = 12,
                            color = "on_surface_variant",
                        }),
                        ui.row(
                            { gap = 4, align = "center" },
                            actionButtons
                        ),
                    }
                ),
            }
        )
    )
end

-- ══ UPDATE CYCLE ══════════════════════════════════════════════════════════
desktopWidget.setWantsSecondTicks(true)

function update()
    local now = os.time()

    -- Dynamic interval: 1s when a notice is active (for smooth expiry), 30s otherwise
    if notice ~= nil then
        noctalia.setUpdateInterval(1000)
    else
        noctalia.setUpdateInterval(30000)
    end

    -- 1) Clear transient feedback notice when expired
    if notice ~= nil then
        if now >= (noticeUntil or 0) then
            clearNotice()
            render()
        end
        return
    end

    -- 2) Network poll gate: at most once every 60s unless manual refresh
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

    -- Fast path: cache is fresh for today and no manual refresh requested
    if cacheValid and not manualPending and not isRandomMode then
        render()
        return
    end

    local minGap = manualPending and REFRESH_COOLDOWN or FETCH_DEBOUNCE
    local timingOk = (lastFetchClock == nil) or ((now - lastFetchClock) >= minGap)
    local backoffActive = (errorKind ~= nil and lastErrorTime ~= nil and (now - lastErrorTime) < ERROR_RETRY_AFTER)

    if manualPending then
        manualPending = false
        if timingOk then
            local curS = verse and verse.surahNumber
            local curA = verse and verse.number
            local randSurah, randAyah = pickRandomVerse(curS, curA)
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
        render()
    end
end

update()
