
using JSON

const industries_filename = "112th-industries.json"
const bills_filename = "112th-bills.json"
const output_filename = "industry-engagement.json"

function filter_overlapping_votes(bills)
    overlap = Any[]
    for (k,v) in bills
        for (k2,v2) in bills
            if k != k2 && v["num"] == v2["num"] && v["prefix"] == v2["prefix"]
                if !([k, k2] in overlap) && !([k2, k] in overlap)
                    push!(overlap, [k, k2])
                end
            end
        end
    end

    for (id1, id2) in overlap
        (haskey(bills, id1) && haskey(bills, id2)) || continue

        passed1 = get(bills[id1], "dateVote", -1)
        passed2 = get(bills[id2], "dateVote", -2)
        if passed1 == passed2
            delete!(bills, id1)
        end
    end

    bills
end

function filter_has_votes(bills)
    filter((k,b)->get(b, "action", "") == "passage", bills)
end

function build_engagement_map(bills, industries)
    engagement_map = Dict()

    for (id, name) in industries
        engagement_map[id] = {
            "supported" => 0,
            "opposed" => 0
        }
    end

    for (aid, data) in bills
        supporters = data["positions"]["support"]
        for ind in supporters
            engagement_map[ind]["supported"] += 1
        end

        opposers = data["positions"]["opposed"]
        for ind in opposers
            engagement_map[ind]["opposed"] += 1
        end
    end

    engagement_map
end

function format_engagement_data(engagement_map)
    order = collect(keys(engagement_map))
    sort!(order, lt = (lhs, rhs) -> ((engagement_map[lhs]["supported"] + engagement_map[lhs]["opposed"]) < (engagement_map[rhs]["supported"] + engagement_map[rhs]["opposed"])))

    engagement_table = [
        { "name" => "Supported", "data" => Any[] },
        { "name" => "Opposed", "data" => Any[] },
    ]

    supporter_data = engagement_table[1]["data"]
    opposed_data = engagement_table[2]["data"]

    for ind in order
        push!(supporter_data, {
            "id" => ind,
            "x" => industries[ind],
            "y" => engagement_map[ind]["supported"]
        })

        push!(opposed_data, {
            "id" => ind,
            "x" => industries[ind],
            "y" => engagement_map[ind]["opposed"]
        })
    end

    engagement_table
end


industries = JSON.parse(readall(industries_filename))
bills = JSON.parse(readall(bills_filename))
bills = filter_overlapping_votes(filter_has_votes(bills))

for (aid, data) in bills
    data["positions"]["support"] = unique(data["positions"]["support"])
    data["positions"]["opposed"] = unique(data["positions"]["opposed"])
end


engagement_map = build_engagement_map(bills, industries)

out = open(output_filename, "w")
write(out, json(format_engagement_data(engagement_map)))
close(out)