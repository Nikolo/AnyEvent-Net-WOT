-- Version
local VERSION               = "1.0"

-- Modules
wot_cache = wot_cache or {}
local wot_cache = wot_cache
module('wot_cache', package.seeall)

function add_to_wot_cache(space_num,json)
    local space = tonumber(space_num)
    for k,rec in pairs(box.cjson.decode(json)) do
        local bad_answer;
        if rec.bad_answer then
            bad_answer = tonumber(rec.bad_answer)
        else
            bad_answer = 0
        end
        box.insert(space, rec.target, box.cjson.encode(rec), box.time(), bad_answer)
    end
end

print(wot_cache._NAME .. " version " .. VERSION .. " loaded")

