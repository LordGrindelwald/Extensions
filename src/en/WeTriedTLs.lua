-- {"id":89283,"ver":"0.0.5","libVer":"1.0.0","author":"Amelia Magdovitz","dep":["dkjson"]}
local Json = Require("dkjson")

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
    --It has them, but will be implemented later. Note that the website does not have a search page, and filters are only applied in cases where there is no search (to user facing. Have not investigated the pseudo-api)
}

--- Internal settings store.
---
--- Completely optional.
---  But required if you want to save results from [updateSetting].
---
--- Notice, each key is surrounded by "[]" and the value is on the right side.
--- @type table
local settings = {}

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



--- Crude means of grabbing and combining a query
--- @param tags string The query tags in the form of &tag1=xyz&tag2=zyx...
--- @return table The query JSON in the form of a table. Data section is included in case it will be needed
local function query(tags)
    local page = 0
    local times = 1
    local json = {}
    repeat
        page = page+1
        local queryDocument = GETDocument('https://api.wetriedtls.site/query?page='..page..tags) --..'&visibility=Public&series_type=Novel')
        if times > 1 then
            for _, v in ipairs(Json.decode(queryDocument:selectFirst('body'):text())['data']) do
                json['data'][#json['data']+1] = v
            end
        else
            json = Json.decode(queryDocument:selectFirst('body'):text())
        end
        times = math.ceil(json['meta']['total']/json['meta']['per_page'])
    until page >= times
    return json
end

local function getListings()

    local queryTable=query('&visibility=Public&series_type=Novel')
    local novels = {}
    for _, v in ipairs(queryTable['data']) do
        if v then
            novels[#novels]= Novel{
                title    = v['title'],
                link     = expandURL(v["series_slug"], KEY_NOVEL_URL),
                imageURL = v['thumbnail']
            }
        end
    end
end

local listings = {getListings()}

--- Get a chapter passage based on its chapterURL.
---
--- @param chapterURL string The chapters shrunken URL.
--- @return string Strings in lua are byte arrays. If you are not outputting strings/html you can return a binary stream.
local function getPassage(chapterURL)
    local url = expandURL(chapterURL, KEY_CHAPTER_URL)

    --- Chapter page, extract info from it.
    local document = GETDocument(url)
    return tostring(document:selectFirst("#reader-container"))
end

--- Get the novel information
---
--- TODO implement with query
--- @param novelURL string shrunken novel url.
--- @return NovelInfo
local function parseNovel(novelURL)
    local url = expandURL(novelURL, KEY_NOVEL_URL)

    --- Novel page, extract info from it.
    local document = GETDocument(url):selectFirst("body")

    return NovelInfo {
    title = document:selectFirst('h1'):text(),
    imageURL = baseURL..document:selectFirst('img.rounded'):attr("src"),
    description = document:selectFirst('div.rounded-xl'):text(),
    authors = { document:selectFirst("p:nth-of-type(3) > strong"):text() }}
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
}