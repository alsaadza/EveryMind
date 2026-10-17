import Foundation

extension OfflineLibrary {

    static func waterCycleChapters(level: SkillLevel) -> [Chapter] {
        [waterChapter1(level), waterChapter2(level), waterChapter3(level)]
    }

    static func waterChapter1(_ level: SkillLevel) -> Chapter {
        var sections: [LessonSection] = []
        sections.append(sec("Water on the move",
            "The water in your glass today may once have been part of a glacier, a thundercloud or even a dinosaur's drink. Earth has had roughly the same amount of water for billions of years. It doesn't get used up; it **moves** and **changes form**.\n\nThis endless journey is called the **water cycle**. Energy from the **Sun** drives it, and **gravity** pulls water back down. Along the way water switches between three states: liquid (water), gas (water vapor) and solid (ice).",
            Illustration(kind: .waterCycle, caption: "Tap each stage of the cycle to explore it."),
            check("What provides the energy that drives the water cycle?", ["The Moon", "The Sun", "Earth's core"], 1, "Sunlight heats water and makes it evaporate.")))
        sections.append(sec("Evaporation",
            "When sunlight warms the surface of oceans, lakes and puddles, some water molecules gain enough energy to escape into the air as invisible **water vapor**. This is **evaporation**.\n\nAbout 86% of the water that evaporates on Earth comes from the oceans. Warm temperatures, wind and dry air all speed it up, which is why laundry dries faster on a hot, breezy day.\n\n" + pick(level,
                "Plants release water vapor too, through tiny holes in their leaves. That's called **transpiration**.",
                "Plants add water vapor through **transpiration**; together with evaporation this is called **evapotranspiration**. Evaporation absorbs energy, which is why sweating cools you.",
                "Evaporation absorbs latent heat (about 2,260 kJ per kg at 100 °C). That energy is released later when vapor condenses, moving heat from the surface into the atmosphere and powering storms."),
            Illustration(kind: .conceptCard, caption: "What speeds up evaporation?", labels: ["Higher temperature", "Wind moving the air", "Dry air (low humidity)", "Larger surface area"]),
            check("On which day would a puddle evaporate fastest?", ["Cold and still", "Hot and windy", "Cool and humid"], 1, "Heat gives molecules energy and wind carries away the vapor.")))
        sections.append(sec("Condensation",
            "As warm, moist air rises, it cools. Cool air can't hold as much water vapor, so the vapor **condenses** back into tiny liquid droplets around specks of dust, salt or smoke. Billions of droplets together form **clouds**.\n\nYou've seen condensation on a cold drink on a summer day. The glass doesn't leak. Water vapor in the air touches the cold glass, cools and turns back to liquid.",
            Illustration(kind: .numberLine, caption: "Relative humidity: at 100% the air is saturated and condensation begins", params: ["value": 0.95], labels: ["Cloud forms"]),
            check("Water droplets on the outside of a cold glass come from…", ["Water leaking through the glass", "Water vapor in the air condensing", "Ice melting inside"], 1, "Vapor from the air cools on the glass and condenses.")))

        var challenges: [Challenge] = []
        challenges.append(short("Explain why a puddle disappears on a sunny afternoon. Where does the water go?",
            answer: "The Sun heats the water, so it evaporates into water vapor in the air.",
            hints: ["The water didn't vanish. It changed form.", "What does sunlight do to the water's temperature?", "Name the process and the state the water ends up in."],
            solution: "Sunlight heats the puddle, giving water molecules energy to escape as water vapor. This is evaporation, and the vapor mixes into the air.",
            rubric: [rub("You named evaporation", ["evaporat"]),
                     rub("You linked it to the Sun's heat", ["sun", "heat", "warm", "energy", "hot"]),
                     rub("You said it becomes water vapor in the air", ["vapor", "vapour", "gas", "air", "steam"])],
            misconceptions: ["it soaks into the ground": "ignored-evaporation", "it disappears": "matter-disappears"]))
        challenges.append(choice("Which change of state happens when a cloud forms?",
            options: ["Gas to liquid (condensation)", "Liquid to gas (evaporation)", "Solid to liquid (melting)"],
            answer: "Gas to liquid (condensation)",
            hints: ["What is water vapor: solid, liquid or gas?", "What are cloud droplets made of?", "Vapor becoming droplets is going from which state to which?"],
            solution: "Clouds form when rising water vapor (gas) cools and condenses into liquid droplets.",
            rubric: [rub("You identified vapor as a gas", ["gas", "vapor", "vapour"]), rub("You described cooling into droplets", ["cool", "droplet", "liquid", "condens"])],
            misconceptions: ["Liquid to gas (evaporation)": "reversed-state-change"]))
        switch level {
        case .beginner:
            challenges.append(short("Why does a cold can of juice get wet on the outside on a hot day?",
                answer: "Water vapor in the warm air touches the cold can, cools and condenses into droplets.",
                hints: ["Is the water coming from inside the can?", "What is in the air around the can?", "What happens to vapor when it gets cold?"],
                solution: "Warm air holds water vapor. When it touches the cold can, the vapor cools and condenses into liquid droplets.",
                rubric: [rub("You named condensation", ["condens"]), rub("You said the water comes from the air", ["air", "vapor", "vapour"]), rub("You mentioned cooling", ["cold", "cool"])],
                misconceptions: ["it leaks": "leak-misconception"]))
        case .intermediate:
            challenges.append(short("Explain why sweating cools your body. Use the word 'energy'.",
                answer: "Evaporating sweat absorbs heat energy from the skin, which cools you.",
                hints: ["Sweat is liquid water on your skin.", "What does water need to evaporate?", "Where does that energy come from?"],
                solution: "Evaporation needs energy. Sweat takes heat energy from your skin to evaporate, so your skin cools.",
                rubric: [rub("You named evaporation", ["evaporat"]), rub("You explained energy is absorbed", ["energy", "heat", "absorb", "takes"]), rub("You connected it to cooling the skin", ["skin", "body", "cool"])]))
        case .advanced:
            challenges.append(numeric("About 97% of Earth's water is salty ocean water. About 2/3 of the remaining fresh water is frozen in ice. Roughly what percent of all Earth's water is fresh and not frozen?",
                answer: "1%",
                hints: ["First find the percent that is fresh water.", "Two-thirds of that is frozen. What fraction is not frozen?", "Find 1/3 of 3%."],
                solution: "Fresh water = 100% − 97% = 3%. Not frozen = 1/3 × 3% = 1%. That tiny share supplies rivers, lakes and groundwater.",
                rubric: [rub("You found 3% fresh water", ["3%", "3 %", "100 - 97", "three percent"]), rub("You took one third", ["1/3", "third", "one-third"])],
                misconceptions: ["2%": "used-frozen-fraction", "3%": "ignored-frozen", "33%": "fraction-of-whole-confusion"]))
        }
        return Chapter(index: 0, title: "Evaporation and Condensation", summary: "How sunlight lifts water into the air and how cooling turns it back into droplets.",
            locationName: "Sunlit Shore", theme: .harbor,
            npc: NPC(name: "Marina the Otter", role: "Keeper of the Shore", greeting: "Every wave here has traveled to the sky and back. Want to follow a drop on its journey?", emoji: "🦦"),
            sections: sections,
            keyIdeas: ["Earth's water is recycled; it changes form but isn't used up.", "The Sun powers the cycle; gravity brings water back down.", "Evaporation: liquid becomes vapor when heated.", "Condensation: vapor cools into droplets, forming clouds."],
            challenges: challenges,
            discussionPrompts: ["Put a cold glass on a table at home. What do you notice after 10 minutes and why?", "Where could the water in your glass have been 1,000 years ago?", "Why does laundry dry faster on some days than others?"])
    }

    static func waterChapter2(_ level: SkillLevel) -> Chapter {
        var sections: [LessonSection] = []
        sections.append(sec("Inside a cloud",
            "A cloud is made of trillions of tiny water droplets or ice crystals, each so small and light that rising air keeps it floating. A typical cloud droplet is about a hundredth of a millimeter across.\n\nFor rain to fall, droplets must **collide and merge** until they're heavy enough to overcome the updrafts. It takes about a million cloud droplets to make one raindrop.",
            Illustration(kind: .conceptCard, caption: "Types of clouds", labels: ["Cumulus: puffy, fair weather", "Stratus: flat gray layers", "Cirrus: thin, wispy, made of ice", "Cumulonimbus: towering storm clouds"]),
            check("Why don't cloud droplets fall right away?", ["They are too small and light; rising air holds them up", "Clouds are made of gas", "Gravity doesn't act on clouds"], 0, "Tiny droplets are kept aloft by updrafts until they grow larger.")))
        sections.append(sec("Precipitation",
            "**Precipitation** is any water that falls from clouds: rain, snow, sleet or hail. Which one you get depends on the temperature of the air the water falls through.\n\nSnow forms when it's below freezing all the way down. Sleet happens when snow melts in a warm layer and refreezes near the ground. Hail grows inside thunderstorms, where strong updrafts toss ice pellets up and down, adding layers like an onion.\n\n" + pick(level, "", "Mountains squeeze precipitation out of air: as moist air is forced upward it cools and condenses, so the windward side is wet and the leeward side is often a dry **rain shadow**.", "Orographic lift explains rain shadows. In cold clouds, the Bergeron process lets ice crystals grow at the expense of supercooled droplets, a key route to precipitation at mid-latitudes."),
            Illustration(kind: .waterCycle, caption: "Follow precipitation from cloud to ground."),
            check("What decides whether precipitation falls as rain or snow?", ["The color of the cloud", "The temperature of the air it falls through", "The time of day"], 1, "Below-freezing air all the way down gives snow.")))
        sections.append(sec("Measuring rain",
            "Scientists measure rain with a **rain gauge**, a container that collects water so its depth can be read. One inch of rain over one acre is about 27,000 gallons of water!\n\nWeather forecasts give a **chance of precipitation**. A 70% chance means that in similar conditions it rained 7 times out of 10.",
            Illustration(kind: .numberLine, caption: "A 70% chance of rain on the likelihood scale", params: ["value": 0.7], labels: ["Rain"])))

        var challenges: [Challenge] = []
        challenges.append(short("Describe how a cloud droplet becomes a raindrop that falls to the ground.",
            answer: "Droplets collide and merge into bigger drops until they are heavy enough for gravity to pull them down.",
            hints: ["Cloud droplets are very small. What must happen to their size?", "How do droplets get bigger?", "What force finally pulls them down?"],
            solution: "Tiny droplets bump into each other and merge (coalesce). When drops become heavy enough to overcome rising air, gravity pulls them down as rain.",
            rubric: [rub("You described droplets combining", ["collide", "merge", "combine", "join", "bump", "coalesc", "stick"]),
                     rub("You said they become heavier or bigger", ["heavy", "bigger", "larger", "grow", "weight"]),
                     rub("You mentioned gravity", ["gravity", "fall", "pull"])]))
        challenges.append(choice("A snowflake falls through a layer of warm air, melts, then refreezes just above the ground. What lands?",
            options: ["Hail", "Sleet", "Snow"],
            answer: "Sleet",
            hints: ["Track the temperature changes on the way down.", "It melted and then froze again near the ground.", "Hail forms in thunderstorm updrafts, not this way."],
            solution: "Melting in a warm layer then refreezing near the ground produces sleet, small ice pellets.",
            rubric: [rub("You tracked melting then refreezing", ["melt", "refreez", "freez"]), rub("You distinguished it from hail", ["hail", "updraft", "storm"])],
            misconceptions: ["Hail": "hail-sleet-confusion", "Snow": "ignored-melting"]))
        switch level {
        case .beginner:
            challenges.append(short("Name two kinds of precipitation and explain what makes them different.",
                answer: "Rain is liquid water; snow is frozen water that falls when the air is below freezing.",
                hints: ["Precipitation is water falling from clouds.", "Think about the form the water takes.", "What role does temperature play?"],
                solution: "Rain is liquid drops; snow is ice crystals that stay frozen because the air is below freezing on the way down.",
                rubric: [rub("You named two types", ["rain", "snow", "sleet", "hail"]), rub("You explained the role of temperature", ["cold", "freez", "warm", "temperature", "melt"])]))
        case .intermediate:
            challenges.append(short("Why is one side of a mountain range often much wetter than the other?",
                answer: "Moist air rises up the windward side, cools and rains; the leeward side gets dry air (rain shadow).",
                hints: ["What happens to air forced up a mountain?", "Cooler air holds less vapor. What happens to the extra?", "What's left in the air when it reaches the other side?"],
                solution: "Air rising over the mountain cools, condenses and drops its water on the windward side. Drier air descends the other side, creating a rain shadow.",
                rubric: [rub("You described air rising and cooling", ["rise", "rising", "up", "cool"]), rub("You explained precipitation on one side", ["rain", "precipitat", "windward", "condens"]), rub("You described the dry side", ["dry", "rain shadow", "leeward", "less"])]))
        case .advanced:
            challenges.append(numeric("A rain gauge collects 2 cm of rain over a 50 m² rooftop. How many liters of water fell on the roof? (1 m³ = 1000 L)",
                answer: "1000",
                hints: ["Volume = area × depth.", "Convert 2 cm to meters.", "50 × 0.02 m³, then convert to liters."],
                solution: "Volume = 50 m² × 0.02 m = 1 m³ = 1000 L.",
                rubric: [rub("You multiplied area by depth", ["area", "depth", "×", "*", "multiply", "volume"]), rub("You converted units", ["0.02", "meters", "1000", "liters", "m³", "m3"])],
                misconceptions: ["100": "unit-conversion", "10": "unit-conversion", "100000": "unit-conversion"]))
        }
        return Chapter(index: 1, title: "Clouds and Precipitation", summary: "How clouds hold water, and how rain, snow, sleet and hail make it back to the ground.",
            locationName: "Cloud Peak", theme: .observatory,
            npc: NPC(name: "Nimbus the Eagle", role: "Watcher of Cloud Peak", greeting: "From up here I see every storm being born. Can you explain how a cloud lets go of its water?", emoji: "🦅"),
            sections: sections,
            keyIdeas: ["Clouds are tiny droplets or ice crystals held up by rising air.", "Droplets merge until heavy enough to fall.", "Air temperature decides rain, snow, sleet or hail.", "Mountains can create wet windward sides and dry rain shadows."],
            challenges: challenges,
            discussionPrompts: ["Look at the sky today. What type of clouds do you see, and what weather might they bring?", "Build a simple rain gauge with a jar. How much rain falls this week?", "Why might a forecast of 30% rain still mean you should bring an umbrella?"])
    }

    static func waterChapter3(_ level: SkillLevel) -> Chapter {
        var sections: [LessonSection] = []
        sections.append(sec("Collection and runoff",
            "When precipitation reaches the ground, gravity takes over. Some water flows over the surface as **runoff** into streams, rivers and eventually the ocean. The land area that drains into one river is its **watershed**.\n\nPaved surfaces like roads and parking lots don't let water soak in, so cities produce much more runoff. That can cause flooding and carry pollution into rivers.",
            Illustration(kind: .waterCycle, caption: "Runoff and collection complete the loop."),
            check("Why do cities often have more flooding than forests after heavy rain?", ["Cities get more rain", "Pavement stops water from soaking in", "Forests have no rivers"], 1, "Hard surfaces turn rain into fast runoff.")))
        sections.append(sec("Infiltration and groundwater",
            "Some water soaks into the soil, called **infiltration**. It trickles down through gaps in soil and rock until it reaches the **water table**, where the ground is saturated. This underground water is **groundwater**, stored in layers of rock called **aquifers**.\n\nGroundwater moves slowly, sometimes only centimeters a day, and can stay underground for thousands of years. Wells and springs tap into it, and it supplies drinking water for about half the world's people.",
            Illustration(kind: .conceptCard, caption: "Where rain goes after it lands", labels: ["Runoff into rivers", "Infiltration into soil", "Groundwater in aquifers", "Taken up by plants", "Evaporates again"]),
            check("What is an aquifer?", ["A cloud type", "An underground layer of rock that holds water", "A water treatment plant"], 1, "Aquifers store groundwater in porous rock.")))
        sections.append(sec("People and the water cycle",
            "Humans change the cycle: we pump groundwater, build dams, pave land and warm the climate. Warmer air holds about 7% more water vapor per degree Celsius, which can make heavy rainstorms more intense and droughts more severe.\n\nSmart choices help: rain gardens and permeable pavement increase infiltration, and saving water reduces how much we pump from aquifers.\n\n" + pick(level, "Even small actions, like fixing a dripping faucet, help.", "Over-pumping can lower the water table faster than rain can recharge it, drying up wells and streams.", "The 7%/°C figure comes from the Clausius–Clapeyron relation. Observed extreme-precipitation increases in many regions roughly match this scaling."),
            Illustration(kind: .numberLine, caption: "Share of rain that runs off a city street versus a forest (illustrative)", params: ["value": 0.55], labels: ["City runoff"])))

        var challenges: [Challenge] = []
        challenges.append(short("A town replaces a grassy field with a parking lot. Predict what happens to runoff and groundwater, and explain why.",
            answer: "Runoff increases and less water reaches groundwater because pavement blocks infiltration.",
            hints: ["Can water soak through asphalt?", "If water can't soak in, where does it go?", "What happens to the water underground over time?"],
            solution: "Pavement blocks infiltration, so more rain becomes runoff (raising flood risk) and less recharges groundwater.",
            rubric: [rub("You predicted more runoff", ["more runoff", "runoff", "flood", "flows", "run off"]),
                     rub("You predicted less groundwater recharge", ["less groundwater", "groundwater", "water table", "aquifer", "less water underground"]),
                     rub("You explained infiltration is blocked", ["soak", "infiltrat", "block", "can't", "cannot", "pavement", "impermeable"])]))
        challenges.append(choice("Which action increases infiltration in a neighborhood?",
            options: ["Building a rain garden", "Paving a driveway", "Removing trees"],
            answer: "Building a rain garden",
            hints: ["Which option gives water a place to soak in?", "Paving and removing plants both reduce soaking.", "Plants and loose soil help water infiltrate."],
            solution: "Rain gardens collect runoff in planted, loose soil so water can soak in.",
            rubric: [rub("You explained water soaking in", ["soak", "infiltrat", "absorb", "into the ground"]), rub("You mentioned plants or soil", ["plant", "soil", "garden", "roots"])],
            misconceptions: ["Paving a driveway": "pavement-misconception"]))
        switch level {
        case .beginner:
            challenges.append(short("Trace one drop of water through the whole water cycle, from the ocean and back again.",
                answer: "Evaporates from the ocean, condenses into a cloud, falls as rain, flows in a river back to the ocean.",
                hints: ["Start at the ocean. How does the drop get into the air?", "How does it become part of a cloud and then fall?", "How does it get back to the ocean?"],
                solution: "The drop evaporates from the ocean, condenses in a cloud, falls as precipitation, and returns as runoff or groundwater.",
                rubric: [rub("You included evaporation", ["evaporat"]), rub("You included condensation or clouds", ["condens", "cloud"]), rub("You included precipitation and return", ["rain", "precipitat", "snow", "river", "runoff", "back"])]))
        case .intermediate:
            challenges.append(short("Explain why groundwater can run out even though water is constantly recycled.",
                answer: "We can pump it out faster than infiltration recharges it, so the water table drops.",
                hints: ["How fast does groundwater move and refill?", "How fast can wells pump?", "Compare the two rates."],
                solution: "Recharge is slow. If pumping exceeds recharge, the water table falls and wells can dry up, even though the water still exists elsewhere in the cycle.",
                rubric: [rub("You compared pumping and recharge rates", ["faster", "rate", "recharge", "refill", "slow"]), rub("You mentioned the water table", ["water table", "aquifer", "drop", "lower"])]))
        case .advanced:
            challenges.append(numeric("If warmer air holds about 7% more water vapor per °C, roughly how many percent more vapor could air hold after 3 °C of warming? (Compounded, nearest whole percent.)",
                answer: "23%",
                hints: ["Each degree multiplies capacity by 1.07.", "Three degrees means multiplying three times.", "Compute 1.07³ and convert to a percent increase."],
                solution: "1.07³ ≈ 1.225, so about 23% more water vapor (simple addition gives 21%).",
                rubric: [rub("You compounded the growth", ["1.07", "^3", "³", "compound", "three times"]), rub("You converted to a percent increase", ["1.225", "22", "23", "percent"])],
                misconceptions: ["21%": "added-instead-of-compounded", "7%": "ignored-repetition"]))
        }
        return Chapter(index: 2, title: "Collection, Groundwater and People", summary: "Runoff, infiltration and aquifers, and how human choices reshape the cycle.",
            locationName: "River Valley", theme: .garden,
            npc: NPC(name: "Willow the Beaver", role: "Builder of River Valley", greeting: "I build dams, and so do you humans! Let's see where the rain goes once it lands.", emoji: "🦫"),
            sections: sections,
            keyIdeas: ["Runoff flows over land into rivers within a watershed.", "Infiltration recharges groundwater in aquifers.", "Pavement increases runoff and reduces recharge.", "Human activity and warming change the cycle's balance."],
            challenges: challenges,
            discussionPrompts: ["Where does the water from your home's tap come from?", "Walk around your school after rain. Where does the water go?", "What is one change your community could make to protect its water?"])
    }

    static func waterCycleRemediations(chapter: Int, round: Int) -> [Remediation] {
        var list: [Remediation] = []
        switch chapter {
        case 0:
            list.append(Remediation(approach: "Kitchen experiment",
                section: sec("Watch it happen in your kitchen",
                    "Boil a pot of water and hold a cold lid above it. The water **evaporates** into steam (vapor) from the heat. When the vapor hits the cold lid, it **condenses** into droplets that drip back down, like rain!\n\nYour kitchen just ran a tiny water cycle: heat makes water rise as vapor; cold turns it back into liquid.",
                    Illustration(kind: .waterCycle, caption: "The pot is the ocean, the lid is the cloud."), nil, adaptive: true),
                followUp: short("In the pot-and-lid experiment, which part acts like the Sun, and which acts like a cloud? Explain.",
                    answer: "The stove is like the Sun because it heats the water; the cold lid is like a cloud because vapor condenses there.",
                    hints: ["What supplies the heat?", "Where does vapor turn back into droplets?", "Match each to the real water cycle."],
                    solution: "The stove's heat plays the Sun (evaporation); the cold lid plays the cloud (condensation).",
                    rubric: [rub("You matched the heat source to the Sun", ["stove", "heat", "burner", "fire"]), rub("You matched the lid to a cloud", ["lid", "cloud", "condens", "droplet"])],
                    followUp: true)))
            list.append(Remediation(approach: "Molecule story",
                section: sec("A molecule's point of view",
                    "Imagine you're one water molecule in a lake. The Sun warms you up and you start jiggling faster and faster until you break free from your neighbors and float up as **vapor**. That's evaporation.\n\nHigh in the sky it's cold. You slow down and huddle with other molecules around a speck of dust. Now you're a tiny droplet in a cloud. That's condensation.",
                    Illustration(kind: .conceptCard, caption: "Energy changes the state", labels: ["Add energy: liquid → gas (evaporation)", "Remove energy: gas → liquid (condensation)", "Remove more: liquid → solid (freezing)"]), nil, adaptive: true),
                followUp: choice("A water molecule loses energy as it rises into cold air. What is most likely to happen?",
                    options: ["It condenses into a droplet", "It evaporates", "It disappears"],
                    answer: "It condenses into a droplet",
                    hints: ["Losing energy means slowing down.", "Slower molecules stick together.", "Gas to liquid is called…"],
                    solution: "Losing energy, vapor molecules slow and stick together, condensing into droplets.",
                    rubric: [rub("You linked losing energy to slowing down", ["slow", "energy", "cool", "cold"]), rub("You named condensation", ["condens", "droplet", "liquid"])],
                    misconceptions: ["It evaporates": "reversed-state-change", "It disappears": "matter-disappears"], followUp: true)))
        case 1:
            list.append(Remediation(approach: "Growing raindrops",
                section: sec("Bumper cars in the sky",
                    "Think of cloud droplets as tiny bumper cars. Most are so light they just float. But when two bump, they stick and become one bigger drop. Bigger drops fall a little faster, bump into more droplets, and grow even more.\n\nOnce a drop is about a million times bigger than a cloud droplet, the updraft can't hold it, and it falls as rain.",
                    Illustration(kind: .conceptCard, caption: "From droplet to raindrop", labels: ["Tiny droplets float", "Collisions merge them", "Bigger drops sweep up more", "Too heavy: they fall"]), nil, adaptive: true),
                followUp: short("Why do clouds that look dark and thick often bring rain?",
                    answer: "They hold lots of water and big drops that block light; droplets have merged into drops heavy enough to fall.",
                    hints: ["Why might a cloud look darker?", "More water and bigger drops block more sunlight.", "What happens when drops grow large?"],
                    solution: "Thick, dark clouds contain lots of water and large drops that block sunlight. Large drops are heavy enough to fall as rain.",
                    rubric: [rub("You connected darkness to lots of water", ["water", "thick", "block", "light", "droplets"]), rub("You explained drops falling", ["heavy", "big", "fall", "grow"])],
                    followUp: true)))
            list.append(Remediation(approach: "Temperature layers",
                section: sec("Follow the thermometer down",
                    "To predict precipitation, follow the temperature from the cloud to the ground.\n\n**Cold all the way:** snow.\n**Cold, then warm:** snow melts into rain.\n**Cold, warm, then cold near the ground:** melts, then refreezes into sleet.\n**Strong storm updrafts:** hail.",
                    Illustration(kind: .numberLine, caption: "Freezing point on the way down", params: ["value": 0.5], labels: ["0 °C"]), nil, adaptive: true),
                followUp: choice("The air is below freezing from the cloud all the way to the ground. What falls?",
                    options: ["Rain", "Snow", "Sleet"],
                    answer: "Snow",
                    hints: ["Does the ice ever melt?", "It stays frozen the whole way.", "Frozen crystals that never melt are…"],
                    solution: "If it's below freezing the whole way, ice crystals never melt, so it snows.",
                    rubric: [rub("You noted it never melts", ["never melt", "stays frozen", "frozen", "below freezing", "cold the whole"]), rub("You named snow", ["snow"])],
                    misconceptions: ["Sleet": "hail-sleet-confusion", "Rain": "ignored-temperature"], followUp: true)))
        default:
            list.append(Remediation(approach: "Sponge model",
                section: sec("The ground is a sponge",
                    "Pour water on a sponge: it soaks in. Pour water on a plate: it runs off the edge. Soil and grass act like the sponge, and pavement acts like the plate.\n\nWater that soaks into the sponge-like ground slowly fills up the **groundwater** below. Water running off the plate-like pavement rushes into drains and rivers.",
                    Illustration(kind: .conceptCard, caption: "Sponge vs plate", labels: ["Soil = sponge: infiltration", "Pavement = plate: runoff", "Sponge refills groundwater", "Plate feeds floods"]), nil, adaptive: true),
                followUp: short("Using the sponge-and-plate idea, explain why rain gardens help prevent floods.",
                    answer: "Rain gardens act like sponges, letting water soak into the ground instead of running off.",
                    hints: ["Is a rain garden more like a sponge or a plate?", "What does a sponge do with water?", "Less runoff means…"],
                    solution: "A rain garden's loose, planted soil soaks up water like a sponge, so less runs off into streets and drains.",
                    rubric: [rub("You compared it to a sponge", ["sponge", "soak", "absorb", "infiltrat"]), rub("You connected it to less runoff or flooding", ["less runoff", "runoff", "flood", "drain"])],
                    followUp: true)))
            list.append(Remediation(approach: "Bank account analogy",
                section: sec("Groundwater is a savings account",
                    "Think of an aquifer as a savings account. Rain soaking into the ground is a **deposit**. Pumping water from wells is a **withdrawal**.\n\nIf withdrawals are bigger than deposits for years, the balance, the water table, keeps dropping, even though it rains sometimes.",
                    Illustration(kind: .numberLine, caption: "Water table balance", params: ["value": 0.35], labels: ["Water table"]), nil, adaptive: true),
                followUp: short("A town pumps 10 units of groundwater a year but only 6 units soak back in. What happens over time, and what could the town do?",
                    answer: "The water table drops by 4 units a year; the town could pump less or increase infiltration.",
                    hints: ["Compare withdrawals to deposits.", "What's the yearly change?", "Name one way to lower withdrawals or raise deposits."],
                    solution: "The aquifer loses 4 units a year, so the water table falls. The town could conserve water, pump less, or build rain gardens to boost infiltration.",
                    rubric: [rub("You found the aquifer shrinks", ["drop", "falls", "lower", "shrink", "4", "four", "lose"]), rub("You proposed a solution", ["less", "conserve", "save", "rain garden", "infiltrat", "reduce"])],
                    followUp: true)))
        }
        return list
    }
}
