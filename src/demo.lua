local Deck = require("src.deck")

local Demo = { target = 15, drawLimit = 3 }

function Demo.new(random)
    local cards = {}
    for value = 1, 9 do
        cards[value] = { value = value }
    end
    return { deck = Deck.new(cards, random), hand = {}, score = 0 }
end

function Demo.draw(state)
    if #state.hand >= Demo.drawLimit then
        return
    end
    local card = state.deck:draw()
    state.hand[#state.hand + 1] = card
    state.score = state.score + card.value
end

return Demo
