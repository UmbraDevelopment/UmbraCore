import Foundation
import UmbraErrors

/// Protocol defining scheduling service functionality
public protocol SchedulingServiceProtocol: Sendable {
  /// Create a new schedule
  /// - Parameter schedule: The schedule configuration to create
  /// - Returns: Result containing the created schedule with assigned ID or an error
  func createSchedule(_ schedule: ScheduleDTO) async -> Result<ScheduleDTO, UmbraErrors.ErrorDTO>

  /// Update an existing schedule
  /// - Parameter schedule: The schedule to update
  /// - Returns: Result containing the updated schedule or an error
  func updateSchedule(_ schedule: ScheduleDTO) async -> Result<ScheduleDTO, UmbraErrors.ErrorDTO>

  /// Delete a schedule by ID
  /// - Parameter scheduleID: The ID of the schedule to delete
  /// - Returns: Success or error result
  func deleteSchedule(withID scheduleID: String) async -> Result<Void, UmbraErrors.ErrorDTO>

  /// Get a schedule by ID
  /// - Parameter scheduleID: The ID of the schedule to retrieve
  /// - Returns: Result containing the schedule or an error
  func getSchedule(withID scheduleID: String) async -> Result<ScheduleDTO, UmbraErrors.ErrorDTO>

  /// List all schedules
  /// - Returns: Result containing array of schedules or an error
  func listSchedules() async -> Result<[ScheduleDTO], UmbraErrors.ErrorDTO>

  /// List all schedules of a specific frequency
  /// - Parameter frequency: The frequency to filter by
  /// - Returns: Result containing filtered schedules or an error
  func listSchedules(withFrequency frequency: ScheduleDTO.Frequency) async
    -> Result<[ScheduleDTO], UmbraErrors.ErrorDTO>

  /// Enable a schedule
  /// - Parameter scheduleID: The ID of the schedule to enable
  /// - Returns: Success or error result
  func enableSchedule(withID scheduleID: String) async -> Result<Void, UmbraErrors.ErrorDTO>

  /// Disable a schedule
  /// - Parameter scheduleID: The ID of the schedule to disable
  /// - Returns: Success or error result
  func disableSchedule(withID scheduleID: String) async -> Result<Void, UmbraErrors.ErrorDTO>

  /// Create a new scheduled task
  /// - Parameter task: The task configuration to create
  /// - Returns: Result containing the created task or an error
  func createTask(_ task: ScheduledTaskDTO) async -> Result<ScheduledTaskDTO, UmbraErrors.ErrorDTO>

  /// Update an existing scheduled task
  /// - Parameter task: The task to update
  /// - Returns: Result containing the updated task or an error
  func updateTask(_ task: ScheduledTaskDTO) async -> Result<ScheduledTaskDTO, UmbraErrors.ErrorDTO>

  /// Delete a task by ID
  /// - Parameter taskID: The ID of the task to delete
  /// - Returns: Success or error result
  func deleteTask(withID taskID: String) async -> Result<Void, UmbraErrors.ErrorDTO>

  /// Get a task by ID
  /// - Parameter taskID: The ID of the task to retrieve
  /// - Returns: Result containing the task or an error
  func getTask(withID taskID: String) async -> Result<ScheduledTaskDTO, UmbraErrors.ErrorDTO>

  /// List all tasks
  /// - Returns: Result containing array of tasks or an error
  func listTasks() async -> Result<[ScheduledTaskDTO], UmbraErrors.ErrorDTO>

  /// List tasks by status
  /// - Parameter status: The status to filter by
  /// - Returns: Result containing filtered tasks or an error
  func listTasks(withStatus status: ScheduledTaskDTO.TaskStatus) async
    -> Result<[ScheduledTaskDTO], UmbraErrors.ErrorDTO>

  /// List tasks for a specific schedule
  /// - Parameter scheduleID: The ID of the schedule to get tasks for
  /// - Returns: Result containing tasks for the schedule or an error
  func listTasks(forSchedule scheduleID: String) async
    -> Result<[ScheduledTaskDTO], UmbraErrors.ErrorDTO>

  /// Cancel a running task
  /// - Parameter taskID: The ID of the task to cancel
  /// - Returns: Success or error result
  func cancelTask(withID taskID: String) async -> Result<Void, UmbraErrors.ErrorDTO>

  /// Calculate the next run time for a schedule
  /// - Parameter schedule: The schedule to calculate for
  /// - Returns: Result containing the next run date or an error
  func calculateNextRunTime(for schedule: ScheduleDTO) async -> Result<Date, UmbraErrors.ErrorDTO>

  /// Register a callback for task status changes
  /// - Parameters:
  ///   - taskID: The ID of the task to monitor
  ///   - callback: Function to call when status changes
  /// - Returns: Registration ID to use for unregistering
  func registerForTaskUpdates(
    taskID: String,
    callback: @Sendable @escaping (ScheduledTaskDTO) -> Void
  ) -> String

  /// Unregister a previously registered callback
  /// - Parameter registrationID: The registration ID to remove
  func unregisterTaskUpdates(registrationID: String)
}
