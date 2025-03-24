@testable import CoreDTOs
import Foundation
import XCTest

final class SchedulingDTOTests: XCTestCase {
  // MARK: - ScheduleDTO Tests

  func testScheduleDTOInitialization() {
    // Arrange & Act
    let schedule=ScheduleDTO(
      frequencyType: .daily,
      startTimestamp: 1_620_000_000,
      endTimestamp: 1_630_000_000,
      windowStartTime: 28800, // 8 AM
      windowEndTime: 72000, // 8 PM
      maxRuns: 10,
      enabled: true
    )

    // Assert
    XCTAssertEqual(schedule.frequencyType, .daily)
    XCTAssertEqual(schedule.startTimestamp, 1_620_000_000)
    XCTAssertEqual(schedule.endTimestamp, 1_630_000_000)
    XCTAssertEqual(schedule.windowStartTime, 28800)
    XCTAssertEqual(schedule.windowEndTime, 72000)
    XCTAssertEqual(schedule.maxRuns, 10)
    XCTAssertTrue(schedule.enabled)
  }

  func testScheduleDTOFactoryMethods() {
    // Test daily schedule
    let daily=ScheduleDTO.daily(
      startTimestamp: 1_620_000_000,
      windowStartTime: 28800 // 8 AM
    )

    XCTAssertEqual(daily.frequencyType, .daily)
    XCTAssertEqual(daily.startTimestamp, 1_620_000_000)
    XCTAssertEqual(daily.windowStartTime, 28800)
    XCTAssertTrue(daily.enabled)

    // Test weekly schedule
    let weekly=ScheduleDTO.weekly(
      startTimestamp: 1_620_000_000,
      windowStartTime: 28800 // 8 AM
    )

    XCTAssertEqual(weekly.frequencyType, .weekly)
    XCTAssertEqual(weekly.startTimestamp, 1_620_000_000)
    XCTAssertEqual(weekly.windowStartTime, 28800)
    XCTAssertTrue(weekly.enabled)

    // Test monthly schedule
    let monthly=ScheduleDTO.monthly(
      startTimestamp: 1_620_000_000,
      windowStartTime: 28800 // 8 AM
    )

    XCTAssertEqual(monthly.frequencyType, .monthly)
    XCTAssertEqual(monthly.startTimestamp, 1_620_000_000)
    XCTAssertEqual(monthly.windowStartTime, 28800)
    XCTAssertTrue(monthly.enabled)
  }

  func testScheduleDTODateConverters() {
    // Arrange
    let currentDate=Date()
    let calendar=Calendar.current

    // Calculate 8 AM today
    var components=calendar.dateComponents([.year, .month, .day], from: currentDate)
    components.hour=8
    components.minute=0
    components.second=0
    let eightAM=calendar.date(from: components)!

    // Calculate 6 PM today
    components.hour=18
    let sixPM=calendar.date(from: components)!

    // Act
    let schedule=ScheduleDTO.fromDates(
      frequencyType: .daily,
      startDate: currentDate,
      windowStartTime: eightAM,
      windowEndTime: sixPM,
      maxRuns: 5,
      enabled: true
    )

    // Assert
    XCTAssertEqual(schedule.frequencyType, .daily)
    XCTAssertEqual(schedule.startTimestamp, UInt64(currentDate.timeIntervalSince1970))

    // Window start should be 8 AM = 8 hours * 3600 seconds = 28800 seconds from midnight
    XCTAssertEqual(schedule.windowStartTime, 8 * 3600)

    // Window end should be 6 PM = 18 hours * 3600 seconds = 64800 seconds from midnight
    XCTAssertEqual(schedule.windowEndTime, 18 * 3600)

    XCTAssertEqual(schedule.maxRuns, 5)
    XCTAssertTrue(schedule.enabled)

    // Test conversion back to dates
    let startDate=schedule.startDate()
    XCTAssertEqual(
      Int(startDate.timeIntervalSince1970),
      Int(currentDate.timeIntervalSince1970),
      accuracy: 1
    )

    // Verify window start time conversion
    if let windowStartDate=schedule.windowStartDate() {
      let startComponents=calendar.dateComponents([.hour, .minute, .second], from: windowStartDate)
      XCTAssertEqual(startComponents.hour, 8)
      XCTAssertEqual(startComponents.minute, 0)
      XCTAssertEqual(startComponents.second, 0)
    } else {
      XCTFail("Window start date should not be nil")
    }

    // Verify window end time conversion
    if let windowEndDate=schedule.windowEndDate() {
      let endComponents=calendar.dateComponents([.hour, .minute, .second], from: windowEndDate)
      XCTAssertEqual(endComponents.hour, 18)
      XCTAssertEqual(endComponents.minute, 0)
      XCTAssertEqual(endComponents.second, 0)
    } else {
      XCTFail("Window end date should not be nil")
    }
  }

  // MARK: - ScheduledTaskDTO Tests

  func testScheduledTaskDTOInitialization() {
    // Arrange
    let schedule=ScheduleDTO.daily(
      startTimestamp: 1_620_000_000,
      windowStartTime: 28800 // 8 AM
    )

    // Act
    let task=ScheduledTaskDTO(
      taskID: "backup-task-123",
      schedule: schedule,
      status: .idle,
      configData: [
        "backupType": "full",
        "source": "/Users/data"
      ],
      lastRunTimestamp: 1_625_000_000,
      nextRunTimestamp: 1_625_086_400,
      creationTimestamp: 1_620_000_000,
      runCount: 5
    )

    // Assert
    XCTAssertEqual(task.taskID, "backup-task-123")
    XCTAssertEqual(task.schedule, schedule)
    XCTAssertEqual(task.status, .idle)
    XCTAssertEqual(task.configData["backupType"], "full")
    XCTAssertEqual(task.configData["source"], "/Users/data")
    XCTAssertEqual(task.lastRunTimestamp, 1_625_000_000)
    XCTAssertEqual(task.nextRunTimestamp, 1_625_086_400)
    XCTAssertEqual(task.creationTimestamp, 1_620_000_000)
    XCTAssertEqual(task.runCount, 5)
  }

  func testScheduledTaskDTODateConversion() {
    // Arrange
    let now=Date()
    let lastRun=now.addingTimeInterval(-24 * 3600) // Yesterday
    let nextRun=now.addingTimeInterval(24 * 3600) // Tomorrow

    // Create schedule
    let schedule=ScheduleDTO.fromDates(
      frequencyType: .daily,
      startDate: now.addingTimeInterval(-7 * 24 * 3600) // A week ago
    )

    // Act
    let task=ScheduledTaskDTO.fromDates(
      taskID: "test-task",
      schedule: schedule,
      status: .idle,
      configData: ["key": "value"],
      lastRunDate: lastRun,
      nextRunDate: nextRun,
      creationDate: now
    )

    // Assert
    XCTAssertEqual(task.taskID, "test-task")
    XCTAssertEqual(task.status, .idle)
    XCTAssertEqual(task.configData["key"], "value")

    // Verify date conversions
    XCTAssertEqual(UInt64(lastRun.timeIntervalSince1970), task.lastRunTimestamp)
    XCTAssertEqual(UInt64(nextRun.timeIntervalSince1970), task.nextRunTimestamp)
    XCTAssertEqual(UInt64(now.timeIntervalSince1970), task.creationTimestamp)

    // Verify conversion back to dates
    XCTAssertEqual(
      Int(task.lastRunDate()!.timeIntervalSince1970),
      Int(lastRun.timeIntervalSince1970),
      accuracy: 1
    )
    XCTAssertEqual(
      Int(task.nextRunDate()!.timeIntervalSince1970),
      Int(nextRun.timeIntervalSince1970),
      accuracy: 1
    )
    XCTAssertEqual(
      Int(task.creationDate().timeIntervalSince1970),
      Int(now.timeIntervalSince1970),
      accuracy: 1
    )
  }

  func testScheduledTaskDTOCalculateNextRun() {
    // Arrange
    let now=Date()
    let calendar=Calendar.current

    // Create an hourly schedule
    let hourlySchedule=ScheduleDTO.hourly(
      startTimestamp: UInt64(now.timeIntervalSince1970) - 3600, // Started an hour ago
      windowStartTime: 8 * 3600, // 8 AM
      windowEndTime: 20 * 3600 // 8 PM
    )

    // Create a daily schedule
    let dailySchedule=ScheduleDTO.daily(
      startTimestamp: UInt64(now.timeIntervalSince1970) - 86400, // Started a day ago
      windowStartTime: 8 * 3600 // 8 AM
    )

    // Create tasks
    let hourlyTask=ScheduledTaskDTO(
      taskID: "hourly-task",
      schedule: hourlySchedule,
      creationTimestamp: UInt64(now.timeIntervalSince1970) - 7200 // Created 2 hours ago
    )

    let dailyTask=ScheduledTaskDTO(
      taskID: "daily-task",
      schedule: dailySchedule,
      creationTimestamp: UInt64(now.timeIntervalSince1970) - 172_800 // Created 2 days ago
    )

    // Act
    let updatedHourlyTask=hourlyTask.calculateNextRun(currentDate: now)
    let updatedDailyTask=dailyTask.calculateNextRun(currentDate: now)

    // Assert

    // For hourly task, the next run should be around 1 hour from now
    guard let hourlyNextRun=updatedHourlyTask.nextRunTimestamp else {
      XCTFail("Hourly task next run timestamp should not be nil")
      return
    }

    let hourlyNextDate=Date(timeIntervalSince1970: TimeInterval(hourlyNextRun))
    let hourlyDiff=hourlyNextDate.timeIntervalSince(now)

    // Next hour should be between 30-90 minutes from now (giving some flexibility for time window
    // logic)
    XCTAssertTrue(
      hourlyDiff >= 30 * 60,
      "Next hourly run should be at least 30 minutes in the future"
    )
    XCTAssertTrue(
      hourlyDiff <= 90 * 60,
      "Next hourly run should be at most 90 minutes in the future"
    )

    // For daily task, the next run should be around 1 day from now
    guard let dailyNextRun=updatedDailyTask.nextRunTimestamp else {
      XCTFail("Daily task next run timestamp should not be nil")
      return
    }

    let dailyNextDate=Date(timeIntervalSince1970: TimeInterval(dailyNextRun))
    let dailyDiff=dailyNextDate.timeIntervalSince(now)

    // Check if the next run is at 8 AM tomorrow
    let components=calendar.dateComponents([.hour, .minute], from: dailyNextDate)
    XCTAssertEqual(components.hour, 8, "Daily task should run at 8 AM")
    XCTAssertEqual(components.minute, 0, "Daily task should run at 8:00 AM")

    // Next day should be between 12-36 hours from now (giving flexibility for time of day)
    XCTAssertTrue(dailyDiff <= 36 * 3600, "Next daily run should be at most 36 hours in the future")
    XCTAssertTrue(
      dailyDiff >= 12 * 3600,
      "Next daily run should be at least 12 hours in the future"
    )
  }

  func testScheduledTaskDTOMaxRunsLimit() {
    // Arrange
    let now=Date()

    // Create a schedule with max 3 runs
    let schedule=ScheduleDTO(
      frequencyType: .daily,
      startTimestamp: UInt64(now.timeIntervalSince1970) - 86400 * 10, // Started 10 days ago
      windowStartTime: 8 * 3600, // 8 AM
      maxRuns: 3,
      enabled: true
    )

    // Create a task that has already run 3 times
    let task=ScheduledTaskDTO(
      taskID: "max-runs-task",
      schedule: schedule,
      status: .idle,
      lastRunTimestamp: UInt64(now.timeIntervalSince1970) - 86400, // Last run yesterday
      creationTimestamp: UInt64(now.timeIntervalSince1970) - 86400 * 10, // Created 10 days ago
      runCount: 3 // Already run 3 times
    )

    // Act
    let updatedTask=task.calculateNextRun(currentDate: now)

    // Assert
    XCTAssertNil(
      updatedTask.nextRunTimestamp,
      "Task with max runs reached should not have a next run time"
    )
  }

  func testScheduledTaskDTODisabledSchedule() {
    // Arrange
    let now=Date()

    // Create a disabled schedule
    let schedule=ScheduleDTO(
      frequencyType: .daily,
      startTimestamp: UInt64(now.timeIntervalSince1970) - 86400, // Started a day ago
      windowStartTime: 8 * 3600, // 8 AM
      enabled: false
    )

    // Create a task with the disabled schedule
    let task=ScheduledTaskDTO(
      taskID: "disabled-task",
      schedule: schedule,
      status: .idle,
      creationTimestamp: UInt64(now.timeIntervalSince1970) - 86400 * 2 // Created 2 days ago
    )

    // Act
    let updatedTask=task.calculateNextRun(currentDate: now)

    // Assert
    XCTAssertNil(
      updatedTask.nextRunTimestamp,
      "Task with disabled schedule should not have a next run time"
    )
  }
}
