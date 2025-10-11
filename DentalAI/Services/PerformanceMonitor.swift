import Foundation
import UIKit

// MARK: - Performance Monitor Protocol
protocol PerformanceMonitorProtocol {
    func startTiming(_ operation: String)
    func endTiming(_ operation: String)
    func getPerformanceMetrics() -> PerformanceMetrics
    func logMemoryUsage()
    func logCPUUsage()
}

// MARK: - Performance Monitor Implementation
class PerformanceMonitor: ObservableObject, PerformanceMonitorProtocol {
    
    // MARK: - Properties
    private var timingOperations: [String: CFAbsoluteTime] = [:]
    private var performanceHistory: [PerformanceEntry] = []
    private let maxHistorySize = 100
    
    // MARK: - Timing Operations
    func startTiming(_ operation: String) {
        timingOperations[operation] = CFAbsoluteTimeGetCurrent()
    }
    
    func endTiming(_ operation: String) {
        guard let startTime = timingOperations[operation] else {
            print("Warning: No start time found for operation: \(operation)")
            return
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        let entry = PerformanceEntry(
            operation: operation,
            duration: duration,
            timestamp: Date(),
            memoryUsage: getCurrentMemoryUsage(),
            cpuUsage: getCurrentCPUUsage()
        )
        
        performanceHistory.append(entry)
        
        // Keep history size manageable
        if performanceHistory.count > maxHistorySize {
            performanceHistory.removeFirst()
        }
        
        timingOperations.removeValue(forKey: operation)
        
        // Log performance if operation takes too long
        if duration > 1.0 {
            print("Performance Warning: \(operation) took \(String(format: "%.2f", duration)) seconds")
        }
    }
    
    // MARK: - Performance Metrics
    func getPerformanceMetrics() -> PerformanceMetrics {
        let totalOperations = performanceHistory.count
        let averageDuration = performanceHistory.isEmpty ? 0.0 : performanceHistory.map { $0.duration }.reduce(0, +) / Double(totalOperations)
        
        let slowOperations = performanceHistory.filter { $0.duration > 1.0 }
        let fastOperations = performanceHistory.filter { $0.duration < 0.5 }
        
        let operationBreakdown = Dictionary(grouping: performanceHistory, by: { $0.operation })
            .mapValues { entries in
                let durations = entries.map { $0.duration }
                return OperationMetrics(
                    count: entries.count,
                    averageDuration: durations.reduce(0, +) / Double(durations.count),
                    minDuration: durations.min() ?? 0.0,
                    maxDuration: durations.max() ?? 0.0
                )
            }
        
        return PerformanceMetrics(
            totalOperations: totalOperations,
            averageDuration: averageDuration,
            slowOperations: slowOperations.count,
            fastOperations: fastOperations.count,
            operationBreakdown: operationBreakdown,
            memoryUsage: getCurrentMemoryUsage(),
            cpuUsage: getCurrentCPUUsage(),
            lastUpdated: Date()
        )
    }
    
    // MARK: - Memory Monitoring
    func logMemoryUsage() {
        let memoryUsage = getCurrentMemoryUsage()
        print("Memory Usage: \(String(format: "%.2f", memoryUsage)) MB")
    }
    
    private func getCurrentMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / 1024.0 / 1024.0 // Convert to MB
        } else {
            return 0.0
        }
    }
    
    // MARK: - CPU Monitoring
    func logCPUUsage() {
        let cpuUsage = getCurrentCPUUsage()
        print("CPU Usage: \(String(format: "%.2f", cpuUsage))%")
    }
    
    private func getCurrentCPUUsage() -> Double {
        var info = processor_info_array_t.allocate(capacity: 1)
        var numCpuInfo: mach_msg_type_number_t = 0
        var numCpus: natural_t = 0
        
        let result = host_processor_info(mach_host_self(),
                                        PROCESSOR_CPU_LOAD_INFO,
                                        &numCpus,
                                        &info,
                                        &numCpuInfo)
        
        if result == KERN_SUCCESS {
            let cpuInfo = info.withMemoryRebound(to: processor_cpu_load_info_t.self, capacity: Int(numCpus)) {
                $0
            }
            
            var totalUser: UInt32 = 0
            var totalSystem: UInt32 = 0
            var totalIdle: UInt32 = 0
            
            for i in 0..<Int(numCpus) {
                totalUser += cpuInfo[i].cpu_ticks.0
                totalSystem += cpuInfo[i].cpu_ticks.1
                totalIdle += cpuInfo[i].cpu_ticks.2
            }
            
            let total = totalUser + totalSystem + totalIdle
            let usage = Double(totalUser + totalSystem) / Double(total) * 100.0
            
            return usage
        } else {
            return 0.0
        }
    }
    
    // MARK: - Performance Analysis
    func analyzePerformance() -> PerformanceAnalysis {
        let metrics = getPerformanceMetrics()
        let slowestOperation = performanceHistory.max { $0.duration < $1.duration }
        let fastestOperation = performanceHistory.min { $0.duration < $1.duration }
        
        let recommendations = generateRecommendations(metrics: metrics)
        
        return PerformanceAnalysis(
            metrics: metrics,
            slowestOperation: slowestOperation,
            fastestOperation: fastestOperation,
            recommendations: recommendations
        )
    }
    
    private func generateRecommendations(metrics: PerformanceMetrics) -> [PerformanceRecommendation] {
        var recommendations: [PerformanceRecommendation] = []
        
        if metrics.averageDuration > 2.0 {
            recommendations.append(PerformanceRecommendation(
                type: .optimization,
                priority: .high,
                title: "Optimize Slow Operations",
                description: "Average operation duration is \(String(format: "%.2f", metrics.averageDuration)) seconds. Consider optimizing image processing algorithms.",
                action: "Review and optimize image processing pipeline"
            ))
        }
        
        if metrics.slowOperations > metrics.totalOperations * 0.2 {
            recommendations.append(PerformanceRecommendation(
                type: .optimization,
                priority: .medium,
                title: "Reduce Slow Operations",
                description: "\(metrics.slowOperations) operations are taking longer than 1 second.",
                action: "Implement background processing for heavy operations"
            ))
        }
        
        if metrics.memoryUsage > 100.0 {
            recommendations.append(PerformanceRecommendation(
                type: .memory,
                priority: .high,
                title: "High Memory Usage",
                description: "Memory usage is \(String(format: "%.2f", metrics.memoryUsage)) MB. Consider implementing memory management.",
                action: "Implement image caching and memory cleanup"
            ))
        }
        
        if metrics.cpuUsage > 80.0 {
            recommendations.append(PerformanceRecommendation(
                type: .cpu,
                priority: .medium,
                title: "High CPU Usage",
                description: "CPU usage is \(String(format: "%.2f", metrics.cpuUsage))%. Consider optimizing algorithms.",
                action: "Use background queues for CPU-intensive operations"
            ))
        }
        
        return recommendations
    }
    
    // MARK: - Export Performance Data
    func exportPerformanceData() -> Data? {
        let exportData = PerformanceExportData(
            performanceHistory: performanceHistory,
            metrics: getPerformanceMetrics(),
            analysis: analyzePerformance(),
            exportDate: Date()
        )
        
        return try? JSONEncoder().encode(exportData)
    }
}

// MARK: - Supporting Types
struct PerformanceEntry: Identifiable, Codable {
    let id = UUID()
    let operation: String
    let duration: Double
    let timestamp: Date
    let memoryUsage: Double
    let cpuUsage: Double
}

struct PerformanceMetrics: Codable {
    let totalOperations: Int
    let averageDuration: Double
    let slowOperations: Int
    let fastOperations: Int
    let operationBreakdown: [String: OperationMetrics]
    let memoryUsage: Double
    let cpuUsage: Double
    let lastUpdated: Date
}

struct OperationMetrics: Codable {
    let count: Int
    let averageDuration: Double
    let minDuration: Double
    let maxDuration: Double
}

struct PerformanceAnalysis: Codable {
    let metrics: PerformanceMetrics
    let slowestOperation: PerformanceEntry?
    let fastestOperation: PerformanceEntry?
    let recommendations: [PerformanceRecommendation]
}

struct PerformanceRecommendation: Identifiable, Codable {
    let id = UUID()
    let type: RecommendationType
    let priority: Priority
    let title: String
    let description: String
    let action: String
    
    enum RecommendationType: String, Codable, CaseIterable {
        case optimization = "Optimization"
        case memory = "Memory"
        case cpu = "CPU"
        case network = "Network"
    }
    
    enum Priority: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
    }
}

struct PerformanceExportData: Codable {
    let performanceHistory: [PerformanceEntry]
    let metrics: PerformanceMetrics
    let analysis: PerformanceAnalysis
    let exportDate: Date
}

// MARK: - Performance Monitoring Extensions
extension PerformanceMonitor {
    
    // MARK: - Image Processing Performance
    func monitorImageProcessing<T>(_ operation: String, block: () async throws -> T) async throws -> T {
        startTiming(operation)
        defer { endTiming(operation) }
        
        return try await block()
    }
    
    // MARK: - ML Inference Performance
    func monitorMLInference<T>(_ operation: String, block: () async throws -> T) async throws -> T {
        startTiming("ML_\(operation)")
        defer { endTiming("ML_\(operation)") }
        
        return try await block()
    }
    
    // MARK: - Network Performance
    func monitorNetworkOperation<T>(_ operation: String, block: () async throws -> T) async throws -> T {
        startTiming("Network_\(operation)")
        defer { endTiming("Network_\(operation)") }
        
        return try await block()
    }
}
