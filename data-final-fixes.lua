-- check if LogisticTrainNetwork added
if mods["cybersyn"] and data.raw["technology"]["cybersyn-train-network"] then
  table.insert(
    data.raw["technology"]["cybersyn-train-network"].effects,
    {type = "unlock-recipe", recipe = "cybersyn-constant-combinator"}
  )
else
  table.insert(
    data.raw["technology"]["circuit-network"].effects,
    {type = "unlock-recipe", recipe = "cybersyn-constant-combinator"}
  )
end

local upgradable = settings.startup["ltnc-upgradable"].value
if upgradable == nil then
  upgradable = true
end


if upgradable == true then
  -- make vanilla combinator upgradable to cybersyn-constant-combinator
  data.raw["constant-combinator"]["constant-combinator"].next_upgrade = "cybersyn-constant-combinator"
end

data.raw["constant-combinator"]["constant-combinator"].fast_replaceable_group = "constant-combinator"
