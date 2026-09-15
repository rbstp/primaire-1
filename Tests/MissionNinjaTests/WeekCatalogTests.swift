import Foundation
import Testing

@testable import MissionNinja

private func week(id: String) -> Week {
    Week(
        schema: 1,
        id: id,
        title: "Semaine \(id)",
        grade: "1re année",
        teacher: "Mme Catherine",
        days: [SchoolDay(name: "lundi", atSchool: true, note: nil)],
        letters: LetterPlan(vowels: ["a"], alphabet: true),
        numbers: NumberPlan(from: 0, to: 9, counting: true),
        tracing: ["a"],
        names: [],
        tasks: []
    )
}

@Suite struct WeekCatalogTests {
    @Test func sortsNewestFirst() {
        let catalog = WeekCatalog(weeks: [week(id: "2026-09-07"), week(id: "2026-09-21"), week(id: "2026-09-14")])
        #expect(catalog.weeks.map(\.id) == ["2026-09-21", "2026-09-14", "2026-09-07"])
        #expect(catalog.newest?.id == "2026-09-21")
    }

    @Test func opensOnTheWeekAlreadyUnderway() {
        let catalog = WeekCatalog(weeks: [week(id: "2026-09-07"), week(id: "2026-09-14"), week(id: "2026-09-21")])
        let wednesday = DayKey(year: 2026, month: 9, day: 16)
        #expect(catalog.current(on: wednesday)?.id == "2026-09-14")
    }

    @Test func opensOnTheMondayItself() {
        let catalog = WeekCatalog(weeks: [week(id: "2026-09-07"), week(id: "2026-09-14")])
        #expect(catalog.current(on: DayKey(year: 2026, month: 9, day: 14))?.id == "2026-09-14")
    }

    @Test func fallsBackToTheNewestBeforeTheYearStarts() {
        let catalog = WeekCatalog(weeks: [week(id: "2026-09-07"), week(id: "2026-09-14")])
        #expect(catalog.current(on: DayKey(year: 2026, month: 8, day: 30))?.id == "2026-09-14")
    }

    @Test func isEmptyWithoutWeeks() {
        #expect(WeekCatalog(weeks: []).current(on: DayKey(year: 2026, month: 9, day: 8)) == nil)
    }

    /// Older week files carry no names and no focus.
    @Test func decodesAWeekWithoutNamesOrFocus() throws {
        let payload = Data(#"{"schema":1,"id":"2026-09-14","title":"x","grade":"x","teacher":"x","days":[],"letters":{"vowels":["a"],"alphabet":true},"numbers":{"from":0,"to":9,"counting":true},"tracing":[],"tasks":[]}"#.utf8)
        let week = try #require(WeekCatalog.decode(from: [payload]).weeks.first)
        #expect(week.names.isEmpty)
        #expect(week.numbers.focus == nil)
        #expect(week.numbers.focused.isEmpty)
    }

    /// Two children with the same first name are one card on the bus.
    @Test func keepsEachNameOnce() {
        let week = Week(
            schema: 1, id: "2026-09-07", title: "x", grade: "x", teacher: "x", days: [],
            letters: LetterPlan(vowels: ["a"], alphabet: true),
            numbers: NumberPlan(from: 0, to: 9, counting: true),
            tracing: [], names: ["Noah", "Zoé", "Noah"], tasks: []
        )
        #expect(week.names == ["Noah", "Zoé"])
    }

    @Test func skipsFilesFromAFutureSchema() {
        let payload = Data(#"{"schema":99,"id":"2027-01-04","title":"x","grade":"x","teacher":"x","days":[],"letters":{"vowels":["a"],"alphabet":true},"numbers":{"from":0,"to":9,"counting":true},"tracing":[],"tasks":[]}"#.utf8)
        #expect(WeekCatalog.decode(from: [payload]).weeks.isEmpty)
    }

    @Test func decodesTheShippedWeek() throws {
        let shipped = try #require(WeekCatalog.bundled().week(id: "2026-09-07"))
        #expect(shipped.letters.vowels == ["a", "e", "i", "o", "u", "y"])
        #expect(shipped.numbers.digits == Array(0...20))
        #expect(shipped.numbers.focused == Array(10...20))
        #expect(shipped.schoolDays.count == 4)
        #expect(shipped.tracing.count == 15)
        #expect(shipped.names.count == 22)
        #expect(shipped.names.contains("Mme Catherine"))
        #expect(shipped.days.first?.note == "Congé, Fête du travail")
        #expect(shipped.monday == DayKey(year: 2026, month: 9, day: 7))
    }

    /// The second week adds the sounds f and j, stops the numbers at 12, and
    /// is the first full week of school.
    @Test func decodesTheSecondWeek() throws {
        let shipped = try #require(WeekCatalog.bundled().week(id: "2026-09-14"))
        #expect(shipped.letters.vowels == ["a", "e", "i", "o", "u", "y", "f", "j"])
        #expect(shipped.numbers.digits == Array(0...12))
        #expect(shipped.numbers.focus == nil)
        #expect(shipped.schoolDays.count == 5)
        #expect(shipped.names.count == 22)
        #expect(!shipped.hasWords)
        #expect(shipped.monday == DayKey(year: 2026, month: 9, day: 14))
    }

    /// Every drill draws its decoys from the week, so a week with nothing to
    /// drill would open a dojo with no tile on it. Two tasks sharing an id
    /// share a tick, so ticking one would tick the other.
    @Test func everyShippedWeekIsPlayable() {
        let weeks = WeekCatalog.bundled().weeks
        #expect(!weeks.isEmpty)
        for week in weeks {
            #expect(week.hasLetters || week.hasNumbers || week.hasWords, "\(week.id)")
            #expect(!week.tasks.isEmpty, "\(week.id)")
            #expect(Set(week.tasks.map(\.id)).count == week.tasks.count, "\(week.id)")
        }
    }

    /// The plan hands the f to Monday and Tuesday and the j to Wednesday and
    /// Thursday, so the carnet only shows each on its own days.
    @Test func aTaskGivenToCertainDaysStaysOnThem() throws {
        let shipped = try #require(WeekCatalog.bundled().week(id: "2026-09-14"))
        let f = try #require(shipped.tasks.first { $0.id == "son-f" })
        #expect(f.runs(on: SchoolDay(name: "lundi", atSchool: true, note: nil)))
        #expect(!f.runs(on: SchoolDay(name: "jeudi", atSchool: true, note: nil)))
    }

    /// A task left with no days runs all week, which is what most of them do.
    @Test func aTaskWithoutDaysRunsAllWeek() throws {
        let shipped = try #require(WeekCatalog.bundled().week(id: "2026-09-14"))
        let alphabet = try #require(shipped.tasks.first { $0.id == "chanson-alphabet" })
        #expect(shipped.schoolDays.allSatisfy(alphabet.runs(on:)))
    }

    /// A day the week does not go to would take its task off the carnet
    /// without a word, and a whole line of the plan would go missing. A day
    /// off counts as one of those: the carnet lists nothing under it.
    @Test func everyTaskDayIsASchoolDayOfItsWeek() {
        let weeks = WeekCatalog.bundled().weeks
        #expect(!weeks.isEmpty)
        for week in weeks {
            let known = Set(week.homeworkDays.map(\.name))
            for task in week.tasks {
                for day in task.days ?? [] {
                    #expect(known.contains(day), "\(week.id): \(task.id) vise \(day)")
                }
            }
        }
    }

    /// The lesson grid stops at Thursday on both weeks shipped so far, and
    /// Friday sends the pochette back to school with nothing to do at home.
    @Test func fridayCarriesNoHomework() {
        for week in WeekCatalog.bundled().weeks {
            #expect(week.homeworkDays.map(\.name) == ["lundi", "mardi", "mercredi", "jeudi"].filter { name in
                week.schoolDays.contains { $0.name == name }
            }, "\(week.id)")
        }
    }

    /// An empty list is a line written down, not a line to hide, so it runs
    /// all week like a task with no days at all.
    @Test func anEmptyDayListStillRunsAllWeek() {
        let task = HomeworkTask(id: "x", title: "x", place: nil, days: [])
        #expect(task.runs(on: SchoolDay(name: "lundi", atSchool: true, note: nil)))
    }
}
