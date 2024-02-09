-- {"id":89283,"ver":"0.0.1","libVer":"1.0.0","author":"Amelia Magdovitz"}


--- @type int
local id = 89283

--- Name of extension to display to the user.
--- Should match index.
---
--- Required.
---
--- @type string
local name = "We Tried Translations"

--- Base URL of the extension. Used to open web view in Shosetsu.
---
--- Required.
---
--- @type string
local baseURL = "https://wetriedtls.site"

--- URL of the logo.
---
--- Optional, Default is empty.
---
--- @type string
local imageURL = baseURL.."/favicon.ico"

--- Shosetsu tries to handle cloudflare protection if this is set to true.
---
--- Optional, Default is false.
---
--- @type boolean
local hasCloudFlare = false

--- If the website has search.
---
--- Optional, Default is true.
---
--- @type boolean
local hasSearch = false --it has them, but too few novels to matter, will implement later

--- If the websites search increments or not.
---
--- Optional, Default is true.
---
--- @type boolean
local isSearchIncrementing = false

--- Filters to display via the filter fab in Shosetsu.
---
--- Optional, Default is none.
---
--- @type Filter[] | Array
local searchFilters = {
    --It has them, but will be implemented later
}

--- Internal settings store.
---
--- Completely optional.
---  But required if you want to save results from [updateSetting].
---
--- Notice, each key is surrounded by "[]" and the value is on the right side.
--- @type table
local settings = {


}

--- Settings model for Shosetsu to render.
---
--- Optional, Default is empty.
---
--- @type Filter[] | Array
local settingsModel = {}

--- ChapterType provided by the extension.
---
--- Optional, Default is STRING. But please do HTML.
---
--- @type ChapterType
local chapterType = ChapterType.HTML

--- Index that pages start with. For example, the first page of search is index 1.
---
--- Optional, Default is 1.
---
--- @type number
local startIndex = 1

--- Listings that users can navigate in Shosetsu.
---
--- Required, 1 value at minimum.
---
--- @type Listing[] | Array
local listings = {
    Listing(name, false, function(data)
        -- Many sites use the baseURL + some path, you can perform the URL construction here.
        -- You can also extract query data from [data]. But do perform a null check, for safety.
        local url = baseURL

        local document = GETDocument(url)

        return {}
    end),
    Listing("Something (with incrementing pages!)", true, function(data)
        --- @type int
        local page = data[PAGE]
        -- Previous documentation, + appending page
        local url = baseURL .. "?p=" .. page

        local document = GETDocument(url)

        return {}
    end),
    Listing("Something without any input", false, function()
        -- Previous documentation, except no data or appending.
        local url = baseURL

        local document = GETDocument(url)

        return {}
    end)
}

--- Shrink the website url down. This is for space saving purposes.
---
--- Required.
---
--- @param url string Full URL to shrink.
--- @param type int Either KEY_CHAPTER_URL or KEY_NOVEL_URL.
--- @return string Shrunk URL.
local function shrinkURL(url, type)
    -- Novel looks like       baseURL/series/{name}
    -- Chapter looks like     baseURL/series/{name}/chapter-{num}
    url = url:gsub(baseURL.."/series/", "")
    if type == KEY_CHAPTER_URL then
        return url:gsub("chapter-", "")
        -- Note that there is only one slash left, right before the number
    else
        return url
    end
end

--- Expand a given URL.
---
--- Required.
---
--- @param url string Shrunk URL to expand.
--- @param type int Either KEY_CHAPTER_URL or KEY_NOVEL_URL.
--- @return string Full URL.
local function expandURL(url, type)
    if type == KEY_CHAPTER_URL then
        -- One slash is left, so we will use it as the target
        url = url:gsub("/","/chapter-")
    end

    return baseURL.."/series/"..url
end
    --- Get a chapter passage based on its chapterURL.
    ---
    --- Required.
    ---
    --- @param chapterURL string The chapters shrunken URL.
    --- @return string Strings in lua are byte arrays. If you are not outputting strings/html you can return a binary stream.
    local function getPassage(chapterURL)
        local url = expandURL(chapterURL, KEY_CHAPTER_URL)

        --- Chapter page, extract info from it.
        local document = GETDocument(url)

        return ""
    end

    --- Load info on a novel.
    ---
    --- Required.
    ---
    --- @param novelURL string shrunken novel url.
    --- @return NovelInfo
    local function parseNovel(novelURL)
        local url = shrinkURL(novelURL, KEY_NOVEL_URL)

        --- Novel page, extract info from it.
        local document = GETDocument(url)

        return NovelInfo()
    end

    --- Called to search for novels off a website.
    ---
    --- Optional, But required if [hasSearch] is true.
    ---
    --- @param data table @of applied filter values [QUERY] is the search query, may be empty.
    --- @return Novel[] | Array
    local function search(data)
        --- Not required if search is not incrementing.
        --- @type int
        local page = data[PAGE]

        --- Get the user text query to pass through.
        --- @type string
        local query = data[QUERY]

        return {}
    end

    --- Called when a user changes a setting and when the extension is being initialized.
    ---
    --- Optional, But required if [settingsModel] is not empty.
    ---
    --- @param id int Setting key as stated in [settingsModel].
    --- @param value any Value pertaining to the type of setting. Int/Boolean/String.
    --- @return void
    local function updateSetting(id, value)
        settings[id] = value
    end

-- Return all properties in a lua table.
return {
    -- Required
    id = id,
    name = name,
    baseURL = baseURL,
    listings = listings, -- Must have at least one listing
    getPassage = getPassage,
    parseNovel = parseNovel,
    shrinkURL = shrinkURL,
    expandURL = expandURL,

    -- Optional values to change
    imageURL = imageURL,
    hasCloudFlare = hasCloudFlare,
    hasSearch = hasSearch,
    isSearchIncrementing = isSearchIncrementing,
    searchFilters = searchFilters,
    settings = settingsModel,
    chapterType = chapterType,
    startIndex = startIndex,

    -- Required if [hasSearch] is true.
    search = search,

    -- Required if [settings] is not empty
    updateSetting = updateSetting,
}