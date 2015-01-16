-- Version
local VERSION               = "1.55"

-- Modules
wot_cache = wot_cache or {}
local wot_cache = wot_cache
local bad_expire_time = 3600 * 24
local expire_time = 60 * 30
local expire_in_process = 0
local max_del_per_iter = 1000
local space = 3
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
        if box.select(space, 0, rec.target) then
            box.update(space, rec.target, '=p=p=p', 1, box.cjson.encode(rec), 2, box.time(), 3, bad_answer)
        else
            box.insert(space, rec.target, box.cjson.encode(rec), box.time(), bad_answer)
        end
    end
    box.fiber.wrap(function() _expire_field(space) end)
    return {}
end

function _expire_field(space)
    if expire_in_process == 0 then
        expire_in_process = 1
        local dt = os.date('*t')
        local cd = box.time() - expire_time
        local cdb = box.time() - bad_expire_time
        local cur_iter = 0
        for v in box.space[space].index[1]:iterator(box.index.GT, 0) do
            if( max_del_per_iter < cur_iter and box.unpack('i',v[2]) < cd ) then break end
            box.delete(space, v[0])
            cur_iter = cur_iter + 1
        end
        expire_in_progres = 0
    end
end

print(wot_cache._NAME .. " version " .. VERSION .. " loaded")

