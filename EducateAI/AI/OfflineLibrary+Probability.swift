import Foundation

extension OfflineLibrary {

    static func pick(_ level: SkillLevel, _ b: String, _ i: String, _ a: String) -> String {
        switch level {
        case .beginner: return b
        case .intermediate: return i
        case .advanced: return a
        }
    }

    // MARK: - Chapters

    static func probabilityChapters(level: SkillLevel) -> [Chapter] {
        [probChapter1(level), probChapter2(level), probChapter3(level)]
    }

    static func probChapter1(_ level: SkillLevel) -> Chapter {
        var sections: [LessonSection] = []
        sections.append(sec("How likely is it?",
            "Every day you make guesses about the future. Will it rain? Will the bus be late? Will your favorite team win? **Probability** is the math of measuring how likely something is to happen.\n\nWe place every event on a scale from **0** to **1**. An event with probability 0 is **impossible**, like rolling a 7 on a normal six-sided die. An event with probability 1 is **certain**, like the sun rising tomorrow. Everything else falls somewhere in between, and an event with probability 1/2 is just as likely to happen as not.\n\n" + pick(level,
                "You can also say probabilities as percentages: 0 is 0%, 1/2 is 50% and 1 is 100%.",
                "We write the probability of an event A as **P(A)**. For any event, 0 ≤ P(A) ≤ 1. Probabilities can be written as fractions, decimals or percentages: 1/4 = 0.25 = 25%.",
                "Formally, P is a function that assigns each event A a number with 0 ≤ P(A) ≤ 1, where P(S) = 1 for the whole sample space S. These simple rules, called the Kolmogorov axioms, are enough to build all of probability theory."),
            Illustration(kind: .numberLine, caption: "Drag the marker: where does \"rain tomorrow\" sit on the likelihood scale?", params: ["value": 0.7], labels: ["Rain tomorrow"]),
            check("Which event has probability 0?", ["Flipping heads on a coin", "Rolling a 7 on a six-sided die", "The sun rising tomorrow"], 1, "A six-sided die only has the numbers 1 to 6, so rolling a 7 is impossible.")))
        sections.append(sec("Outcomes and the sample space",
            "An **outcome** is one possible result of an experiment. When you flip a coin, the outcomes are heads and tails. When you roll a die, the outcomes are 1, 2, 3, 4, 5 and 6.\n\nThe list of **all** possible outcomes is called the **sample space**. Writing out the sample space is the most important first step in almost every probability problem. If you forget an outcome, every answer after that will be wrong.\n\nAn **event** is a group of outcomes we care about. \"Rolling an even number\" is an event made of three outcomes: 2, 4 and 6.",
            Illustration(kind: .spinner, caption: "Spin it! Each of the four colors is one outcome in the sample space.", labels: ["Red", "Blue", "Green", "Yellow"]),
            check("What is the sample space for one roll of a six-sided die?", ["{1, 6}", "{1, 2, 3, 4, 5, 6}", "{even, odd, 6}"], 1, "The sample space lists every possible outcome exactly once.")))
        sections.append(sec("The probability formula",
            "When every outcome is **equally likely**, probability is simply counting:\n\n**Probability = number of favorable outcomes ÷ total number of outcomes**\n\nA fair coin has 2 equally likely outcomes, and 1 of them is heads, so P(heads) = 1/2. A die has 6 outcomes and only one is a 4, so P(rolling a 4) = 1/6. Rolling an even number has 3 favorable outcomes out of 6, so the probability is 3/6, which simplifies to 1/2.\n\n" + pick(level,
                "Watch out: just because there are two possibilities doesn't mean each is 50%. Winning the lottery either happens or it doesn't, but it is definitely not a 1/2 chance!",
                "The **complement** of A, written A′ or \"not A\", contains every outcome not in A. Since something must happen, P(not A) = 1 − P(A). The equally-likely trap: two possible results do not make each one 1/2 unless the outcomes are equally likely.",
                "Counting works only under the equally-likely assumption. For a biased coin with P(H) = 0.7, the sample space is still {H, T}, but the outcomes carry different weights. In general P(A) is the sum of the probabilities of the outcomes in A."),
            Illustration(kind: .fractionBar, caption: "3 favorable outcomes out of 6 total: rolling an even number", params: ["numerator": 3, "denominator": 6]),
            check("A bag has 2 red and 3 blue marbles. What is P(red)?", ["2/3", "2/5", "1/2"], 1, "There are 2 red marbles out of 5 total, so P(red) = 2/5.")))
        sections.append(sec("Experiments and the law of large numbers",
            "**Theoretical probability** comes from reasoning: a fair coin should land heads 1/2 of the time. **Experimental probability** comes from actually doing it: if you flip 20 times and get 13 heads, the experimental probability is 13/20.\n\nIn a small experiment, results can be surprisingly far from the theory. Getting 7 heads in 10 flips is not unusual at all. But as you flip more and more times, the share of heads gets closer and closer to 1/2. This is the **law of large numbers**.\n\nImportant: coins have no memory. After five heads in a row, the next flip is still 1/2 heads. Believing tails is \"due\" is called the **gambler's fallacy**. Try it yourself below and watch the line settle down as you add flips.",
            Illustration(kind: .coinFlip, caption: "Flip 1, 10 or 100 coins and watch the share of heads approach 1/2.", params: ["bias": 0.5]),
            check("A fair coin lands heads 5 times in a row. What is the probability the next flip is heads?", ["Less than 1/2, tails is due", "Exactly 1/2", "More than 1/2, heads is on a streak"], 1, "Each flip is independent. The coin has no memory, so it's still 1/2.")))

        var challenges: [Challenge] = []
        switch level {
        case .beginner:
            challenges.append(numeric("Sage spins a spinner with 4 equal sections: red, blue, green and yellow. What is the probability it lands on blue?",
                answer: "1/4",
                hints: ["Start by listing every color the spinner could land on.", "Count how many sections are blue, and how many sections there are in total.", "Put the blue count on top of a fraction and the total count on the bottom."],
                solution: "There are 4 equally likely sections and 1 of them is blue, so P(blue) = 1/4.",
                rubric: [rub("You counted the total number of outcomes", ["4", "four", "total", "sections", "outcomes", "all"]),
                         rub("You counted the favorable outcomes", ["1", "one", "blue", "favorable", "only"])],
                misconceptions: ["1/2": "equally-likely-fallacy", "4": "count-not-probability", "1/3": "part-to-part-ratio"]))
            challenges.append(numeric("A bag has 3 red marbles and 2 blue marbles. You reach in without looking. What is the probability you pick a red marble?",
                answer: "3/5",
                hints: ["How many marbles are in the bag altogether?", "Probability = favorable ÷ total. Which marbles are favorable here?", "You have 3 favorable marbles. Divide by the total you found."],
                solution: "There are 3 + 2 = 5 marbles in total and 3 are red, so P(red) = 3/5.",
                rubric: [rub("You found the total number of marbles", ["5", "five", "total", "altogether", "3+2", "3 + 2"]),
                         rub("You used the 3 red marbles as favorable outcomes", ["3", "three", "red", "favorable"]),
                         rub("You divided favorable by total", ["divide", "over", "out of", "/", "fraction"])],
                misconceptions: ["3/2": "part-to-part-ratio", "1/2": "equally-likely-fallacy", "2/5": "complement-confusion", "3": "count-not-probability"]))
            challenges.append(choice("Leo flips a fair coin 10 times and gets 7 heads. Which statement is true?",
                options: ["The coin must be unfair.", "This can happen with a fair coin, and with many more flips the share of heads would get closer to 1/2.", "The next flip is more likely to be tails to even things out."],
                answer: "This can happen with a fair coin, and with many more flips the share of heads would get closer to 1/2.",
                hints: ["Think about how much small experiments can vary.", "What does the law of large numbers say happens as you flip more times?", "Does a coin remember what it landed on before?"],
                solution: "Ten flips is a small experiment, so 7 heads is quite possible with a fair coin. As the number of flips grows, the experimental probability approaches 1/2. The coin has no memory, so tails is never \"due\".",
                rubric: [rub("You mentioned small samples can vary", ["small", "only 10", "few", "random", "vary", "chance", "luck"]),
                         rub("You referred to many trials or the law of large numbers", ["more flips", "many", "large", "law", "long run", "closer"]),
                         rub("You recognized coins have no memory", ["memory", "independent", "doesn't remember", "each flip", "still 1/2", "50"])],
                misconceptions: ["The coin must be unfair.": "small-sample-overreaction", "The next flip is more likely to be tails to even things out.": "gamblers-fallacy"]))
        case .intermediate:
            challenges.append(numeric("You roll a fair six-sided die. What is P(roll greater than 4)?",
                answer: "1/3",
                hints: ["Write out the sample space for one die.", "Which outcomes are strictly greater than 4? Be careful: is 4 included?", "Two outcomes are favorable. Divide by the size of the sample space and simplify."],
                solution: "The sample space is {1, 2, 3, 4, 5, 6}. Only 5 and 6 are greater than 4, so P = 2/6 = 1/3.",
                rubric: [rub("You listed or used the sample space of 6 outcomes", ["6", "six", "sample space", "1-6", "1 to 6", "outcomes"]),
                         rub("You identified 5 and 6 as favorable", ["5 and 6", "5,6", "5, 6", "two", "2 outcomes", "five and six"]),
                         rub("You simplified the fraction", ["simplif", "2/6", "reduce", "1/3"])],
                misconceptions: ["1/2": "included-boundary", "3/6": "included-boundary", "1/6": "single-outcome-only", "2": "count-not-probability"]))
            challenges.append(numeric("A bag holds 5 red, 3 blue and 2 green tokens. Find P(blue).",
                answer: "3/10",
                hints: ["Find the total number of tokens first.", "P(blue) = number of blue ÷ total.", "Three tokens are blue. How many are there altogether?"],
                solution: "Total = 5 + 3 + 2 = 10 tokens and 3 are blue, so P(blue) = 3/10.",
                rubric: [rub("You found the total of 10 tokens", ["10", "ten", "total", "5+3+2", "5 + 3 + 2"]),
                         rub("You used the 3 blue tokens", ["3", "three", "blue"])],
                misconceptions: ["1/3": "equally-likely-fallacy", "3/7": "part-to-part-ratio", "3": "count-not-probability"]))
            challenges.append(numeric("In an experiment, a coin was flipped 200 times and landed heads 112 times. What is the experimental probability of heads? (A fraction or decimal is fine.)",
                answer: "14/25",
                hints: ["Experimental probability uses what actually happened, not what should happen.", "Divide the number of heads observed by the number of flips.", "Compute 112 ÷ 200 and simplify."],
                solution: "Experimental P(heads) = 112/200 = 0.56 = 14/25. It differs from the theoretical 1/2 because of random variation.",
                rubric: [rub("You used the observed counts", ["112", "observed", "actual", "experiment", "happened"]),
                         rub("You divided by the total number of trials", ["200", "trials", "flips", "total", "divide"]),
                         rub("You distinguished experimental from theoretical", ["theoretical", "1/2", "0.5", "expected", "differ"])],
                misconceptions: ["1/2": "theoretical-vs-experimental", "0.5": "theoretical-vs-experimental", "112": "count-not-probability"]))
        case .advanced:
            challenges.append(numeric("Two fair coins are flipped. What is P(exactly one head)?",
                answer: "1/2",
                hints: ["List the sample space carefully, keeping track of which coin is which.", "Is HT the same outcome as TH? Think of a penny and a dime.", "There are 4 equally likely ordered outcomes. Count those with exactly one H."],
                solution: "Ordered sample space: {HH, HT, TH, TT}. Exactly one head occurs in HT and TH, so P = 2/4 = 1/2. Treating the outcomes as {0 heads, 1 head, 2 heads} gives the wrong answer 1/3 because those are not equally likely.",
                rubric: [rub("You listed four ordered outcomes", ["hh", "ht", "th", "tt", "4", "four", "ordered"]),
                         rub("You counted HT and TH separately", ["ht and th", "both orders", "two ways", "2 ways", "either coin", "distinct"]),
                         rub("You noted unordered outcomes are not equally likely", ["not equally", "equally likely", "unordered", "1/3"])],
                misconceptions: ["1/3": "unordered-sample-space", "1/4": "single-outcome-only"]))
            challenges.append(numeric("Three fair coins are flipped. What is P(at least one head)?",
                answer: "7/8",
                hints: ["\"At least one\" problems are often easier through the complement.", "What is the only outcome with zero heads? What is its probability?", "Subtract P(no heads) from 1."],
                solution: "There are 2³ = 8 equally likely outcomes. Only TTT has no heads, so P(at least one head) = 1 − 1/8 = 7/8.",
                rubric: [rub("You used the complement", ["complement", "1 -", "1 −", "1-", "not", "none", "no heads", "opposite"]),
                         rub("You found 8 total outcomes", ["8", "eight", "2^3", "2³", "2*2*2"]),
                         rub("You identified TTT as the only failure", ["ttt", "all tails", "only one", "zero heads"])],
                misconceptions: ["3/8": "exactly-instead-of-at-least", "1/2": "equally-likely-fallacy", "3/2": "added-probabilities", "1/8": "complement-confusion"]))
            challenges.append(numeric("A spinner landed on red 45 times in 120 spins. Using this experimental probability, how many times would you expect red in 400 spins?",
                answer: "150",
                hints: ["First find the experimental probability of red.", "Expected count = probability × number of trials.", "45/120 simplifies nicely. Multiply it by 400."],
                solution: "Experimental P(red) = 45/120 = 3/8. Expected count in 400 spins = 3/8 × 400 = 150.",
                rubric: [rub("You found the experimental probability", ["45/120", "3/8", "0.375", "experimental"]),
                         rub("You multiplied by the number of trials", ["400", "multiply", "×", "*", "times"])],
                misconceptions: ["3/8": "probability-not-count", "325": "added-instead-of-scaled"]))
        }

        return Chapter(index: 0, title: "What Is Probability?", summary: "Measure chance on a scale from 0 to 1, list outcomes, and see why experiments settle down over time.",
            locationName: "Coin Grove", theme: .grove,
            npc: NPC(name: "Penny the Fox", role: "Guardian of Coin Grove", greeting: "Heads or tails? Before you guess, tell me how you'd figure out the chances!", emoji: "🦊"),
            sections: sections,
            keyIdeas: ["Probability measures likelihood on a scale from 0 (impossible) to 1 (certain).", "The sample space lists every possible outcome.", "With equally likely outcomes, P = favorable ÷ total.", "Experimental probability approaches theoretical probability as trials grow (law of large numbers).", "Coins and dice have no memory: past results don't change future chances."],
            challenges: challenges,
            discussionPrompts: ["Where did you hear someone use probability this week, like a weather forecast or a sports commentator?", "Flip a real coin 20 times with a partner. How close did you get to 1/2? Why might you be off?", "Why do people believe in \"lucky streaks\"? What would you tell them?"])
    }

    static func probChapter2(_ level: SkillLevel) -> Chapter {
        var sections: [LessonSection] = []
        sections.append(sec("Rolling two dice",
            "When you roll two dice, it's tempting to think every sum from 2 to 12 is equally likely. It isn't! There are **36** equally likely outcomes, because each of the 6 faces on the first die can pair with each of the 6 faces on the second die (6 × 6 = 36).\n\nA sum of 2 can only happen one way: (1, 1). But a sum of 7 can happen **six** ways: (1,6), (2,5), (3,4), (4,3), (5,2) and (6,1). That's why 7 is the most common sum, with probability 6/36 = 1/6.\n\nThink of the two dice as different colors, say a red die and a blue die. Then (3, 4) and (4, 3) are clearly different outcomes.",
            Illustration(kind: .diceRoll, caption: "Roll two dice many times. Which sums show up most often?", params: ["dice": 2]),
            check("How many equally likely outcomes are there when you roll two dice?", ["12", "36", "11"], 1, "6 faces on the first die × 6 faces on the second = 36 outcomes.")))
        sections.append(sec("Independent events",
            "Two events are **independent** when one happening doesn't change the chance of the other. Flipping a coin and rolling a die are independent: the coin has no idea what the die did.\n\nTo find the probability that two independent events **both** happen, **multiply** their probabilities. The chance of heads and a 6 is 1/2 × 1/6 = 1/12. You can check this by counting: there are 2 × 6 = 12 coin-and-die outcomes, and only one of them is (heads, 6).\n\n" + pick(level,
                "A tree diagram helps: each branch splits into the next event's outcomes, and you multiply along the branches.",
                "The **multiplication rule** for independent events: P(A and B) = P(A) × P(B). A tree diagram shows why: each branch splits, and you multiply along a path.",
                "A and B are independent exactly when P(A ∩ B) = P(A)·P(B). This is a definition you can test. Some events that sound related turn out to be independent, and some that sound unrelated are not."),
            Illustration(kind: .probabilityTree, caption: "Two coin flips: multiply along each path.", params: ["p": 0.5, "stages": 2], labels: ["Heads", "Tails"]),
            check("You flip a coin twice. What is P(heads, then heads)?", ["1/2", "1/4", "1"], 1, "The flips are independent, so 1/2 × 1/2 = 1/4.")))
        sections.append(sec("The complement trick",
            "Sometimes it's easier to find the chance something **doesn't** happen. Since an event either happens or doesn't, these two probabilities always add up to 1:\n\n**P(not A) = 1 − P(A)**\n\nThe chance of not rolling a 6 is 1 − 1/6 = 5/6. This trick is powerful for \"at least one\" questions. Instead of counting every way to get at least one six in two rolls, find the chance of **no** sixes (5/6 × 5/6 = 25/36) and subtract from 1. The answer is 11/36.\n\nAdding 1/6 + 1/6 = 2/6 would be wrong, because it counts the outcome (6, 6) twice.",
            Illustration(kind: .fractionBar, caption: "5 of 6 faces are \"not a six\"", params: ["numerator": 5, "denominator": 6]),
            check("P(rain) = 0.3. What is P(no rain)?", ["0.3", "0.7", "1.3"], 1, "P(not A) = 1 − 0.3 = 0.7.")))

        var challenges: [Challenge] = []
        switch level {
        case .beginner:
            challenges.append(numeric("You roll one fair die. What is the probability of rolling an even number?",
                answer: "1/2",
                hints: ["Which numbers on a die are even?", "Count the even numbers, then count all the numbers on the die.", "Write it as a fraction and see if it simplifies."],
                solution: "The even numbers are 2, 4 and 6: that's 3 out of 6 outcomes. P(even) = 3/6 = 1/2.",
                rubric: [rub("You identified 2, 4 and 6", ["2, 4", "2,4", "2 4 6", "2, 4, 6", "three", "3 even"]),
                         rub("You used 6 total outcomes", ["6", "six", "total", "outcomes"])],
                misconceptions: ["1/6": "single-outcome-only", "3": "count-not-probability", "1/3": "miscounted-favorable"]))
            challenges.append(numeric("You roll two dice and add them. What is the probability the sum is 7?",
                answer: "1/6",
                hints: ["How many outcomes are there for two dice altogether?", "List pairs (first die, second die) that add to 7. Remember (1,6) and (6,1) are different.", "You should find 6 pairs. Divide by the total number of outcomes."],
                solution: "There are 36 outcomes. Sums of 7: (1,6), (2,5), (3,4), (4,3), (5,2), (6,1), which is 6 outcomes. P = 6/36 = 1/6.",
                rubric: [rub("You used 36 total outcomes", ["36", "thirty-six", "6x6", "6 x 6", "6*6", "6 × 6"]),
                         rub("You listed the pairs that make 7", ["1,6", "1 and 6", "(1,6)", "pairs", "six ways", "6 ways"]),
                         rub("You counted both orders", ["order", "both ways", "different", "6,1", "reverse"])],
                misconceptions: ["1/11": "sums-equally-likely", "1/12": "sums-equally-likely", "3/36": "ignored-order"]))
            challenges.append(numeric("You flip a coin and roll a die. What is the probability of getting heads AND a 6?",
                answer: "1/12",
                hints: ["Do the coin and the die affect each other?", "When two independent things both need to happen, multiply their chances.", "P(heads) is 1/2 and P(6) is 1/6. What is their product?"],
                solution: "The events are independent, so P(heads and 6) = 1/2 × 1/6 = 1/12. Counting checks it: 12 outcomes, one is (heads, 6).",
                rubric: [rub("You recognized the events are independent", ["independent", "don't affect", "doesn't affect", "separate", "no effect"]),
                         rub("You multiplied the probabilities", ["multiply", "×", "*", "times", "1/2 x 1/6", "12 outcomes"])],
                misconceptions: ["2/3": "added-instead-of-multiplied", "1/8": "added-outcome-counts", "1/6": "ignored-second-event"]))
        case .intermediate:
            challenges.append(numeric("Two dice are rolled. Find P(sum = 8).",
                answer: "5/36",
                hints: ["There are 36 equally likely ordered outcomes.", "List ordered pairs summing to 8, starting with (2, 6).", "You should get 5 pairs, since (4,4) only counts once."],
                solution: "Pairs: (2,6), (3,5), (4,4), (5,3), (6,2). That's 5 of 36, so P = 5/36.",
                rubric: [rub("You used 36 outcomes", ["36", "6x6", "6 × 6", "6*6"]),
                         rub("You listed the ordered pairs", ["2,6", "(2,6)", "pairs", "5 ways", "five"]),
                         rub("You counted (4,4) once", ["4,4", "once", "double"])],
                misconceptions: ["1/11": "sums-equally-likely", "6/36": "double-counted-doubles", "1/6": "double-counted-doubles", "3/36": "ignored-order"]))
            challenges.append(numeric("A die is rolled twice. Find P(no sixes in either roll).",
                answer: "25/36",
                hints: ["First find P(not 6) on a single roll using the complement.", "The two rolls are independent. What rule combines them?", "Multiply 5/6 by itself."],
                solution: "P(not 6) = 5/6 for each roll. The rolls are independent, so P(no sixes) = 5/6 × 5/6 = 25/36.",
                rubric: [rub("You used the complement for one roll", ["5/6", "complement", "1 - 1/6", "1 − 1/6", "not 6"]),
                         rub("You multiplied for independent rolls", ["multiply", "×", "*", "independent", "squared", "^2"])],
                misconceptions: ["2/3": "added-or-subtracted-probabilities", "4/6": "added-or-subtracted-probabilities", "5/6": "ignored-second-event", "10/36": "added-instead-of-multiplied"]))
            challenges.append(numeric("Two dice are rolled. Find P(both dice show the same number).",
                answer: "1/6",
                hints: ["How many 'doubles' are there, like (1,1)?", "There is one double for each face of the die.", "Divide the number of doubles by 36."],
                solution: "The doubles are (1,1) through (6,6): 6 outcomes out of 36, so P = 6/36 = 1/6. Equivalently, whatever the first die shows, the second must match it with probability 1/6.",
                rubric: [rub("You counted 6 doubles", ["6 doubles", "six", "(1,1)", "1,1", "doubles"]),
                         rub("You used 36 outcomes or matching reasoning", ["36", "match", "first die", "whatever"])],
                misconceptions: ["1/36": "single-outcome-only", "1/12": "sums-equally-likely"]))
        case .advanced:
            challenges.append(numeric("A fair die is rolled four times. Find P(at least one 6). Give a fraction or a decimal to 3 places.",
                answer: "671/1296",
                hints: ["\"At least one\" suggests the complement.", "Find P(no sixes in four independent rolls).", "Compute 1 − (5/6)⁴."],
                solution: "P(no sixes) = (5/6)⁴ = 625/1296. So P(at least one 6) = 1 − 625/1296 = 671/1296 ≈ 0.518. This is the famous de Méré problem: it's slightly better than even.",
                rubric: [rub("You used the complement", ["complement", "1 -", "1 −", "1-", "no sixes", "none"]),
                         rub("You raised 5/6 to the 4th power", ["(5/6)^4", "5/6)^4", "(5/6)⁴", "625", "four times", "^4"]),
                         rub("You relied on independence", ["independent", "multiply"])],
                misconceptions: ["2/3": "added-probabilities", "4/6": "added-probabilities", "625/1296": "forgot-to-subtract-complement", "1/1296": "all-sixes-confusion"]))
            challenges.append(numeric("Two dice are rolled. Find P(sum ≥ 10).",
                answer: "1/6",
                hints: ["Break it into sums 10, 11 and 12.", "Count ordered pairs for each sum separately.", "You should get 3 + 2 + 1 outcomes."],
                solution: "Sum 10: (4,6), (5,5), (6,4) = 3. Sum 11: (5,6), (6,5) = 2. Sum 12: (6,6) = 1. Total 6/36 = 1/6.",
                rubric: [rub("You split into cases 10, 11, 12", ["10, 11", "10,11", "11", "12", "cases"]),
                         rub("You counted ordered pairs", ["4,6", "(4,6)", "pairs", "3 + 2 + 1", "3+2+1", "6 outcomes"]),
                         rub("You divided by 36", ["36"])],
                misconceptions: ["3/11": "sums-equally-likely", "1/12": "missed-cases"]))
            challenges.append(choice("A die is rolled twice. Let A = \"first roll is 6\" and B = \"the sum is 7\". Are A and B independent?",
                options: ["Yes, because P(A and B) = P(A) × P(B).", "No, because the sum depends on the first roll.", "It cannot be determined without more rolls."],
                answer: "Yes, because P(A and B) = P(A) × P(B).",
                hints: ["Don't trust intuition. Test the definition of independence.", "Find P(A), P(B), and P(A and B) separately by counting from 36 outcomes.", "Only (6,1) is in both events. Compare 1/36 with P(A) × P(B)."],
                solution: "P(A) = 6/36 = 1/6. P(B) = 6/36 = 1/6. A and B together is only (6,1), so P(A ∩ B) = 1/36 = 1/6 × 1/6. The definition holds, so they're independent, surprising as it sounds. (With sum = 8 instead, they would not be.)",
                rubric: [rub("You computed P(A) and P(B)", ["1/6", "p(a)", "p(b)", "6/36"]),
                         rub("You found P(A and B) = 1/36", ["1/36", "(6,1)", "6,1", "only one"]),
                         rub("You compared with the product", ["product", "multiply", "×", "*", "equal", "definition"])],
                misconceptions: ["No, because the sum depends on the first roll.": "intuition-over-definition"]))
        }

        return Chapter(index: 1, title: "Dice and Combining Events", summary: "Discover why 7 is the luckiest sum, multiply independent chances, and use the complement trick.",
            locationName: "Dice Tower", theme: .tower,
            npc: NPC(name: "Professor Pip", role: "Keeper of Dice Tower", greeting: "Ah, a visitor! Two dice, thirty-six possibilities. Shall we see which sums the tower favors?", emoji: "🦉"),
            sections: sections,
            keyIdeas: ["Two dice have 6 × 6 = 36 equally likely ordered outcomes.", "Sums are not equally likely: 7 is most common (6/36).", "For independent events, P(A and B) = P(A) × P(B).", "P(not A) = 1 − P(A).", "\"At least one\" is often easiest as 1 − P(none)."],
            challenges: challenges,
            discussionPrompts: ["Why do many board games use two dice instead of one 12-sided die? How does it change the game?", "Explain to a friend why (3,4) and (4,3) are different outcomes.", "Think of two events in daily life that are independent, and two that are not."])
    }

    static func probChapter3(_ level: SkillLevel) -> Chapter {
        var sections: [LessonSection] = []
        sections.append(sec("Meet the deck",
            "A standard deck has **52 cards** in **4 suits**: hearts ♥ and diamonds ♦ (red), clubs ♣ and spades ♠ (black). Each suit has 13 ranks: A, 2–10, J, Q and K. So there are 4 of each rank, and 13 of each suit.\n\nThat structure makes cards perfect for probability. P(heart) = 13/52 = 1/4. P(king) = 4/52 = 1/13. P(red card) = 26/52 = 1/2. Picture face cards: jacks, queens and kings, 3 per suit, so 12 in total.",
            Illustration(kind: .cardDraw, caption: "Shuffle and draw. Try drawing with and without putting cards back."),
            check("How many kings are in a standard deck?", ["1", "4", "13"], 1, "There is one king in each of the 4 suits.")))
        sections.append(sec("Without replacement: the deck remembers",
            "Coins and dice have no memory, but a deck does! If you draw a card and **don't put it back**, the next draw comes from a smaller deck. These are **dependent** events.\n\nThe chance of drawing two hearts in a row without replacement: the first heart is 13/52. Now only 12 hearts remain in 51 cards, so the second is 12/51. Multiply: 13/52 × 12/51 = 1/17. With replacement it would be 1/4 × 1/4 = 1/16, a little higher.\n\nThe same idea works for marbles in a bag, names drawn from a hat, or picking team members.\n\n" + pick(level,
                "A good habit: after each draw, rewrite how many of each thing are left before you compute the next chance.",
                "We write the probability of B **given** A as **P(B | A)**. The general multiplication rule is P(A and B) = P(A) × P(B | A).",
                "Conditional probability is defined as P(B | A) = P(A ∩ B) / P(A). Rearranging gives the general multiplication rule, which chains: P(A ∩ B ∩ C) = P(A)·P(B | A)·P(C | A ∩ B)."),
            Illustration(kind: .probabilityTree, caption: "Draw twice without replacement from 3 red and 2 blue: the second branch changes.", params: ["p": 0.6, "stages": 2], labels: ["Red", "Blue"]),
            check("You draw one card, a heart, and keep it. How many hearts are left in the deck?", ["13", "12", "51"], 1, "One heart is gone, so 12 of the original 13 remain.")))
        sections.append(sec("Or: overlapping events",
            "What is P(king **or** heart)? It's tempting to add 4/52 + 13/52 = 17/52, but the king of hearts got counted **twice**, once as a king and once as a heart. Subtract the overlap:\n\n**P(A or B) = P(A) + P(B) − P(A and B)**\n\nSo P(king or heart) = 4/52 + 13/52 − 1/52 = 16/52 = 4/13. A Venn diagram makes the overlap easy to see.",
            Illustration(kind: .venn, caption: "Kings and hearts overlap in exactly one card.", params: ["a": 3, "b": 12, "both": 1, "neither": 36], labels: ["Kings", "Hearts"]),
            check("Why do we subtract P(A and B) when finding P(A or B)?", ["It was counted twice", "It's impossible", "To make the answer smaller"], 0, "Outcomes in the overlap belong to both A and B, so adding counts them twice.")))
        if level != .beginner {
            sections.append(sec("Expected value: what happens on average",
                "Probability tells us how often; **expected value** tells us what we gain on average. Multiply each outcome's value by its probability and add them up.\n\nSuppose you draw a card: win $4 for a heart, lose $1 otherwise. Expected value = 4 × 1/4 + (−1) × 3/4 = 1 − 0.75 = $0.25 per game. Over many games you'd gain about a quarter each time, even though you lose most individual games.\n\n" + pick(level, "", "Casinos design every game so the expected value is negative for the player.", "E[X] = Σ x·P(X = x). Expected value is linear: E[X + Y] = E[X] + E[Y], even when X and Y are dependent."),
                Illustration(kind: .conceptCard, caption: "Computing expected value", labels: ["List each possible outcome", "Give each a value (+ win, − loss)", "Multiply value × probability", "Add the results"])))
        }

        var challenges: [Challenge] = []
        switch level {
        case .beginner:
            challenges.append(numeric("You draw one card from a shuffled deck of 52. What is the probability it's a heart?",
                answer: "1/4",
                hints: ["How many suits are there, and how many cards in each?", "Count the hearts and the total number of cards.", "13 hearts out of 52 cards. Can that fraction be simplified?"],
                solution: "There are 13 hearts among 52 cards, so P(heart) = 13/52 = 1/4.",
                rubric: [rub("You used 13 hearts", ["13", "thirteen"]),
                         rub("You used 52 cards total", ["52", "fifty-two", "deck", "total"]),
                         rub("You simplified or used the 4 suits", ["4 suits", "four suits", "1/4", "simplif", "quarter"])],
                misconceptions: ["1/13": "rank-suit-confusion", "1/52": "single-card-only", "13": "count-not-probability"]))
            challenges.append(numeric("What is the probability of drawing a king from a full deck?",
                answer: "1/13",
                hints: ["How many kings are there? One per suit.", "Favorable ÷ total.", "4 out of 52. Simplify."],
                solution: "There are 4 kings in 52 cards: 4/52 = 1/13.",
                rubric: [rub("You counted 4 kings", ["4", "four", "one per suit", "each suit"]),
                         rub("You used 52 cards", ["52", "deck", "total"])],
                misconceptions: ["1/4": "rank-suit-confusion", "1/52": "single-card-only"]))
            challenges.append(numeric("A bag has 3 red and 2 blue marbles. You pick one, keep it, then pick another. What is the probability both are red?",
                answer: "3/10",
                hints: ["What's the chance the first marble is red?", "After taking out a red marble, how many red marbles and total marbles are left?", "Multiply 3/5 by the new chance for the second draw (2 red out of 4)."],
                solution: "First red: 3/5. Then 2 red remain among 4 marbles: 2/4. Both red: 3/5 × 2/4 = 6/20 = 3/10.",
                rubric: [rub("You found 3/5 for the first draw", ["3/5", "3 out of 5", "first"]),
                         rub("You updated the bag for the second draw", ["2/4", "2 red", "4 left", "4 marbles", "one less", "fewer", "without"]),
                         rub("You multiplied", ["multiply", "×", "*", "times"])],
                misconceptions: ["9/25": "forgot-without-replacement", "6/5": "added-probabilities", "1/5": "subtracted-probabilities", "3/5": "ignored-second-event"]))
        case .intermediate:
            challenges.append(numeric("Find P(king or heart) when drawing one card from a standard deck.",
                answer: "4/13",
                hints: ["Find P(king) and P(heart) separately.", "Is any card both a king and a heart?", "Use P(A or B) = P(A) + P(B) − P(A and B)."],
                solution: "P(king) = 4/52, P(heart) = 13/52, P(king of hearts) = 1/52. P = (4 + 13 − 1)/52 = 16/52 = 4/13.",
                rubric: [rub("You found P(king) and P(heart)", ["4/52", "13/52", "1/13", "1/4"]),
                         rub("You subtracted the overlap", ["subtract", "overlap", "king of hearts", "both", "counted twice", "- 1/52", "−1/52"])],
                misconceptions: ["17/52": "double-counted-overlap", "1/52": "and-instead-of-or", "1/4": "ignored-first-event"]))
            challenges.append(numeric("Two cards are drawn without replacement. Find P(both are aces).",
                answer: "1/221",
                hints: ["P(first ace) = 4/52.", "After one ace is drawn, how many aces and cards remain?", "Multiply 4/52 × 3/51 and simplify."],
                solution: "P = 4/52 × 3/51 = 12/2652 = 1/221.",
                rubric: [rub("You used 4/52 for the first draw", ["4/52", "1/13"]),
                         rub("You used 3/51 for the second draw", ["3/51", "1/17", "51", "without replacement", "remaining"]),
                         rub("You multiplied the conditional probabilities", ["multiply", "×", "*", "p(b | a)", "p(b|a)", "given"])],
                misconceptions: ["1/169": "forgot-without-replacement", "2/13": "added-probabilities", "8/52": "added-probabilities"]))
            challenges.append(numeric("A card is drawn and you're told it's a face card (J, Q or K). What is P(it's a king | face card)?",
                answer: "1/3",
                hints: ["The condition shrinks the sample space. How many face cards are there?", "Among those face cards, how many are kings?", "Divide kings by face cards."],
                solution: "There are 12 face cards and 4 are kings. P(king | face) = 4/12 = 1/3.",
                rubric: [rub("You reduced the sample space to 12 face cards", ["12", "twelve", "face cards", "given", "sample space"]),
                         rub("You counted 4 kings", ["4 kings", "4", "four"])],
                misconceptions: ["1/13": "ignored-condition", "4/52": "ignored-condition", "3/13": "and-instead-of-given"]))
        case .advanced:
            challenges.append(numeric("Two cards are drawn without replacement. Find P(at least one ace). Give a fraction or decimal to 3 places.",
                answer: "33/221",
                hints: ["Use the complement: what is P(no aces)?", "P(no aces) = 48/52 × 47/51.", "Subtract from 1 and simplify."],
                solution: "P(no aces) = 48/52 × 47/51 = 2256/2652 = 188/221. P(at least one) = 1 − 188/221 = 33/221 ≈ 0.149.",
                rubric: [rub("You used the complement", ["complement", "1 -", "1 −", "1-", "no aces", "none"]),
                         rub("You used 48/52 and 47/51", ["48/52", "47/51", "48", "47"]),
                         rub("You accounted for no replacement", ["without", "51", "remaining", "dependent"])],
                misconceptions: ["2/13": "added-probabilities", "8/52": "added-probabilities", "25/169": "forgot-without-replacement", "188/221": "forgot-to-subtract-complement"]))
            challenges.append(numeric("A game: draw one card. Win $10 if it's a heart; otherwise lose $2. What is the expected value of one game in dollars?",
                answer: "1",
                hints: ["List outcomes with their values and probabilities.", "Heart: +10 with probability 1/4. Not heart: −2 with probability 3/4.", "Compute 10 × 1/4 + (−2) × 3/4."],
                solution: "E = 10 × 1/4 − 2 × 3/4 = 2.5 − 1.5 = $1 per game.",
                rubric: [rub("You weighted each outcome by its probability", ["1/4", "3/4", "0.25", "0.75", "probability"]),
                         rub("You treated the loss as negative", ["-2", "−2", "negative", "lose", "minus"]),
                         rub("You added the weighted values", ["add", "sum", "+", "2.5", "1.5"])],
                misconceptions: ["8": "ignored-probabilities", "2.5": "ignored-losses", "4": "averaged-values"]))
            challenges.append(numeric("The first card drawn was a heart and was not replaced. Find P(the second card is a heart | first was a heart).",
                answer: "4/17",
                hints: ["The first heart is gone. How many cards remain?", "How many hearts remain?", "Divide 12 by 51 and simplify."],
                solution: "51 cards remain and 12 are hearts. P = 12/51 = 4/17 ≈ 0.235.",
                rubric: [rub("You updated the deck to 51 cards", ["51", "fifty-one", "remaining", "left"]),
                         rub("You updated hearts to 12", ["12", "twelve"])],
                misconceptions: ["1/4": "forgot-without-replacement", "13/51": "forgot-to-remove-favorable", "1/17": "joint-instead-of-conditional"]))
        }

        return Chapter(index: 2, title: "Cards and Dependent Events", summary: "Explore the 52-card deck, see how probabilities change without replacement, and handle overlapping events.",
            locationName: "Card Castle", theme: .castle,
            npc: NPC(name: "Queen Clara", role: "Ruler of Card Castle", greeting: "Welcome to my court. In this castle, every card drawn changes the deck. Can you keep track?", emoji: "👑"),
            sections: sections,
            keyIdeas: ["A deck has 52 cards: 4 suits × 13 ranks.", "Without replacement, later probabilities change: events are dependent.", "P(A and B) = P(A) × P(B | A).", "P(A or B) = P(A) + P(B) − P(A and B).", "Expected value averages outcomes weighted by probability."],
            challenges: challenges,
            discussionPrompts: ["Where in real life do things happen \"without replacement\", like choosing teams or raffle drawings?", "Why might a casino game feel fair even when its expected value is negative?", "Draw a Venn diagram of two activities your classmates do. What's in the overlap?"])
    }

    // MARK: - Remediation

    static func probabilityRemediations(chapter: Int, round: Int) -> [Remediation] {
        var list: [Remediation] = []
        switch chapter {
        case 0:
            list.append(Remediation(approach: "Visual analogy",
                section: sec("Think of it as pizza",
                    "Imagine a pizza cut into equal slices. If the pizza has 8 slices and 3 have pepperoni, then if you grab a slice without looking, the chance it has pepperoni is **3 out of 8**, or 3/8.\n\nThat's all probability is: **the slices you want over all the slices**. The key word is *equal*. Every slice must be the same size, which is what \"equally likely\" means.\n\nSpin the spinner below. Count how many sections are the color you want, and how many sections there are altogether.",
                    Illustration(kind: .spinner, caption: "Each equal slice is one outcome.", labels: ["Pepperoni", "Cheese", "Pepperoni", "Cheese", "Cheese", "Pepperoni", "Cheese", "Cheese"]), nil, adaptive: true),
                followUp: numeric("A spinner has 8 equal slices. 3 are pepperoni and 5 are cheese. What is the probability of landing on pepperoni?",
                    answer: "3/8",
                    hints: ["How many slices are there in total?", "How many of those are pepperoni?", "Put pepperoni slices over total slices."],
                    solution: "3 pepperoni slices out of 8 equal slices: P = 3/8.",
                    rubric: [rub("You counted all 8 slices", ["8", "eight", "total", "all"]), rub("You used 3 pepperoni slices", ["3", "three", "pepperoni"])],
                    misconceptions: ["3/5": "part-to-part-ratio", "1/2": "equally-likely-fallacy", "5/8": "complement-confusion"], followUp: true)))
            list.append(Remediation(approach: "Worked example",
                section: sec("Step by step: a jar of marbles",
                    "Let's work one together. A jar holds 2 green and 6 yellow marbles. What's P(yellow)?\n\n**Step 1: Count everything.** 2 + 6 = 8 marbles in total. This is the bottom of the fraction.\n\n**Step 2: Count what you want.** 6 yellow marbles. This is the top.\n\n**Step 3: Write and simplify.** 6/8 = 3/4.\n\nA common mistake is writing 6/2, comparing yellow with green. That compares one part with another part. Probability always compares a part with the **whole**.",
                    Illustration(kind: .fractionBar, caption: "6 yellow out of 8 total marbles", params: ["numerator": 6, "denominator": 8]), nil, adaptive: true),
                followUp: numeric("A jar holds 4 green and 6 yellow marbles. What is P(green)?",
                    answer: "2/5",
                    hints: ["Step 1: count all the marbles.", "Step 2: count the green ones.", "Step 3: write green ÷ total and simplify."],
                    solution: "Total = 10. Green = 4. P(green) = 4/10 = 2/5.",
                    rubric: [rub("You counted the whole jar", ["10", "ten", "total", "4+6", "4 + 6"]), rub("You used 4 green marbles", ["4", "four", "green"])],
                    misconceptions: ["4/6": "part-to-part-ratio", "2/3": "part-to-part-ratio", "3/5": "complement-confusion"], followUp: true)))
            let r = 2 + (round % 4), b = 3 + 2 * (round % 3)
            list.append(Remediation(approach: "Real-world story",
                section: sec("The raffle at the fair",
                    "At a school fair, every ticket in the raffle drum has the same chance of being drawn. If you buy more tickets, your chance goes up, but it's always **your tickets over all the tickets**.\n\nWhen you see a probability question, try retelling it as a raffle: what are \"your tickets\" (favorable outcomes) and what are \"all the tickets\" (the total)?",
                    Illustration(kind: .conceptCard, caption: "Turn any question into a raffle", labels: ["Your tickets = favorable outcomes", "All tickets = total outcomes", "Your chance = yours ÷ all", "Simplify if you can"]), nil, adaptive: true),
                followUp: numeric("At the fair, you hold \(r) raffle tickets and your friends hold \(b) other tickets. Those are all the tickets. What is the chance one of yours is drawn?",
                    answer: frac(r, r + b),
                    hints: ["How many tickets are in the drum altogether?", "Which tickets are 'favorable' for you?", "Your tickets ÷ all tickets."],
                    solution: "Total tickets = \(r + b). Yours = \(r). P = \(r)/\(r + b) = \(frac(r, r + b)).",
                    rubric: [rub("You found the total number of tickets", ["\(r + b)", "total", "all", "altogether"]), rub("You used your tickets as favorable", ["\(r)", "my tickets", "mine", "favorable"])],
                    misconceptions: ["\(r)/\(b)": "part-to-part-ratio", "1/2": "equally-likely-fallacy"], followUp: true)))
        case 1:
            list.append(Remediation(approach: "Grid picture",
                section: sec("See all 36 outcomes at once",
                    "Picture a 6 × 6 grid. The rows are the red die (1 to 6) and the columns are the blue die (1 to 6). Every square is one outcome, so there are 36 squares.\n\nNow look along the diagonals: all squares with the same sum line up. The sum 7 runs corner to corner with **6** squares. The sum 2 is a single square in the corner. That's why sums are not equally likely.\n\nTo find P(sum), count the squares on that diagonal and put the count over 36.",
                    Illustration(kind: .diceRoll, caption: "Roll many times and compare the bars with the grid count.", params: ["dice": 2]), nil, adaptive: true),
                followUp: numeric("Two dice are rolled. Using the grid idea, what is P(sum = 4)?",
                    answer: "1/12",
                    hints: ["Find squares where red + blue = 4.", "Start with red = 1. What must blue be? Then red = 2, red = 3.", "Count the squares and divide by 36."],
                    solution: "(1,3), (2,2), (3,1): 3 squares. P = 3/36 = 1/12.",
                    rubric: [rub("You listed the pairs", ["1,3", "(1,3)", "2,2", "3,1", "three"]), rub("You divided by 36", ["36"])],
                    misconceptions: ["1/11": "sums-equally-likely", "2/36": "ignored-order", "1/18": "ignored-order"], followUp: true)))
            list.append(Remediation(approach: "Tree diagram",
                section: sec("Walk along the branches",
                    "When two things happen one after another, draw a tree. The first split shows the first event's outcomes. From each branch, split again for the second event.\n\nFor a coin then a 4-color spinner, the coin splits into H and T (1/2 each). Each of those splits into 4 colors (1/4 each). There are 2 × 4 = 8 paths. To get the probability of one path, **multiply along it**: 1/2 × 1/4 = 1/8.\n\nAdding would be a mistake. Adding gives a number bigger than either chance, but needing **both** things to happen should make it less likely, not more.",
                    Illustration(kind: .probabilityTree, caption: "Multiply along a path.", params: ["p": 0.5, "stages": 2], labels: ["Heads", "Tails"]), nil, adaptive: true),
                followUp: numeric("You flip a coin and spin a spinner with 4 equal colors (red, blue, green, yellow). What is P(tails and blue)?",
                    answer: "1/8",
                    hints: ["What is P(tails)? What is P(blue)?", "Both must happen. Multiply or add?", "Multiply 1/2 by 1/4."],
                    solution: "P(tails) = 1/2 and P(blue) = 1/4. They're independent: 1/2 × 1/4 = 1/8.",
                    rubric: [rub("You multiplied", ["multiply", "×", "*", "times", "8 paths"]), rub("You found each probability", ["1/2", "1/4"])],
                    misconceptions: ["3/4": "added-instead-of-multiplied", "1/6": "added-outcome-counts"], followUp: true)))
            let sums = [5, 6, 9, 10]
            let s = sums[round % sums.count]
            let ways = 6 - abs(7 - s)
            list.append(Remediation(approach: "Count in a table",
                section: sec("Make a list, then count",
                    "When in doubt, list it out. Write the first die from 1 to 6 down the side. For each, ask: \"what must the second die be?\" If the answer is between 1 and 6, that's one outcome.\n\nThis turns a tricky question into simple checking, and you won't miss or double count any outcome.",
                    Illustration(kind: .conceptCard, caption: "Listing method for two dice", labels: ["First die: 1, 2, 3, 4, 5, 6", "Second die needed = target − first", "Keep it only if it's 1 to 6", "Count, then divide by 36"]), nil, adaptive: true),
                followUp: numeric("Two dice are rolled. What is P(sum = \(s))?",
                    answer: frac(ways, 36),
                    hints: ["For first die = 1, what must the second be?", "Go through first die = 1 to 6 and keep valid pairs.", "You should find \(ways) pairs. Divide by 36."],
                    solution: "There are \(ways) ordered pairs summing to \(s), so P = \(ways)/36 = \(frac(ways, 36)).",
                    rubric: [rub("You listed ordered pairs", ["pairs", "(", ",", "first die", "list"]), rub("You divided by 36", ["36"])],
                    misconceptions: ["1/11": "sums-equally-likely"], followUp: true)))
        default:
            list.append(Remediation(approach: "Shrinking bag story",
                section: sec("The bag gets smaller",
                    "Imagine a bag of 4 strawberry candies and 1 lemon. You grab one: the chance it's strawberry is 4/5. You eat it!\n\nNow the bag is different: **3 strawberry and 1 lemon**, only 4 candies. The second grab is 3/4 strawberry. The bag \"remembers\" what you took.\n\nSo P(two strawberries) = 4/5 × 3/4. Before each draw, **redraw the bag** in your head with what's left.",
                    Illustration(kind: .probabilityTree, caption: "The second branch uses the smaller bag.", params: ["p": 0.8, "stages": 2], labels: ["Strawberry", "Lemon"]), nil, adaptive: true),
                followUp: numeric("A bag has 4 strawberry candies and 1 lemon. You eat one, then take another. What is P(both strawberry)?",
                    answer: "3/5",
                    hints: ["First draw: strawberry out of all candies.", "After eating one strawberry, what's left in the bag?", "Multiply 4/5 by 3/4."],
                    solution: "4/5 × 3/4 = 12/20 = 3/5.",
                    rubric: [rub("You updated the bag", ["3/4", "3 strawberry", "4 left", "smaller", "without"]), rub("You multiplied", ["multiply", "×", "*", "times"])],
                    misconceptions: ["16/25": "forgot-without-replacement", "4/5": "ignored-second-event"], followUp: true)))
            list.append(Remediation(approach: "Venn picture",
                section: sec("Don't count the overlap twice",
                    "Picture two hula hoops on the floor. Students who play soccer stand in one hoop, students in band stand in the other. Students who do both stand where the hoops overlap.\n\nIf you count everyone in the soccer hoop, then everyone in the band hoop, the overlap students get counted **twice**. So subtract them once: **soccer + band − both**.",
                    Illustration(kind: .venn, caption: "Soccer and band in a class of 30", params: ["a": 8, "b": 6, "both": 4, "neither": 12], labels: ["Soccer", "Band"]), nil, adaptive: true),
                followUp: numeric("In a class of 30, 12 play soccer, 10 are in band, and 4 do both. A student is picked at random. What is P(soccer or band)?",
                    answer: "3/5",
                    hints: ["Add soccer and band players.", "Who got counted twice?", "(12 + 10 − 4) ÷ 30."],
                    solution: "12 + 10 − 4 = 18 students. P = 18/30 = 3/5.",
                    rubric: [rub("You subtracted the overlap", ["subtract", "- 4", "−4", "-4", "both", "twice", "overlap"]), rub("You divided by 30", ["30"])],
                    misconceptions: ["11/15": "double-counted-overlap", "22/30": "double-counted-overlap", "2/15": "and-instead-of-or"], followUp: true)))
            let red = 3 + (round % 3), blue = 2 + (round % 2)
            let total = red + blue
            list.append(Remediation(approach: "Update the counts",
                section: sec("Rewrite the bag after every draw",
                    "Here's a habit that prevents most mistakes: after each draw, write down the new numbers.\n\n**Before:** \(red) red, \(blue) blue (total \(total)).\n**After drawing a red:** \(red - 1) red, \(blue) blue (total \(total - 1)).\n\nThe second fraction uses the **after** numbers. Then multiply the two fractions.",
                    Illustration(kind: .fractionBar, caption: "First draw: red out of all", params: ["numerator": Double(red), "denominator": Double(total)]), nil, adaptive: true),
                followUp: numeric("A bag has \(red) red and \(blue) blue marbles. Two are drawn without replacement. What is P(both red)?",
                    answer: frac(red * (red - 1), total * (total - 1)),
                    hints: ["First draw: \(red) red out of \(total).", "After a red is drawn, write the new counts.", "Multiply \(red)/\(total) × \(red - 1)/\(total - 1)."],
                    solution: "\(red)/\(total) × \(red - 1)/\(total - 1) = \(frac(red * (red - 1), total * (total - 1))).",
                    rubric: [rub("You updated the counts", ["\(red - 1)", "\(total - 1)", "left", "remaining", "without"]), rub("You multiplied", ["multiply", "×", "*", "times"])],
                    misconceptions: [frac(red * red, total * total): "forgot-without-replacement"], followUp: true)))
        }
        return list
    }
}
