import Foundation

extension LanguageModule {
    public static let swedish = LanguageModule(
        id: "sv", name: "Swedish", nativeName: "Svenska", variety: "Sweden", locale: "sv-SE",
        greeting: "Hej!", greetingWord: "hej",
        speechGuidance: "Use clear, natural standard Swedish as spoken in Sweden, with everyday du and ni for plural address. Prioritize intelligible word stress, sentence rhythm and the contrast between a long vowel with a short following consonant and a short vowel with a long following consonant. Model distinct Swedish vowel sounds, including y and u, and natural sj and tj sounds. Model pitch accents naturally without making native-like pitch accent a prerequisite for communication. Accept valid regional Swedish, including Finland-Swedish, and do not treat an accent or regional pronunciation alone as an error. Do not imitate a regional caricature or infer stress, vowel length, consonant length or pitch-accent errors from a transcript alone. Welcome French, English or mixed learner replies as support and bridge back to a useful Swedish phrase while keeping your own speech in Swedish.",
        writingGuidance: "Use contemporary standard Swedish spelling and punctuation. Preserve the distinct letters å, ä and ö, including Å, Ä and Ö; they are not interchangeable with a or o. Write ordinary compounds together, for example sjuksköterska and tågstation. Model de and dem in standard written Swedish, but accept established conversational dom without calling it a spoken grammar error. Accept valid regional wording and equivalent composed or decomposed Unicode text. Preserve the learner's exact spelling and quotations when recording evidence.",
        lemmaGuidance: "Give count nouns with their singular indefinite article, for example en bok and ett hus, and verbs with att plus the infinitive, for example att läsa. Map definite and plural forms to the same singular lemma when their sense is the same. Swedish en/ett is common versus neuter gender, not masculine versus feminine; do not infer it from a French or English translation. Preserve å, ä and ö and keep different senses distinct. Keep reflexive and particle verbs as meaningful phrases, for example att känna sig and att tycka om, rather than losing the pronoun or particle. Leave the observed form and exact quotation unchanged.",
        teachingFocus: [
            "Greetings, introductions, useful everyday chunks such as jag heter and jag skulle vilja, and asking someone to repeat or speak more slowly.",
            "Everyday questions and requests, en/ett with useful nouns, definite endings, common plurals and present-tense verbs that do not change with the subject.",
            "Connected everyday stories, preterite and perfect in context, modal verbs with infinitives, adjective agreement and verb-second word order after a time or place phrase.",
            "Reasons, opinions and plans, subordinate-clause word order and the placement of inte, comparisons and natural connectors.",
            "Nuanced discussion, particle verbs, reflexive possessives sin/sitt/sina, idiomatic chunks, register and valid regional variation.",
            "Flexible advanced conversation with precise, natural Swedish, including hypothetical situations, passive constructions, argumentation and appropriate tone."
        ],
        topicPlaceholder: "Fika, music, travel, life in Sweden…",
        lookupUnavailableReply: "Jag kunde inte kolla det just nu. Vi kan prata om ämnet i allmänhet, om du vill.",
        themeOverrides: [
            "coffee": .init("coffee", "Fika?", "Coffee and a little chat", "cup.and.saucer", "Everyday", "Meet for an imagined fika in Sweden. Help the learner order a drink and something to eat, then chat about their day. Model friendly requests without presenting one custom as universal.", 0),
            "groceries": .init("groceries", "Handla lite", "Something for dinner", "basket", "Everyday", "Visit an imagined Swedish grocery shop or market. Practise quantities, prices, en/ett and useful food words, then ask what the learner likes to cook.", 2),
            "travel": .init("travel", "Nästa hållplats", "A ticket to somewhere", "tram", "Everyday", "Plan a bus or train trip in Sweden. Practise destinations, directions and tickets without inventing current routes, fares or schedules.", 1),
            "weather": .init("weather", "Vilket väder!", "A little fresh air", "cloud.rain", "Local life", "Discuss weather, clothing and outdoor plans in Sweden. Explore the learner's preferences and verify current forecasts before claiming them.", 1),
            "cabin": .init("cabin", "En helg i stugan", "A quieter kind of day", "mountain.2", "Local life", "Plan an imagined weekend in a Swedish stuga. Discuss travel, food, walks and relaxing together without assuming every Swedish person owns a cabin.", 2),
            "traditions": .init("traditions", "Livet i Sverige", "Small customs, big stories", "flag", "Local life", "Explore everyday life and customs in Sweden, such as fika or midsummer, and compare the learner's own experiences. Describe variation and avoid treating all Swedish people as alike.", 2)
        ]
    )
}
