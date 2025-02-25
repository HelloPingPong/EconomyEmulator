# EconomyEmulator

EconomyEmulator is a simple, deterministic and event-driven economy manager designed to help you spice your game up with some price diversity.

EconomyEmulator is an educational project and may have flaws and bugs. You can use it "As Is".

EconomyEmulator is designed to be used in Godot game engine projects.

## Entities

- **EconomyEmulator** - entry point, inherited from Node and can be instanced manually or used in project autoload. Assumed to be used as a singleton. 
- **EconomyActor** - represents a node in economy tree graph, calculates prices for existing items, may have **PriceModifiers** and **EconomyEvent**s to alter prices. 
- **Item** - describes and item that could be bought or sold. Has name and base price. Base price never changes and is being used to calculate any further changes on top of it.
- **Group** - allows to group items and modify them at once using single **PriceModifier**. 
- **PriceModifier** - represents price modification, has item_name which could be an Item name or Group name. **PriceModifier** is a permanent modification and will affect price until removed. Has two types and two stacking types:
    - Types:
        - ADD - adds the value of **PriceModifier** to the price
        - MULTIPLY - multiplies the price by the value of **PriceModifier**
    - StackingTypes:
        - BASE - modification will be performed on base price
        - TOTAL - modification will be performed on total price after all the base modifications
- **EconomyEvent** - uses **PriceModifier** to change the price temporary and interpolate changes. 
    - Interpolation types:
        - IMMEDIATE - changes the price with full **PriceModifier** value. Could be used as a simple holiday price drop
        - LINEAR_IN - changes the price from 0% to 100% of **PriceModifier** value during event duration. Could be used before adding a permanent **PriceModifier**
        - LINEAR_OUT - changes the price from 100% to 0% of **PriceModifier** value during event duration. Could be used as an immediate change that fades out with time
        - WAVE - ramps up and down as a sin(p * PI) where p is the percent of event duration. Could be used as a general event that comes and goes 


## Usage example - modifiers
    
    var economy = EconomyEmulator.new()

    economy.add_actor('city')

    # city is a parent of merchant
    economy.add_actor('merchant', 'city')

    economy.add_item('apple', 20)
    economy.add_item('banana', 30)

    economy.add_group('food')

    economy.add_item_to_group('apple', 'food')
    economy.add_item_to_group('banana', 'food')

    # apple price modifier that adds 3 to base price
    economy.add_modifier('mod_apple', 'apple', 3, PriceModifier.Types.ADD, PriceModifier.StackingTypes.BASE) 
    
    # food group price modifier that multiplies base price by 2
    economy.add_modifier('mod_food', 'food', 2, PriceModifier.Types.MULTIPLY, PriceModifier.StackingTypes.BASE)

    # banana price modifier that multiplies base price by 2
    economy.add_modifier('greedy_merchant', 'banana', 2, PriceModifier.Types.MULTIPLY, PriceModifier.StackingTypes.BASE)
    
    # apply modifier globally
    economy.activate_modifier('mod_apple')
    # apply modifier to city
    economy.activate_modifier('mod_food', 'city')
    # apply modifier to merchant
    economy.activate_modifier('greedy_merchant', 'merchant')
    
    # check the global price for apple 
    print(economy.get_price('apple')) #prints 23

    # check the price for apple in city, zero is the global time
    print(economy.get_price('apple', 0, 'city')) #prints 43

     # check the price of merchant for apple, zero is the global time
    print(economy.get_price('apple', 0, 'merchant')) #prints 43

    # check the global price for banana 
    print(economy.get_price('banana')) #prints 30

    # check the price for banana in city, zero is the global time
    print(economy.get_price('banana', 0, 'city')) #prints 60

     # check the price of merchant for banana, zero is the global time
    print(economy.get_price('banana', 0, 'merchant')) #prints 120

## Usage example - events

    var economy = EconomyEmulator.new()
    economy.add_actor('city_one')
    economy.add_actor('city_two')
    economy.add_actor('merchant_one', 'city_one')
    economy.add_actor('merchant_two', 'city_two')
    
    economy.add_item('apple', 20)
    economy.add_item('banana', 30)
    economy.add_item('sword', 50)
    
    economy.add_group('food')
    
    economy.add_item_to_group('apple', 'food')
    economy.add_item_to_group('banana', 'food')
    
    economy.add_modifier('drought_modifier', 'food', 3, PriceModifier.Types.MULTIPLY, PriceModifier.StackingTypes.BASE)
    
    # create drought event with duration of 10 seconds
    economy.add_event('drought_event', 'drought_modifier', 0, 10, EconomyEvent.Types.WAVE)
    
    # activate drought event in city_one with delay of 0
    economy.activate_event('drought_event', 0, 'city_one')
    
    # see how prices of merchant_one change during the event
    print(economy.get_price('apple', 0, 'merchant_one')) #prints 20
    print(economy.get_price('apple', 3, 'merchant_one')) #prints 52.36
    print(economy.get_price('apple', 5, 'merchant_one')) #prints 60
    print(economy.get_price('apple', 8, 'merchant_one')) #prints 43.51
    print(economy.get_price('apple', 10, 'merchant_one')) #prints 20
    
    # sword is not in the food group so price don't change
    print(economy.get_price('sword', 0, 'merchant_one')) #prints 50
    print(economy.get_price('sword', 5, 'merchant_one')) #prints 50
    print(economy.get_price('sword', 10, 'merchant_one')) #prints 50
    
    # merchant_two lives in another city and the prices not affected
    print(economy.get_price('apple', 0, 'merchant_two')) #prints 20
    print(economy.get_price('apple', 3, 'merchant_two')) #prints 20
    print(economy.get_price('apple', 5, 'merchant_two')) #prints 20
    print(economy.get_price('apple', 8, 'merchant_two')) #prints 20
    print(economy.get_price('apple', 10, 'merchant_two')) #prints 20
