function explode(target, params)
    local x, y = get_position(target)
    damage_area(x, y, params.radius, params.damage)
end