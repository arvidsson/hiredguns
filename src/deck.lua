local Deck = {}
Deck.__index = Deck

function Deck.new(cards, random)
    local self = setmetatable({ drawPile = {}, discardPile = {}, random = random or math.random }, Deck)
    for _, card in ipairs(cards) do
        table.insert(self.drawPile, card)
    end
    self:shuffle()
    return self
end

function Deck:shuffle()
    -- Keep cards deliberately put on top in order when recycling the discard pile.
    local top = {}
    for i = #self.drawPile, 1, -1 do
        if self.drawPile[i].topdecked then
            table.insert(top, 1, table.remove(self.drawPile, i))
        end
    end
    for i = #self.drawPile, 2, -1 do
        local j = self.random(i)
        self.drawPile[i], self.drawPile[j] = self.drawPile[j], self.drawPile[i]
    end
    for _, card in ipairs(top) do
        self.drawPile[#self.drawPile + 1] = card
    end
end

function Deck:prepare(count)
    if #self.drawPile >= count or #self.discardPile == 0 then
        return false
    end
    for _, card in ipairs(self.discardPile) do
        table.insert(self.drawPile, card)
    end
    self.discardPile = {}
    self:shuffle()
    return true
end

function Deck:draw()
    local card = table.remove(self.drawPile)
    if card then
        card.topdecked = nil
    end
    return card
end

function Deck:putOnTop(card)
    card.topdecked = true
    self.drawPile[#self.drawPile + 1] = card
end

-- Preview in draw order without removing cards. Unchosen cards keep their order.
function Deck:peek(count)
    self:prepare(count)
    local cards = {}
    for index = #self.drawPile, math.max(1, #self.drawPile - count + 1), -1 do
        cards[#cards + 1] = self.drawPile[index]
    end
    return cards
end

function Deck:take(card)
    for index, entry in ipairs(self.drawPile) do
        if entry == card then
            card.topdecked = nil
            return table.remove(self.drawPile, index)
        end
    end
end

function Deck:discard(card)
    card.topdecked = nil
    table.insert(self.discardPile, card)
end

return Deck
