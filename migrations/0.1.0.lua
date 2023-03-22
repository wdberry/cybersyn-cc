for index, force in pairs(game.forces) do
  if force.technologies["cybersyn-train-network"] ~= nil and force.technologies["cybersyn-train-network"].researched then
    force.recipes["cybersyn-constant-combinator"].enabled = true
  end
end
