function timer_damage_taken(target, params)
    local steps = math.floor(get_age(target) / params.seconds_per_step)
    local bonus = steps * params.percent_per_step

    if params.max_percent and bonus > params.max_percent then
        bonus = params.max_percent
    end

    set_damage_taken(target, 1.0 + bonus)
end
