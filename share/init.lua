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

