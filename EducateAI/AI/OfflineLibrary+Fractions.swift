import Foundation

extension OfflineLibrary {

    static func fractionsChapters(level: SkillLevel) -> [Chapter] {
        [fracChapter1(level), fracChapter2(level), fracChapter3(level)]
    }

    static func fracChapter1(_ level: SkillLevel) -> Chapter {
        var sections: [LessonSection] = []
        sections.append(sec("Parts of a whole",
            "A **fraction** describes part of a whole that has been split into **equal** parts. If a chocolate bar is broken into 4 equal pieces and you eat 3, you've eaten 3/4 of the bar.\n\nThe bottom number, the **denominator**, tells how many equal parts the whole is split into. The top number, the **numerator**, tells how many of those parts we're talking about.\n\nThe word *equal* matters. If a pizza is cut into one giant slice and three tiny ones, a slice isn't 1/4 of the pizza.",
            Illustration(kind: .fractionBar, caption: "3 of 4 equal parts are shaded: 3/4", params: ["numerator": 3, "denominator": 4]),
            check("In the fraction 5/8, what does the 8 tell you?", ["How many parts are shaded", "How many equal parts make the whole", "How big each part is in inches"], 1, "The denominator counts the equal parts in the whole.")))
        sections.append(sec("Fractions are numbers",
            "Fractions aren't just pictures of pizza. They are **numbers** with a place on the number line. 1/2 sits exactly halfway between 0 and 1. 3/4 sits three-quarters of the way.\n\nTo place a fraction, split the space from 0 to 1 into as many equal jumps as the denominator, then count the numerator's number of jumps. A fraction like 5/4 is more than 1: it goes one jump past the 1 mark.",
            Illustration(kind: .numberLine, caption: "Where does 3/4 live between 0 and 1?", params: ["value": 0.75], labels: ["3/4"]),
            check("Which fraction is greater than 1?", ["3/4", "4/4", "5/4"], 2, "5/4 is five quarters, one more quarter than a whole.")))
        sections.append(sec("Bigger denominator, smaller pieces",
            "Here's a surprise: 1/8 is **smaller** than 1/3. When you share a cake among 8 people, each slice is smaller than when you share it among 3.\n\nFor **unit fractions** (numerator 1), the bigger the denominator, the smaller the piece. Many people trip over this because 8 is bigger than 3, so it feels like 1/8 should be bigger.\n\n" + pick(level, "Always picture the pieces, not just the numbers.", "When numerators are equal, compare denominators in reverse: 3/5 > 3/7.", "When numerators are equal, the fraction with the smaller denominator is larger; when denominators are equal, the larger numerator wins. Otherwise, use a common denominator or cross-multiply."),
            Illustration(kind: .spinner, caption: "A spinner split into 8 equal parts. Each part is 1/8.", labels: ["1", "2", "3", "4", "5", "6", "7", "8"]),
            check("Which is larger?", ["1/8", "1/3", "They are equal"], 1, "Sharing among 3 gives bigger pieces than sharing among 8.")))

        var challenges: [Challenge] = []
        challenges.append(numeric("A garden bed is split into 8 equal rows. Mia plants carrots in 3 rows. What fraction of the bed has carrots?",
            answer: "3/8",
            hints: ["How many equal parts is the whole bed split into?", "How many of those parts have carrots?", "Put the carrot rows on top and the total rows on the bottom."],
            solution: "The bed has 8 equal rows and 3 have carrots, so the fraction is 3/8.",
            rubric: [rub("You identified 8 equal parts as the whole", ["8", "eight", "total", "whole", "rows"]),
                     rub("You used 3 as the numerator", ["3", "three", "carrot"])],
            misconceptions: ["3/5": "part-to-part-ratio", "8/3": "flipped-fraction", "5/8": "complement-confusion"]))
        challenges.append(choice("Which list is in order from smallest to largest?",
            options: ["1/2, 1/4, 1/8", "1/8, 1/4, 1/2", "1/4, 1/8, 1/2"],
            answer: "1/8, 1/4, 1/2",
            hints: ["Picture each fraction as a slice of the same pizza.", "More equal slices means each slice is smaller.", "Which has the biggest denominator? That's the smallest piece."],
            solution: "With numerator 1, a bigger denominator makes a smaller piece: 1/8 < 1/4 < 1/2.",
            rubric: [rub("You explained bigger denominators mean smaller pieces", ["bigger denominator", "more pieces", "smaller pieces", "more parts", "split into more"]),
                     rub("You used a picture or example", ["pizza", "cake", "slice", "share", "picture", "bar"])],
            misconceptions: ["1/2, 1/4, 1/8": "bigger-denominator-bigger-fraction"]))
        switch level {
        case .beginner:
            challenges.append(numeric("A ribbon is cut into 5 equal pieces. Sam uses 2 of them. What fraction of the ribbon is left?",
                answer: "3/5",
                hints: ["How many pieces were there to start?", "How many pieces are left after Sam uses 2?", "Left pieces ÷ total pieces."],
                solution: "5 − 2 = 3 pieces are left out of 5, so 3/5 of the ribbon remains.",
                rubric: [rub("You found 3 pieces left", ["3", "three", "left", "5 - 2", "5-2", "remain"]), rub("You kept 5 as the whole", ["5", "five", "total", "whole"])],
                misconceptions: ["2/5": "answered-used-not-left", "3/2": "part-to-part-ratio"]))
        case .intermediate:
            challenges.append(numeric("On a number line from 0 to 2, where is 7/4? Give your answer as a decimal.",
                answer: "1.75",
                hints: ["How many quarters make one whole?", "7 quarters is one whole plus how many quarters?", "Convert 3/4 to a decimal and add 1."],
                solution: "7/4 = 4/4 + 3/4 = 1 + 0.75 = 1.75.",
                rubric: [rub("You split into wholes and parts", ["4/4", "1 and 3/4", "one whole", "1 3/4", "mixed"]), rub("You converted to a decimal", ["0.75", ".75", "divide", "decimal"])],
                misconceptions: ["0.75": "ignored-whole-part", "7.4": "decimal-notation-confusion", "0.57": "flipped-fraction"]))
        case .advanced:
            challenges.append(numeric("Which is larger, 5/7 or 7/10? Give the difference (larger minus smaller) as a fraction.",
                answer: "1/70",
                hints: ["Use a common denominator to compare.", "The least common denominator of 7 and 10 is 70.", "Convert both: 5/7 = 50/70 and 7/10 = ?/70."],
                solution: "5/7 = 50/70 and 7/10 = 49/70. So 5/7 is larger by 1/70.",
                rubric: [rub("You used a common denominator of 70", ["70", "seventy", "common denominator", "lcd"]), rub("You converted both fractions", ["50/70", "49/70", "50", "49"])],
                misconceptions: ["2/3": "subtracted-tops-and-bottoms", "-1/70": "subtracted-wrong-order"]))
        }
        return Chapter(index: 0, title: "What Is a Fraction?", summary: "Equal parts, numerators and denominators, and fractions as numbers on a line.",
            locationName: "Slice Garden", theme: .garden,
            npc: NPC(name: "Gardener Gus", role: "Tender of Slice Garden", greeting: "Every garden bed here is split into equal parts. Can you tell me what part I've planted?", emoji: "🧑‍🌾"),
            sections: sections,
            keyIdeas: ["A fraction names equal parts of a whole.", "The denominator counts the equal parts; the numerator counts the parts we mean.", "Fractions are numbers with a place on the number line.", "For unit fractions, a bigger denominator means a smaller piece."],
            challenges: challenges,
            discussionPrompts: ["Where do you see fractions at home, like recipes, clocks or money?", "Why does 1/8 feel bigger than 1/3 to some people? How would you convince them?", "Fold a sheet of paper into equal parts. What fractions can you make?"])
    }

    static func fracChapter2(_ level: SkillLevel) -> Chapter {
        var sections: [LessonSection] = []
        sections.append(sec("Same amount, different names",
            "**Equivalent fractions** name the same amount using different numbers. Cut a pizza into 2 and eat 1 slice: you ate 1/2. Cut the same pizza into 4 and eat 2: you still ate half. So 1/2 = 2/4 = 4/8.\n\nTo make an equivalent fraction, **multiply the numerator and denominator by the same number**. You're just cutting every piece into the same number of smaller pieces.",
            Illustration(kind: .fractionBar, caption: "2/4 covers exactly as much as 1/2", params: ["numerator": 2, "denominator": 4]),
            check("Which fraction is equivalent to 1/3?", ["2/6", "2/3", "1/6"], 0, "Multiply top and bottom by 2: 1/3 = 2/6.")))
        sections.append(sec("Simplifying",
            "Going the other way is **simplifying**: divide the numerator and denominator by the same number. 6/8 becomes 3/4 when you divide both by 2.\n\nA fraction is in **simplest form** when the only number dividing both top and bottom is 1. To get there in one step, divide by the **greatest common factor**. For 12/18, the GCF is 6, so 12/18 = 2/3.",
            Illustration(kind: .conceptCard, caption: "How to simplify", labels: ["Find a number that divides top and bottom", "Divide both by it", "Repeat until only 1 divides both", "Check: is it the same amount?"]),
            check("What is 10/15 in simplest form?", ["2/3", "5/10", "1/5"], 0, "Divide top and bottom by 5.")))
        sections.append(sec("Comparing with common denominators",
            "Which is bigger, 2/3 or 3/5? It's hard to tell because the pieces are different sizes. Make them the same size first: rewrite both with a **common denominator**.\n\n2/3 = 10/15 and 3/5 = 9/15. Now the pieces match, and 10 pieces beat 9 pieces, so 2/3 is bigger.\n\n" + pick(level, "A quick check: compare each fraction to 1/2.", "A shortcut is cross-multiplying: compare 2 × 5 = 10 with 3 × 3 = 9.", "Cross-multiplication works because a/b > c/d ⇔ ad > bc when b, d > 0. Benchmarks like 1/2 and 1 often avoid computation entirely."),
            Illustration(kind: .numberLine, caption: "2/3 sits just to the right of 3/5", params: ["value": 0.667], labels: ["2/3"])))

        var challenges: [Challenge] = []
        challenges.append(numeric("Baker Bea used 6/8 of a bag of flour. Write that amount in simplest form.",
            answer: "3/4",
            hints: ["Is there a number that divides both 6 and 8?", "Both are even, so try dividing by 2.", "6 ÷ 2 and 8 ÷ 2 give the simplest form."],
            solution: "Divide top and bottom by 2: 6/8 = 3/4.",
            rubric: [rub("You divided both numbers by the same factor", ["divide", "÷", "/2", "by 2", "both", "common factor", "gcf"]),
                     rub("You checked it's the same amount", ["same", "equivalent", "equal", "still"])],
            misconceptions: ["6/8": "not-simplified", "3/8": "divided-numerator-only", "1/2": "over-simplified"]))
        challenges.append(choice("Which fraction is NOT equivalent to 2/5?",
            options: ["4/10", "6/15", "4/7"],
            answer: "4/7",
            hints: ["Equivalent fractions multiply top and bottom by the same number.", "Check each: what did 2 and 5 get multiplied by?", "For each option, divide the bottom by 5. Did the top get multiplied by that same number?"],
            solution: "4/10 and 6/15 multiply both parts by 2 and 3. 4/7 adds 2 to both, which doesn't keep the amount the same.",
            rubric: [rub("You checked multiplying top and bottom by the same number", ["multiply", "×", "same number", "times", "both"]),
                     rub("You noticed adding doesn't keep it equivalent", ["add", "plus", "+2", "+ 2", "not multiplied"])],
            misconceptions: ["4/10": "equivalence-confusion", "6/15": "equivalence-confusion"]))
        switch level {
        case .beginner:
            challenges.append(numeric("Fill in the blank: 1/2 = ?/10. What number goes on top?",
                answer: "5",
                hints: ["What do you multiply 2 by to get 10?", "Whatever you do to the bottom, do to the top.", "Multiply 1 by that same number."],
                solution: "2 × 5 = 10, so multiply the top by 5 too: 1/2 = 5/10.",
                rubric: [rub("You found the multiplier 5", ["5", "five", "× 5", "x5", "times 5"]), rub("You applied it to both parts", ["both", "top", "same", "numerator"])],
                misconceptions: ["9": "added-instead-of-multiplied", "2": "unchanged-numerator"]))
        case .intermediate:
            challenges.append(numeric("Simplify 18/24 completely.",
                answer: "3/4",
                hints: ["Find the greatest common factor of 18 and 24.", "Both are divisible by 6.", "Divide top and bottom by 6."],
                solution: "GCF(18, 24) = 6. 18/24 = 3/4.",
                rubric: [rub("You found a common factor", ["6", "gcf", "common factor", "divide"]), rub("You reached simplest form", ["simplest", "3/4", "only 1"])],
                misconceptions: ["9/12": "not-fully-simplified", "6/8": "not-fully-simplified"]))
        case .advanced:
            challenges.append(numeric("Order 5/8, 2/3 and 7/12 and give the largest minus the smallest as a fraction.",
                answer: "1/12",
                hints: ["Find a common denominator for 8, 3 and 12.", "24 works: convert each fraction to twenty-fourths.", "Compare 15/24, 16/24 and 14/24."],
                solution: "5/8 = 15/24, 2/3 = 16/24, 7/12 = 14/24. Largest − smallest = 16/24 − 14/24 = 2/24 = 1/12.",
                rubric: [rub("You used a common denominator of 24", ["24", "common denominator", "lcd"]), rub("You converted each fraction", ["15/24", "16/24", "14/24"])],
                misconceptions: ["1/24": "arithmetic-slip", "2/24": "not-simplified"]))
        }
        return Chapter(index: 1, title: "Equivalent Fractions", summary: "Rename fractions, simplify them and compare them fairly.",
            locationName: "Baker's Workshop", theme: .workshop,
            npc: NPC(name: "Baker Bea", role: "Master of the Workshop", greeting: "Half a cup or two quarter cups? In my workshop, they're the same! Can you tell why?", emoji: "🧁"),
            sections: sections,
            keyIdeas: ["Equivalent fractions name the same amount.", "Multiply or divide top and bottom by the same number.", "Simplest form: only 1 divides both parts.", "Compare fractions by making the pieces the same size."],
            challenges: challenges,
            discussionPrompts: ["Find a recipe and rewrite one measurement as an equivalent fraction.", "Why does adding the same number to top and bottom change the amount?", "Explain to a friend why 2/4 and 1/2 are the same."])
    }

    static func fracChapter3(_ level: SkillLevel) -> Chapter {
        var sections: [LessonSection] = []
        sections.append(sec("Adding like fractions",
            "When fractions have the **same denominator**, the pieces are the same size, so just count them: 2/7 + 3/7 = 5/7. The denominator stays the same because the size of the pieces didn't change.\n\nA common mistake is adding the denominators too: 2/7 + 3/7 is **not** 5/14. Two-sevenths plus three-sevenths is five-sevenths, the same way two apples plus three apples is five apples.",
            Illustration(kind: .fractionBar, caption: "2/7 + 3/7 = 5/7", params: ["numerator": 5, "denominator": 7]),
            check("What is 1/5 + 2/5?", ["3/10", "3/5", "2/25"], 1, "Same-size pieces: count them. 1 + 2 = 3 fifths.")))
        sections.append(sec("Unlike denominators",
            "To add 1/2 + 1/3, the pieces are different sizes. First, rename both with a **common denominator**. Sixths work for both: 1/2 = 3/6 and 1/3 = 2/6. Now add: 3/6 + 2/6 = 5/6.\n\nThe same steps work for subtraction: 3/4 − 1/6 = 9/12 − 2/12 = 7/12.",
            Illustration(kind: .conceptCard, caption: "Adding unlike fractions", labels: ["Find a common denominator", "Rename each fraction", "Add or subtract the numerators", "Simplify the result"]),
            check("What's a common denominator for 1/4 and 1/6?", ["10", "12", "24 only"], 1, "12 is the least common multiple of 4 and 6 (24 also works, but 12 is smaller).")))
        sections.append(sec(level == .advanced ? "Mixed numbers and multiplying" : "Mixed numbers",
            "A **mixed number** like 2 1/4 means 2 wholes and 1/4 more. To add mixed numbers, add the wholes and the fractions separately, then regroup if the fractions make more than 1.\n\n1 3/4 + 2 2/4 = 3 5/4 = 4 1/4.\n\n" + pick(level, "", "You can also convert to improper fractions first: 1 3/4 = 7/4.", "Multiplying fractions is easier than adding: multiply tops and multiply bottoms. 2/3 × 3/4 = 6/12 = 1/2. Think of it as \"2/3 **of** 3/4\"."),
            Illustration(kind: .numberLine, caption: "1 3/4 + 2 2/4 lands at 4 1/4 (shown as a share of 5)", params: ["value": 0.85], labels: ["4 1/4"])))

        var challenges: [Challenge] = []
        challenges.append(numeric("A boat trip covers 2/8 of the harbor in the morning and 3/8 in the afternoon. What fraction of the harbor is covered in total?",
            answer: "5/8",
            hints: ["Are the denominators the same?", "Same-size pieces can just be counted.", "Add the numerators and keep the eighths."],
            solution: "2/8 + 3/8 = 5/8. The denominator stays 8 because the pieces are still eighths.",
            rubric: [rub("You added the numerators", ["2 + 3", "2+3", "add", "5", "numerator"]), rub("You kept the denominator", ["8", "same denominator", "eighths", "stays"])],
            misconceptions: ["5/16": "added-denominators", "6/64": "multiplied-everything"]))
        challenges.append(numeric("Captain Cora has 3/4 of a tank of fuel and uses 1/3 of a tank. How much is left?",
            answer: "5/12",
            hints: ["The denominators differ. What common denominator works for 4 and 3?", "Use twelfths.", "3/4 = 9/12 and 1/3 = 4/12."],
            solution: "3/4 − 1/3 = 9/12 − 4/12 = 5/12 of a tank.",
            rubric: [rub("You found a common denominator", ["12", "twelfths", "common denominator", "lcd"]), rub("You renamed both fractions", ["9/12", "4/12"])],
            misconceptions: ["2/1": "subtracted-tops-and-bottoms", "2": "subtracted-tops-and-bottoms", "2/12": "renaming-error"]))
        switch level {
        case .beginner:
            challenges.append(numeric("What is 1/2 + 1/4?",
                answer: "3/4",
                hints: ["Can you write 1/2 using quarters?", "1/2 is the same as 2/4.", "Now add 2/4 + 1/4."],
                solution: "1/2 = 2/4, so 2/4 + 1/4 = 3/4.",
                rubric: [rub("You renamed 1/2 as 2/4", ["2/4", "quarters", "two quarters"]), rub("You added like fractions", ["add", "3/4", "+"])],
                misconceptions: ["2/6": "added-denominators", "1/3": "added-denominators"]))
        case .intermediate:
            challenges.append(numeric("Add 1 2/3 + 2 1/2. Give an improper fraction or mixed number.",
                answer: "25/6",
                hints: ["Add the whole numbers first.", "Add 2/3 + 1/2 with a common denominator of 6.", "4/6 + 3/6 = 7/6, which is more than 1. Regroup."],
                solution: "Wholes: 1 + 2 = 3. Fractions: 4/6 + 3/6 = 7/6 = 1 1/6. Total = 4 1/6 = 25/6.",
                rubric: [rub("You added wholes and fractions", ["wholes", "1 + 2", "3", "separately"]), rub("You used sixths", ["6", "sixths", "4/6", "3/6"]), rub("You regrouped", ["regroup", "7/6", "1 1/6", "more than 1"])],
                misconceptions: ["3 3/5": "added-denominators", "19/6": "forgot-regroup"]))
        case .advanced:
            challenges.append(numeric("A recipe needs 3/4 cup of sugar. You make 2/3 of the recipe. How many cups of sugar do you need?",
                answer: "1/2",
                hints: ["\"2/3 of\" means multiply.", "Multiply numerators and multiply denominators.", "(2 × 3)/(3 × 4), then simplify."],
                solution: "2/3 × 3/4 = 6/12 = 1/2 cup.",
                rubric: [rub("You multiplied", ["multiply", "×", "*", "of", "times"]), rub("You simplified", ["6/12", "simplif", "1/2"])],
                misconceptions: ["17/12": "added-instead-of-multiplied", "1/12": "subtracted-instead-of-multiplied", "6/12": "not-simplified"]))
        }
        return Chapter(index: 2, title: "Adding and Subtracting Fractions", summary: "Combine fractions with like and unlike denominators, and work with mixed numbers.",
            locationName: "Harbor of Halves", theme: .harbor,
            npc: NPC(name: "Captain Cora", role: "Harbor Master", greeting: "Ahoy! My fuel gauge reads in quarters, my map in thirds. Help me make them work together!", emoji: "⚓️"),
            sections: sections,
            keyIdeas: ["Like denominators: add the numerators, keep the denominator.", "Unlike denominators: rename with a common denominator first.", "Never add the denominators.", "Mixed numbers: add wholes and parts, then regroup."],
            challenges: challenges,
            discussionPrompts: ["Why don't we add the denominators? Use a picture to explain.", "Find a real situation where you'd add two fractions.", "Double a recipe that uses fractions. What changed?"])
    }

    static func fractionsRemediations(chapter: Int, round: Int) -> [Remediation] {
        var list: [Remediation] = []
        switch chapter {
        case 0:
            list.append(Remediation(approach: "Visual analogy",
                section: sec("Chocolate bar thinking",
                    "Picture a chocolate bar with grooves that split it into equal squares. The **denominator** is how many squares the whole bar has. The **numerator** is how many squares you're holding.\n\nIf the bar has 6 squares and you hold 4, you have 4/6 of the bar. Always count the whole bar first, then the part.",
                    Illustration(kind: .fractionBar, caption: "4 of 6 squares", params: ["numerator": 4, "denominator": 6]), nil, adaptive: true),
                followUp: numeric("A chocolate bar has 10 equal squares. You eat 3. What fraction did you eat?",
                    answer: "3/10",
                    hints: ["How many squares in the whole bar?", "How many did you eat?", "Eaten over whole."],
                    solution: "3 out of 10 equal squares: 3/10.",
                    rubric: [rub("You used 10 as the whole", ["10", "ten", "whole", "total"]), rub("You used 3 as the part", ["3", "three", "ate", "eaten"])],
                    misconceptions: ["3/7": "part-to-part-ratio", "10/3": "flipped-fraction", "7/10": "complement-confusion"], followUp: true)))
            list.append(Remediation(approach: "Sharing story",
                section: sec("Sharing a cake fairly",
                    "When more friends share a cake, everyone gets a smaller slice. With 2 friends, each gets 1/2. With 6 friends, each gets 1/6, which is much smaller.\n\nSo when the numerator is 1, ask: \"How many people are sharing?\" More people means a smaller piece.",
                    Illustration(kind: .spinner, caption: "A cake shared by 6 friends", labels: ["Ana", "Ben", "Cy", "Dee", "Eli", "Fay"]), nil, adaptive: true),
                followUp: choice("Which is the biggest slice?",
                    options: ["1/6 of a cake", "1/2 of a cake", "1/10 of a cake"],
                    answer: "1/2 of a cake",
                    hints: ["How many people share in each case?", "Fewer people means bigger slices.", "Which has the smallest denominator?"],
                    solution: "Sharing between 2 gives the biggest slice: 1/2 > 1/6 > 1/10.",
                    rubric: [rub("You reasoned about fewer people sharing", ["fewer", "less people", "2 people", "smaller denominator", "shared by 2"]), rub("You compared the pieces", ["bigger", "larger", "smaller"])],
                    misconceptions: ["1/10 of a cake": "bigger-denominator-bigger-fraction"], followUp: true)))
            let d = 5 + (round % 4), n = 2 + (round % 3)
            list.append(Remediation(approach: "Number line walk",
                section: sec("Hop along the line",
                    "Draw a line from 0 to 1 and split it into \(d) equal hops. Each hop is 1/\(d). Take \(n) hops from 0 and you land on \(n)/\(d).\n\nThinking in hops helps you see a fraction as a distance, not just a shape.",
                    Illustration(kind: .numberLine, caption: "\(n) hops of 1/\(d)", params: ["value": Double(n) / Double(d)], labels: ["\(n)/\(d)"]), nil, adaptive: true),
                followUp: numeric("A path from 0 to 1 is split into \(d) equal hops. A frog takes \(n) hops. What fraction of the path has it covered?",
                    answer: "\(n)/\(d)",
                    hints: ["How big is each hop?", "How many hops did the frog take?", "Hops taken over total hops."],
                    solution: "Each hop is 1/\(d), so \(n) hops is \(n)/\(d).",
                    rubric: [rub("You found the size of each hop", ["1/\(d)", "each hop", "equal"]), rub("You counted the hops", ["\(n)", "hops", "took"])],
                    misconceptions: ["\(d)/\(n)": "flipped-fraction"], followUp: true)))
        case 1:
            list.append(Remediation(approach: "Paper folding",
                section: sec("Fold it and see",
                    "Take a strip of paper and fold it in half. Shade one half. Now fold it in half again. The shaded part didn't change, but now it's **2 of 4** parts. Fold again: **4 of 8**.\n\nEach fold multiplies both the number of parts and the shaded parts by 2. That's why multiplying top and bottom by the same number keeps the amount the same.",
                    Illustration(kind: .fractionBar, caption: "4/8 after folding twice", params: ["numerator": 4, "denominator": 8]), nil, adaptive: true),
                followUp: numeric("A strip shows 3/4 shaded. You fold every part in half. How many eighths are shaded? (Give the fraction.)",
                    answer: "6/8",
                    hints: ["Folding in half doubles the number of parts.", "It also doubles the number of shaded parts.", "Multiply top and bottom by 2."],
                    solution: "3/4 × 2/2 = 6/8.",
                    rubric: [rub("You doubled both parts", ["double", "× 2", "x2", "times 2", "both"]), rub("You kept the amount the same", ["same", "equivalent", "equal"])],
                    misconceptions: ["3/8": "multiplied-denominator-only", "5/6": "added-instead-of-multiplied"], followUp: true)))
            list.append(Remediation(approach: "Worked example",
                section: sec("Simplify step by step",
                    "Let's simplify 8/12 together.\n\n**Step 1:** Both 8 and 12 are even, so divide by 2: 4/6.\n\n**Step 2:** Both 4 and 6 are still even: 2/3.\n\n**Step 3:** Is there any number besides 1 that divides 2 and 3? No, so 2/3 is the simplest form.\n\nIf you spot the greatest common factor (4) right away, you can do it in one step.",
                    Illustration(kind: .conceptCard, caption: "8/12 → 4/6 → 2/3", labels: ["Divide by 2: 4/6", "Divide by 2 again: 2/3", "Nothing else divides both", "Done: 2/3"]), nil, adaptive: true),
                followUp: numeric("Simplify 9/12.",
                    answer: "3/4",
                    hints: ["Which number divides both 9 and 12?", "Try 3.", "9 ÷ 3 and 12 ÷ 3."],
                    solution: "Divide both by 3: 9/12 = 3/4.",
                    rubric: [rub("You found a common factor", ["3", "three", "common factor", "gcf", "divide"]), rub("You divided both parts", ["both", "top and bottom"])],
                    misconceptions: ["3/12": "divided-numerator-only", "9/4": "divided-denominator-only"], followUp: true)))
        default:
            list.append(Remediation(approach: "Same-size pieces",
                section: sec("Why the denominator stays",
                    "Imagine 2 quarters and 1 quarter in your pocket: you have 3 quarters. You'd never say \"3 eighths\" just because there were two groups.\n\nThe denominator is the **name** of the piece, like \"quarter\". When you add pieces with the same name, you count them and keep the name.",
                    Illustration(kind: .fractionBar, caption: "2/4 + 1/4 = 3/4", params: ["numerator": 3, "denominator": 4]), nil, adaptive: true),
                followUp: numeric("What is 3/10 + 4/10?",
                    answer: "7/10",
                    hints: ["What's the name of the pieces?", "Count the pieces: 3 plus 4.", "Keep the name tenths."],
                    solution: "3 tenths + 4 tenths = 7 tenths: 7/10.",
                    rubric: [rub("You added numerators", ["3 + 4", "3+4", "7", "add"]), rub("You kept tenths", ["10", "tenths", "keep", "same"])],
                    misconceptions: ["7/20": "added-denominators"], followUp: true)))
            list.append(Remediation(approach: "Worked example",
                section: sec("Unlike denominators, step by step",
                    "Let's do 1/4 + 1/6.\n\n**Step 1:** Find a number both 4 and 6 go into: 12.\n\n**Step 2:** Rename: 1/4 = 3/12 and 1/6 = 2/12.\n\n**Step 3:** Add same-size pieces: 3/12 + 2/12 = 5/12.\n\nThe renaming step makes the pieces the same size, so counting works again.",
                    Illustration(kind: .conceptCard, caption: "1/4 + 1/6", labels: ["Common denominator: 12", "1/4 = 3/12", "1/6 = 2/12", "Sum: 5/12"]), nil, adaptive: true),
                followUp: numeric("What is 1/3 + 1/4?",
                    answer: "7/12",
                    hints: ["Find a common denominator for 3 and 4.", "Rename both as twelfths.", "4/12 + 3/12."],
                    solution: "1/3 = 4/12, 1/4 = 3/12. Sum = 7/12.",
                    rubric: [rub("You found 12", ["12", "twelfths", "common"]), rub("You renamed both", ["4/12", "3/12"])],
                    misconceptions: ["2/7": "added-denominators", "1/7": "added-denominators"], followUp: true)))
        }
        return list
    }
}
