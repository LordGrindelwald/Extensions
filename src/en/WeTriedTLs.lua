-- {"id":89283,"ver":"1.0.0","libVer":"1.0.0","author":"Amelia Magdovitz","dep":["dkjson"]}
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

local baseAPIURL = "https://api.wetriedtls.site"

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
local hasSearch = false

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
    TextFilter(14, "Keyword (title)"), --&query_string=
    FilterGroup("Genres (AND)", { --Yes the ids are like this in the api. WHY &tags_ids=[{tag},{tag}...]
        CheckboxFilter(101, "Action Fantasy"),
        CheckboxFilter(103, "Romance"),
        CheckboxFilter(104, "Drama"),
        CheckboxFilter(105, "Thriller"),
        CheckboxFilter(106, "Horror"),
        CheckboxFilter(107, "Comedy"),
        CheckboxFilter(108, "Science Fiction"),
        CheckboxFilter(109, "Slice of Life"),
        CheckboxFilter(110, "Mystery"),
        CheckboxFilter(111, "Martial Arts"),
    }),
    DropdownFilter(12, "Order by", { --&orderBy=
        "Trending", --total_views   (0)
        "Updated at", --latest      (1)
        "Created at", --created_at  (2)
        "Title" --title             (3)
    } ),
    CheckboxFilter(13, "Ascending"), --&order=asec
}


--- Internal settings store.
---
--- Completely optional.
---  But required if you want to save results from [updateSetting].
---
--- Notice, each key is surrounded by "[]" and the value is on the right side.
--- @type table
local settings = {
    [1] = false,
}

--- Settings model for Shosetsu to render.
---
--- Optional, Default is empty.
---
--- @type Filter[] | Array
local settingsModel = {
    CheckboxFilter(1, "List chapters that cost money")
}

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
    if string.sub(url, 0,4)~="http" then
        return url
    end
    url = url:gsub(baseURL.."/series/", "")
    if type == KEY_CHAPTER_URL then
        return url:gsub("chapter%-", "")

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
    if string.sub(url, 0,4)=="http" then
        return url
    end
    if type == KEY_CHAPTER_URL then

        -- One slash is left, so we will use it as the
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
        local queryDocument = Json.GET('https://api.wetriedtls.site/query?perPage=999&visibility=Public&series_type=Novel&page='..page..tags)
        if times > 1 then
            for _, v in ipairs(queryDocument['data']) do
                json['data'][#json['data']+1] = v
            end
        else
            json = queryDocument
        end
        times = math.ceil(json['meta']['total']/json['meta']['per_page'])
    until page >= times
    return json
end


local function makeFilterString(data)
    local fS = ""
    --keyword
    fS = fS.."&query_string="..data[14]
    if data[13] then --Ascending checkbox
        fS=fS.."&order=asec"
    end
    if data[12] then
        fS=fS.."&orderBy="
        if data[12] == 1 then
            fS=fS.."latest"
        elseif data[12] == 2 then
            fS=fS.."created_at"
        elseif data[12] == 3 then
            fS=fS.."title"
        else
            fS=fS.."total_views"
        end
    end
    local tags = {}
    local filterList = {101,103,104,105,106,107,108,109,110,111}
    for _, v in ipairs(filterList) do
        if data[v] then
            tags[#tags+1]=v-100
        end
    end
    print(Json.encode(tags))
    fS=fS.."&tags_ids="..Json.encode(tags)
    return fS
end

local function getListings()
    return Listing("all", false, function(data)
        local queryTable = query(makeFilterString(data))
        return map(queryTable['data'],function(v)
            return Novel{
                title    = v['title'],
                link     = v["series_slug"],
                imageURL = v['thumbnail']
            }
        end)
    end)
end

local listings = {getListings()}

---@param novelJSON table
---@return table
local function combineChapters(novelJSON)
    local chapterList = {}
    for _, v in ipairs(novelJSON['seasons']) do
        for _, u in ipairs(v['chapters'])do
            if u['price'] == 0 or settings[1] then
                chapterList[#chapterList+1]=u
            end
        end
    end
    return chapterList
end


--- Get a chapter passage based on its chapterURL.
---
--- @param chapterURL string The chapters shrunken URL.
--- @return string Strings in lua are byte arrays. If you are not outputting strings/html you can return a binary stream.
local function getPassage(chapterURL)
    local url = expandURL(chapterURL, KEY_CHAPTER_URL)
    --- Chapter page, extract info from it.
    local document = GETDocument(url)
    if document:selectFirst("h5.font-bold") then
        if document:selectFirst("h5.font-bold"):text() == 'This chapter is premium!'then
            return "<h1>This chapter is a paid chapter. You might be able to log in via the webview and purchase the chapter to display it here.</h1>"
        end
    end
    return tostring(document:selectFirst("#reader-container"))
end

--- Get the novel information
---
--- TODO implement with query
--- @param novelURL string shrunken novel url.
--- @param loadChapters boolean if to grab chapters
--- @return NovelInfo
local function parseNovel(novelURL, loadChapters)
    local url = baseAPIURL..'/series/'..novelURL
    local document = Json.GET(url)
    print(Json.encode(document))

    local novelInfo = NovelInfo {
    title = document['title'],
    imageURL = baseURL..GETDocument(expandURL(novelURL)):selectFirst('body'):selectFirst('img.rounded'):attr("src")
    }
    if document['author'] then
        novelInfo:setAuthors({ document['author'] })
    end
    if document['tags'] then
        novelInfo:setTags(map(document['tags'],function(v) return v["name"] end))
    end
    if document['description'] then
        novelInfo:setDescription(document['description']:gsub("<%p%w+>",""):gsub("<p>", ""))
    end
    if loadChapters then
        novelInfo:setChapters(AsList(map(combineChapters(document), function(v)
            local novelChapter= NovelChapter {
                link = shrinkURL(baseURL..'/series/'..novelURL.."/"..v['chapter_slug'], KEY_CHAPTER_URL),
                order = tonumber(v['index'])
            }
            if v['created_at'] then
                novelChapter:setRelease(v['created_at'])
            end
            if v["price"] == 0 then
                novelChapter:setTitle(v['chapter_title'])
            else
                novelChapter:setTitle("(Locked)"..v['chapter_title'])
            end
            return novelChapter
        end)))
    end

    return novelInfo
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
    updateSetting = updateSetting
}