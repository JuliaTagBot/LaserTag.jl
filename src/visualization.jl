using TikzPictures
using ParticleFilters

type LaserTagVis
    p::LaserTagPOMDP
    s::Nullable{Any}
    a::Nullable{Any}
    o::Nullable{Any}
    b::Nullable{Any}
    r::Nullable{Any}
end
LaserTagVis(p; s=nothing, a=nothing, o=nothing, b=nothing, r=nothing) = LaserTagVis(p, s, a, o, b, r)

Base.show(io::IO, mime::MIME"image/svg+xml", v::LaserTagVis) = show(io, mime, tikz_pic(v))

#=
function colorval(val, brightness::Real = 1.0)
  val = convert(Vector{Float64}, val)
  x = 255 - min(255, 255 * (abs(val) ./ 10.0) .^ brightness)
  r = 255 * ones(size(val))
  g = 255 * ones(size(val))
  b = 255 * ones(size(val))
  r[val .>= 0] = x[val .>= 0]
  b[val .>= 0] = x[val .>= 0]
  g[val .< 0] = x[val .< 0]
  b[val .< 0] = x[val .< 0]
  (r, g, b)
end
=#

function fill_square(o::IO, x, y, color, opacity=0.5) # maybe opacity should be a keyword
    sqsize = 1.0
    println(o, "\\fill[$(color), opacity=$opacity] ($((x-1) * sqsize),$((y-1) * sqsize)) rectangle +($sqsize,$sqsize);")
end

function show_belief(o::IO, b::ParticleCollection{LTState})
    d = Dict{Coord, Int}()
    total = 0
    for p in particles(b)
        if !p.terminal
            opp = p.opponent
            if haskey(d, opp)
                d[opp] += 1
            else
                d[opp] = 1
            end
            total += 1
        end
    end
    for (opp, freq) in d
        fill_square(o, opp[1], opp[2], "yellow", sqrt(freq/total))
    end
end

function show_meas(o::IO, s::LTState, obs::CMeas)
    middle = s.robot - 0.5
    for i in 1:4
        dir = CARDINALS[i]
        start = middle+0.5*dir
        finish = start + obs[i]*dir
        draw_laser(o, start, finish)
    end
    for i in 5:8
        dir = DIAGONALS[i-4]*sqrt(2)/2
        start = middle+0.5*sqrt(2)*dir
        finish = start + obs[i]*dir 
        draw_laser(o, start, finish)
    end
end

function draw_laser(o::IO, start::AbstractVector{Float64}, finish::AbstractVector{Float64})
    println(o, "\\draw[dashed, red] ($(start[1]), $(start[2])) -- ($(finish[1]), $(finish[2]));")
end

function tikz_pic(v::LaserTagVis)
    p = v.p
    f = p.floor
    o = IOBuffer()
    sqsize=1

    for c in p.obstacles
        fill_square(o, c[1], c[2], "gray")
    end

    if !isnull(v.b)
        show_belief(o, get(v.b))
    end

    if !isnull(v.s)
        s = get(v.s)
        opp = s.opponent
        rob = s.robot
        fill_square(o, opp[1], opp[2], "orange")
        fill_square(o, rob[1], rob[2], "green")
        if !isnull(v.o)
            show_meas(o, s, get(v.o))
        end
        if !isnull(v.a)
            aname = ACTION_NAMES[get(v.a)]
            println(o, "\\node[above right] at ($((rob[1]-1) * sqsize), $((rob[2]-1) * sqsize)) {$aname};")
        end
        if !isnull(v.r)
            rtext = @sprintf("%0.2f", get(v.r))
            println(o, "\\node[below right] at ($((rob[1]-1) * sqsize), $((rob[2]-1) * sqsize)) {$rtext};")
        end

    end

    # # possibly for later: text in a square
    # vs = @sprintf("%0.2f", V[i])
    # println(o, "\\node[above right] at ($((xval-1) * sqsize), $((yval-1) * sqsize)) {\$$(vs)\$};")

    println(o, "\\draw[black] grid($(f.n_cols), $(f.n_rows));")
    tikzDeleteIntermediate(false)
    return TikzPicture(takebuf_string(o), options="scale=1.25")
end