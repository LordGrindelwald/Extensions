-- {"id":94593,"ver":"0.0.1","libVer":"1.0.0","author":"Amelia Magdovitz","dep":["dkjson, url"]}
local Json = Require("dkjson")
local URLlib = Require("url")

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
--We'll see
--- If the websites search increments or not.
---
--- Optional, Default is true.
---
--- @type boolean
local isSearchIncrementing = false
--We'll see
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
                local image = imageURL
                if vv:selectFirst("img") then
                    image = vv:selectFirst("img"):attr("src")
                end
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
local function parseNovel(novelURL, loadChapters)
    local url = expandURL(novelURL)
    --- Novel page, extract info from it.
    --- Can not get ongoing status, as all forums say Ongoing, even those that are 19 years old
    local document = GETDocument(url)
    local header  = document:selectFirst(".threadmarkListingHeader")
    local header2 = document:selectFirst(".p-body-header")
    local novelInfo =  NovelInfo {
        title = document:selectFirst(".p-title-value"),
        authors = {header2:selectFirst(".u-concealed.username"):text()}
    }

    if pcall(function() header:selectFirst("img") end) then
        pcall(function() novelInfo:setImageURL(header:selectFirst("img"):attr("src")) end)
    end
    if header2:selectFirst(".js-tagList") then
        novelInfo:setTags(mapNotNil(header2:selectFirst(".js-tagList"):select(".tagItem"), function(v)
            return v:text()
        end))
    end

    -- TODO fix
    local desc = "There was a problem with getting the description"
    pcall(function() desc = header2:selectFirst(".bbWrapper"):text() end)

    --- Chapters time


    --- Try to find the info in the original document
    local hiddenButton = nil
    pcall(function() hiddenButton = document:selectFirst("#js-XFUniqueId12") end)
    if hiddenButton then
        local buttonURL = hiddenButton:attr("data-fetchurl")
        buttonURL = buttonURL:gsub("&min=1", "&min=-1")
        local maxloc = buttonURL:find("&max=")
        maxloc[1] = maxloc[1]+5
        maxloc[2] = #buttonURL
        print("hellp")
        print(buttonURL:sub(maxloc))
    end

                                                                                    --I have no clue where this token comes from rn
    local body = "_xfRequestUri=".. URLlib.encode(novelURL) .."&_xfWithData=1&_xfToken=1709821056%2Ce465e9dc1f5fb9cae4219ba2f7df0921&_xfResponseType=json"
    -- novelURL looks like https://forums.spacebattles.com//threads/demesne-fantasy-comedy-town-building-engineering-dungeon-not-a-litrpg.918789/
    -- we need https://forums.spacebattles.com/threads/venator-worm-star-wars-crossover.1137160/threadmarks-load-range?threadmark_category_id=1&min=0&max=9999999999999999999999999999999
    local h = HeadersBuilder()
    -- gotta get this one too
    h:set("Cookies", "[{\"name\": \"xf_csrf\",\"value\": \"1sEnrz42Nmag8fX7\"}]")
    h:set("Cookie",'xf_csrf=1sEnrz42Nmag8fX7')
    h:add("Accept", "application/json; q=0.01")

    local chapterInfo = Json.POST(url.."threadmarks-load-range?threadmark_category_id=1&min="..min.."&max="..max, body, h:build())
    if type(chapterInfo) == type("This is a String") then
        return novelInfo
    end
    if chapterInfo["status"] ~= "ok" or loadChapters == false then
        return novelInfo
    end
    local chapterHTML = chapterInfo["html"]["content"]:gsub("\n",""):gsub("\t","")

    return novelInfo
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
