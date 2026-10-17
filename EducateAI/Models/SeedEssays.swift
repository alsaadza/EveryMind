import Foundation

/// Demo content for the teacher-facing essay feedback feature.
/// All students, names, and essays are fictional.
enum SeedEssays {

    struct Entry {
        let studentName: String
        let text: String
        let profileHint: String
    }

    // MARK: - Late-start argumentative essays (Grade 9 English)

    /// Paragraphs separated by a blank line ("\n\n"). Plain text, no markdown.
    static let lateStart: [Entry] = [
        // Exemplary
        Entry(
            studentName: "Maya Okafor",
            text: """
            Every morning my alarm goes off at 6:15, while it is still dark outside, and I am not the only one at our school who drags through first period half asleep. Starting at 7:45 a.m. works against the way teenagers' bodies actually function. Our high school should move its start time to 9:00 a.m. because a later start matches teen sleep needs, protects students' health, and has already worked in real school districts.

            First, teenagers need more sleep than most of us get. According to the CDC, teens ages 13 to 18 need 8 to 10 hours of sleep every night. The problem is not just that teens stay up on their phones. During adolescence, the brain starts releasing melatonin, the hormone that makes you sleepy, later at night. Because of this shift in our circadian rhythm, many teenagers can't fall asleep until around 11:00 p.m. If a student falls asleep at 11 and wakes up at 6:15, that is barely seven hours.

            Medical experts agree that this is a serious problem. In 2014, the American Academy of Pediatrics recommended that middle and high schools start no earlier than 8:30 a.m. The AAP linked chronic sleep loss in teens to car accidents, depression, and lower grades, which shows that being tired can effect much more than a quiz score. Furthermore, later start times have worked in practice. When Seattle Public Schools moved its high school start times later in 2016, a University of Washington study found that students got about 34 more minutes of sleep per night, and attendance in first period improved.

            Some people argue that a later start would ruin after-school sports and jobs, since practices and shifts would end later in the evening. This is a fair concern, and it would take planning. However, athletes who are well rested play better and get injured less, and some practices could move to the morning before classes. Others say teens would just stay up later. But the Seattle researchers measured actual sleep with wrist monitors, and students really did sleep longer instead of simply shifting their bedtime.

            In conclusion, starting at 9:00 a.m. is not about letting students be lazy. It is about building the school day around the science of how teenagers sleep. A later start would make our school healthier, safer, and more focused, and that is worth a few changes to the bus and sports schedules.
            """,
            profileHint: "Exemplary"
        ),

        // Solid but uneven — strong thesis, thin rebuttal
        Entry(
            studentName: "Priya Raman",
            text: """
            Imagine trying to solve a geometry proof when your brain still thinks it's the middle of the night. That is what first period feels like for a lot of students here. I believe our school should start at 9:00 a.m. instead of 7:45 a.m. because students would be healthier and do better in class.

            The biggest reason is sleep. The CDC says teenagers need 8 to 10 hours of sleep a night, but most high schoolers get way less than that. Teenagers' sleep cycles are different from adults. Our bodies want to go to sleep later and wake up later, it's not something we can just decide to change. So when school starts at 7:45, we are basically forced to be sleep deprived.

            Being tired also hurts grades. When I am tired I read the same paragraph three times and still don't remember it. Studies show that students who get more sleep have better grades and better attendance. Seattle changed their start time and students there slept more. If our school started later, more students would actually be awake enough to learn instead of just sitting there.

            Another reason is mental health. Not getting enough sleep makes people more stressed and moody. A lot of students at our school already have a lot of pressure from homework, sports, and college stuff. An extra hour of sleep would not fix everything but it would help. Even my brother, who is a junior, says he would be less stressed if he wasn't exhausted all the time.

            Some people argue that starting later means school ends later, and that would mess up sports and after-school jobs. However, I think health is more important than a practice schedule.

            In conclusion, starting school at 9:00 a.m. would help students sleep more, focus better, and feel less stressed. The school board should seriously think about making this change, because students' health should come first.
            """,
            profileHint: "Solid — counterargument underdeveloped"
        ),

        // Solid but uneven — good evidence, wandering organization
        Entry(
            studentName: "Kenji Watanabe",
            text: """
            School should start at 9:00 a.m. The current 7:45 start is too early for teenagers and it is affecting how we learn.

            There is actual science behind why teens are tired in the morning. When kids hit puberty their bodies start making melatonin later at night. Melatonin is the chemical that tells you to go to sleep. This means a teenager is not being lazy when they can't fall asleep at 10, their internal clock is literally set later than an adult's. The American Academy of Pediatrics said in 2014 that high schools should not start before 8:30 a.m. Our school starts 45 minutes before that.

            My older cousin goes to high school in Seattle, where they moved the start time later in 2016. He says it was weird at first but now nobody wants to go back. A study from the University of Washington found students there slept about 34 minutes more per night. That might not sound like a lot. But over a whole school year it adds up to more than 100 hours. Also my cousin plays soccer and the team still practices, they just end a little later. And the buses had to be rearranged which took a while. Some parents complained about the buses.

            Critics say that a later start will just make teenagers stay up later, so it won't actually help. However, the Seattle study showed that students' bedtimes stayed about the same and they just woke up later, so they got more total sleep. Another thing is that some teachers might like the later start too. My science teacher said she is not a morning person either, and she has to drive 40 minutes to get here.

            Overall, the evidence shows a 9:00 start would help students get the sleep they need. Our school should follow what the doctors recommend.
            """,
            profileHint: "Solid — organization uneven"
        ),

        // Developing — evidence mostly anecdote, vague thesis, no counterargument
        Entry(
            studentName: "Jonah Reyes",
            text: """
            School start times are something that a lot of people have opinions about and I think it is a really important topic that should be talked about more because it affects everyone at our school every single day.

            Last year I had first period math at 7:45 and I was really tired every single day and I would put my head down on the desk and my teacher would get mad at me but it wasn't my fault because I really could not keep my eyes open no matter how hard I tried. I even tried drinking coffee. It didn't work.

            My friends feel the same way. My friend Marcus misses the bus like twice a week because he can't wake up and then his mom has to drive him and she gets really annoyed and then he is late to her work too. That's not fair to her. Another friend said she falls asleep in her car in the parking lot before school. Which is kind of dangerous.

            On weekends I sleep until like 11 and I feel totally fine, so I think that proves that teenagers just need to sleep later and the school is making us get up at a time that is really not good for us and it makes the whole day worse because once you are tired in the morning you are tired the whole day and you can't focus in any of your classes even the ones you like.

            Studies show that sleep is important for your brain. If we got more sleep we would do better on tests and be in a better mood. Teachers would probably be happier too because students would actually pay attention.

            So I think school should start later, maybe at 9:00. It would be really good for everybody and people would be a lot less tired.
            """,
            profileHint: "Developing — evidence"
        ),

        // Developing — thesis late, overuse of "very", vague citations
        Entry(
            studentName: "Leah Goldberg",
            text: """
            It is 6:00 in the morning and my alarm is going off for the third time. I hit snooze again. My mom yells up the stairs that I am going to miss the bus. This is what almost every school morning is like in my house and I know I am not the only one, because when I get to first period half the class looks like zombies and the other half is drinking energy drinks which is honestly not very healthy either.

            Sleep is very important for teenagers. Studies show that teenagers need a lot of sleep, more than adults. Scientists say that teenagers' brains are still growing and sleep helps the brain grow. When you don't get enough sleep you get very cranky and it is very hard to concentrate.

            That is why I believe that our school should start at 9:00 instead of 7:45. An hour and fifteen minutes might not seem like a big deal but to a tired teenager it is very big. It could be the difference between eating breakfast and not eating breakfast, or between paying attention in English and staring at the wall.

            Some schools have already changed their start times and it went very well, the students were happier and they got better grades. I read about it online. My aunt is a nurse and she says that being tired all the time is bad for your health and can even make you get sick more, so starting later would mean less kids would be absent from school because they would not be sick as much and they would not be as tired either.

            Also, a later start would be good for teachers. Teachers have to wake up even earlier than students to get to school, so they are probably very tired too. Everyone would be in a better mood and the whole school would just be a nicer place to be.

            Starting school later is a very good idea and our school should try it.
            """,
            profileHint: "Developing — thesis and organization"
        ),

        // Struggling — conventions
        Entry(
            studentName: "Mateo Alvarez",
            text: """
            i think school should start at 9 becuase 7:45 is to early. Alot of kids are tird in teh morning and they cant focus in class. i am definately one of them, i wake up at 6 to catch the bus and i am tird all day. When your tird you dont learn anything you just sit there and wait for the bell. Also some kids dont eat breakfast becuase they dont have time and then there hungry and that makes it worse. My mom says teenagers need alot of sleep like 9 hours and i only get like 6 or 7.

            Another reason is driving. Some seniors drive to school and if there tird they could crash, that is really dangerous. Teachers would be happier to becuase the students would actually be awake. i think if we started at 9 more people would come to school and less people would be late. Some people say it would mess up sports but sports could just go later its not a big deal. Kids would be definately be in a better mood and
            """,
            profileHint: "Struggling — conventions"
        ),

        // Opposing position — competent argument for keeping 7:45
        Entry(
            studentName: "Omar Siddiqui",
            text: """
            Almost everyone in my grade wants school to start later, and I understand why. Nobody likes waking up in the dark. But a 9:00 a.m. start would create more problems than it solves. Our high school should keep its 7:45 a.m. start time because a later schedule would hurt students' jobs and activities, disrupt families, and fail to fix the real cause of teen sleep loss.

            First, a later start pushes everything else later. If school starts at 9:00, it ends around 4:15, which means sports practices would run until 6:30 or later. In the winter, it is dark by 5:00, so outdoor teams like soccer and track would lose practice time. Students with after-school jobs would also lose hours. For some families, a teenager's paycheck is not just spending money. It helps pay bills.

            Second, the bus schedule affects more than just our school. Our district uses the same buses for the high school, the middle school, and the elementary schools. If the high school moves to 9:00, then either the elementary schools have to start earlier, or the district has to buy more buses and hire more drivers. Many parents also count on older siblings to get home early and watch younger kids. A late dismissal takes that away.

            Supporters of a later start point out that the American Academy of Pediatrics recommends that high schools start no earlier than 8:30 a.m., and that teenagers naturally fall asleep later because of how melatonin works. These are real facts, and teen sleep is a real problem. However, a big part of the problem is what happens at night. Phones, video games, and late-night homework keep students up, and if school started later, many students would just push their bedtime later too. Teaching better sleep habits, like putting phones away an hour before bed, would help without rearranging the whole district.

            In conclusion, starting school at 9:00 a.m. sounds like an easy fix, but it would cost students jobs and practice time, cause problems for families and younger students, and still not solve the habits that keep teenagers awake. Keeping the 7:45 start and focusing on healthier nighttime routines is the more realistic choice.
            """,
            profileHint: "Opposing position"
        ),
    ]

    // MARK: - Class roster

    struct Roster {
        let name: String
        let avatar: String
        let profile: String
        let accommodations: [String]
        let supportNote: String
    }

    static let roster: [Roster] = [
        Roster(name: "Maya Okafor", avatar: "avatar-01", profile: "standard",
               accommodations: [], supportNote: ""),
        Roster(name: "Theo Lindqvist", avatar: "avatar-02", profile: "dyslexia",
               accommodations: ["dyslexiaFont", "readAloud", "extendedTime"],
               supportNote: "504 plan: extended time 1.5x. Uses text-to-speech for longer readings; assess ideas separately from spelling."),
        Roster(name: "Amara Diallo", avatar: "avatar-03", profile: "standard",
               accommodations: [], supportNote: ""),
        Roster(name: "Jonah Reyes", avatar: "avatar-04", profile: "standard",
               accommodations: [], supportNote: ""),
        Roster(name: "Priya Raman", avatar: "avatar-05", profile: "focus",
               accommodations: ["chunkedText", "extendedTime", "reducedLength"],
               supportNote: "IEP: extended time and shortened readings. Uses a focus timer; prefers one task on screen at a time."),
        Roster(name: "Lucas Moreau", avatar: "avatar-06", profile: "listen",
               accommodations: ["readAloud", "extendedTime"],
               supportNote: "Prefers audio for instructions and feedback. Please keep read-aloud enabled for assignment prompts."),
        Roster(name: "Sofia Petrova", avatar: "avatar-07", profile: "standard",
               accommodations: [], supportNote: ""),
        Roster(name: "Kenji Watanabe", avatar: "avatar-08", profile: "visual",
               accommodations: ["visualSupports", "chunkedText"],
               supportNote: "Learns best with graphic organizers and examples. Outline templates help with essay structure."),
        Roster(name: "Zara Haddad", avatar: "avatar-09", profile: "focus",
               accommodations: ["chunkedText", "extendedTime"],
               supportNote: "504 plan: work in shorter chunks with check-ins. Benefits from one or two priority comments at a time."),
        Roster(name: "Mateo Alvarez", avatar: "avatar-10", profile: "standard",
               accommodations: [], supportNote: "Responds well to brief, encouraging feedback with one next step."),
        Roster(name: "Leah Goldberg", avatar: "avatar-11", profile: "dyslexia",
               accommodations: ["dyslexiaFont", "readAloud", "extendedTime"],
               supportNote: "504 plan: extended time 1.5x and audio support for readings. Drafts in speech-to-text at home."),
        Roster(name: "Omar Siddiqui", avatar: "avatar-12", profile: "standard",
               accommodations: [], supportNote: ""),
    ]

    // MARK: - Poem response assignment

    /// "Dust of Snow" by Robert Frost (1923). Public domain in the United States.
    static let dustOfSnow: String = """
    The way a crow
    Shook down on me
    The dust of snow
    From a hemlock tree

    Has given my heart
    A change of mood
    And saved some part
    Of a day I had rued.
    """

    static let poemResponsePrompt: String = "What does the speaker’s mood shift in “Dust of Snow” suggest about how small moments can change a day? Use at least one quotation."

    static let poemResponses: [Entry] = [
        // Strong
        Entry(
            studentName: "Amara Diallo",
            text: """
            In “Dust of Snow,” Robert Frost shows that a tiny, almost silly moment can rescue a day that seemed ruined. At the start, the speaker is in a bad mood. We know this because the last line says it was “a day I had rued,” which means a day he regretted. Then a crow shakes snow off a hemlock branch onto him. That’s it. Nothing dramatic happens, but it “has given my heart / A change of mood.”

            What I find interesting is that the crow and the hemlock are usually gloomy symbols. Crows can stand for bad luck, and hemlock is a poison. Frost takes two dark images and turns them into the thing that cheers the speaker up. This suggests that good moments don’t have to look pretty to matter.

            The speaker also says it “saved some part” of the day, not the whole day. I think that is realistic. One small moment doesn’t fix everything, but it can be enough to shift how you feel for the rest of the afternoon. The poem is only eight lines long, which fits its message: something short and small can still make a difference.
            """,
            profileHint: "Exemplary"
        ),

        // Developing
        Entry(
            studentName: "Theo Lindqvist",
            text: """
            The poem Dust of Snow is about a guy who is having a bad day and then a crow knocks snow on him and he feels better. I think the mood shift shows that small things can change your whole day. At first he is sad and at the end he is happy.

            The poem says “Has given my heart a change of mood.” This means that he was in one mood and then it changed to a different mood. The snow falling on him was a small thing but it made him happy. I think this is true in real life to. Like one time I was having a bad day becuase I failed a quiz but then my friend made a joke at lunch and I felt way better and the rest of the day was ok.

            So the poem is saying that you should notice small things because they can make you feel better even if your having a bad day. Frost is saying small moments matter alot.
            """,
            profileHint: "Developing — analysis"
        ),

        // Solid / mid
        Entry(
            studentName: "Sofia Petrova",
            text: """
            The mood shift in “Dust of Snow” suggests that small, unexpected moments can change how we feel about an entire day. In the beginning the speaker is upset, and the last line tells us he had “rued” the day, meaning he regretted it or wished it hadn’t happened.

            The change comes from something very simple. A crow “shook down on me / The dust of snow / From a hemlock tree.” The word “dust” makes the snow sound light and small, like it barely matters. But this tiny moment is what changes his heart. I think Frost is showing that we don’t always need something big to feel better. Sometimes nature surprises us and pulls us out of our own thoughts.

            The poem also says the moment “saved some part” of his day. So the shift is not complete, but it is enough. This suggests that even on a bad day, we can still have good moments if we pay attention to them.
            """,
            profileHint: "Solid"
        ),
    ]
}
