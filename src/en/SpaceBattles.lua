-- {"id":94593,"ver":"0.1.0","libVer":"1.0.0","author":"Amelia Magdovitz"}

-- may be possible to convert to a general xenforoforum library

--- Identification number of the extension.
--- Should be unique. Should be consistent in all references.
---
--- Required.
---
--- @type int
local id = 94593

--- Name of extension to display to the user.
--- Should match index.
---
--- Required.
---
--- @type string
local name = "Space Battles Creative Writing"

--- Base URL of the extension. Used to open web view in Shosetsu.
---
--- Required.
---
--- @type string
local baseURL = "https://forums.spacebattles.com/"

--- Base URL of the extension plus /forums.
---
--- @type string
local baseURLForums = baseURL .. "forums/"

--- URL of the logo.
---
--- Optional, Default is empty.
---
--- @type string
local imageURL = "https://forums.spacebattles.com/data/svg/2/1/1709013933/2022_favicon_192x192.png"

--- Shosetsu tries to handle cloudflare protection if this is set to true.
---
--- Optional, Default is false.
---
--- @type boolean
local hasCloudFlare = true

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
--[[local searchFilters = {
    TextFilter(5, "RANDOM STRING INPUT"),
    SwitchFilter(6, "RANDOM SWITCH INPUT"),
    CheckboxFilter(7, "RANDOM CHECKBOX INPUT"),
    TriStateFilter(8, "RANDOM TRISTATE CHECKBOX INPUT"),
    RadioGroupFilter(9, "RANDOM RGROUP INPUT", { "A", "B", "C" }),
    DropdownFilter(10, "RANDOM DDOWN INPUT", { "A", "B", "C" })
}]]
--we'll see


--- Internal settings store.
---
--- Completely optional.
---  But required if you want to save results from [updateSetting].
---
--- Notice, each key is surrounded by "[]" and the value is on the right side.
--- @type table
--[[local settings = {
    [1] = "test",
    [2] = false,
    [3] = false,
    [4] = 2,
    [5] = "A",
    [6] = "B"
}]]
--We'll see

--- Settings model for Shosetsu to render.
---
--- Optional, Default is empty.
---
--- @type Filter[] | Array
--[[
local settingsModel = {
    TextFilter(1, "RANDOM STRING INPUT"),
    SwitchFilter(2, "RANDOM SWITCH INPUT"),
    CheckboxFilter(3, "RANDOM CHECKBOX INPUT"),
    TriStateFilter(4, "RANDOM TRISTATE CHECKBOX INPUT"),
    RadioGroupFilter(5, "RANDOM RGROUP INPUT", { "A", "B", "C" }),
    DropdownFilter(6, "RANDOM DDOWN INPUT", { "A", "B", "C" })
}
]]
--We'll see

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

--- @return Listing[] | Array
local function getListings()
    local listingList = {
        {"Main - Creative Writing", "creative-writing.18"},
        {"Original Fiction" , "original-fiction.48"},
        {"Creative Writing Archives", "creative-writing-archives.40"},
        {"Worm", "worm.115"}
    }
    return map(listingList, function(v)
        return Listing(v[1], true, function(data)

            --- @type int
            local page = data[PAGE]
            -- Previous documentation, + appending page
            local url = baseURLForums .. v[2] .. "/page-" .. page

            local document = GETDocument(url)
            local novelsOnPage = document:select(".js-threadList")
            novelsOnPage = novelsOnPage:select("[class *= node--id]")

            return mapNotNil(novelsOnPage, function (vv)

                local title = vv:selectFirst(".structItem-title [href]")
                local image = imageURL                                            -- No title images on the page
                return Novel {
                    title    = title:text(),
                    link     = title:attr("href"),
                    imageURL = image
                }
            end)
        end)
    end)
end

--- Listings that users can navigate in Shosetsu.
---
--- Required, 1 value at minimum.
---
--- @type Listing[] | Array
local listings = getListings()


--- Shrink the website url down. This is for space saving purposes.
---
--- Required.
---
--- @param url string Full URL to shrink.
--- @return string Shrunk URL.
local function shrinkURL(url)
        return url:gsub(baseURL, "")
end

--- Expand a given URL.
---
--- Required.
---
--- @param url string Shrunk URL to expand.
--- @return string Full URL.
local function expandURL(url)
        return (baseURL .. url)
end

--- Get a chapter passage based on its chapterURL.
---
--- Required.
---
--- @param chapterURL string The chapters shrunken URL.
--- @return string Strings in lua are byte arrays. If you are not outputting strings/html you can return a binary stream.
local function getPassage(chapterURL)
    local url = expandURL(chapterURL)
    --- Chapter page, extract info from it.
    local document = GETDocument(url)
    return tostring(document:selectFirst(".bbWrapper"))
end

--- Load info on a novel.
---
--- Required.
---
--- @param novelURL string shrunken novel url.
--- @return NovelInfo
local function parseNovel(novelURL, loadChapters)
    local url = expandURL(novelURL)
    --- Novel page, extract info from it.
    --- Can not get ongoing status, as all forums say Ongoing, even those that are 19 years old
    local document = GETDocument(url)
    local header  = document:selectFirst(".threadmarkListingHeader")
    local header2 = document:selectFirst(".p-body-header")
    local novelInfo =  NovelInfo {
        title = document:selectFirst(".p-title-value"):text(),
        authors = {header2:selectFirst(".u-concealed.username"):text()}
    }

    local imagePage = imageURL
    if pcall(function() header:selectFirst("img") end) then
        pcall(function() imageURL = expandURL(header:selectFirst("img"):attr("src")) end)
    end
    novelInfo:setImageURL(imagePage)
    if header2:selectFirst(".js-tagList") then
        novelInfo:setTags(mapNotNil(header2:selectFirst(".js-tagList"):select(".tagItem"), function(v)
            return v:text()
        end))
    end
    pcall (function() novelInfo:setDescription(document:selectFirst(".message-body.threadmarkListingHeader-extraInfoChild"):text()) end)

    if not loadChapters then return novelInfo end

    local page = 0
    local pages = 1 -- 50 threadmarks per page
    local order = 1
    local chapters = {}
    repeat
        page = page+1
        local chaptersBody = GETDocument(url.."threadmarks?display=page&page="..page)
        local numThreadmarks = 0
        if page == 1 then
            map(chaptersBody:select(".dataList-cell--min"), function(v) -- Lua loops do not work with class Elements
                if v:text() ~= "Total" then
                    numThreadmarks = numThreadmarks+tonumber(v:text()) -- I have only seen threads with one user's threadmarks, but there is a chance there are multiple
                end
            end)
            pages = math.ceil(numThreadmarks/50)
        end

        local chaptersElements = chaptersBody:select(".structItem")

        map(chaptersElements, function(v) -- Lua loops do not work with class Elements
            local titleElement = v:selectFirst("a")
            chapters[#chapters+1] = NovelChapter{
                link = titleElement:attr("data-preview-url"),
                order = order,
                release = v:attr("data-content-date"),
                title = titleElement:text()
            }
            order = order+1
        end)
    until page == pages
    novelInfo:setChapters(chapters)
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
    chapterType = chapterType,
    startIndex = startIndex
}
