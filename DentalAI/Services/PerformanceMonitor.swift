import Foundation
import UIKit
import os.log

// MARK: - Performance Monitor
class PerformanceMonitor {
    
    // MARK: - Properties
    static let shared = PerformanceMonitor()
    private let logger = Logger(subsystem: "com.dentalai.app", category: "Performance")
    
    private var operationTimings: [String: TimeInterval] = [:]
    private var operationCounts: [String: Int] = [:]
    private var memoryUsage: [String: Int64] = [:]
    private var cpuUsage: [String: Double] = [:]
    
    // MARK: - Operation Timing
    func startTiming(operation: String) {
        operationTimings[operation] = Date().timeIntervalSince1970
    }
    
    func endTiming(operation: String) -> TimeInterval {
        guard let startTime = operationTimings[operation] else {
            logger.warning("No start time found for operation: \(operation)")
            return 0
        }
        
        let duration = Date().timeIntervalSince1970 - startTime
        operationTimings.removeValue(forKey: operation)
        
        // Log performance
        logger.info("Operation '\(operation)' completed in \(duration, privacy: .public) seconds")
        
        // Update counts
        operationCounts[operation, default: 0] += 1
        
        return duration
    }
    
    func measureOperation<T>(_ operation: String, block: () throws -> T) rethrows -> T {
        startTiming(operation: operation)
        defer {
            endTiming(operation: operation)
        }
        return try block()
    }
    
    func measureAsyncOperation<T>(_ operation: String, block: () async throws -> T) async rethrows -> T {
        startTiming(operation: operation)
        defer {
            endTiming(operation: operation)
        }
        return try await block()
    }
    
    // MARK: - Memory Monitoring
    func recordMemoryUsage(for operation: String) {
        let memoryInfo = getMemoryInfo()
        memoryUsage[operation] = memoryInfo.used
        logger.info("Memory usage for '\(operation)': \(memoryInfo.used, privacy: .public) bytes")
    }
    
    func getMemoryInfo() -> MemoryInfo {
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
            return MemoryInfo(
                used: Int64(info.resident_size),
                available: Int64(ProcessInfo.processInfo.physicalMemory),
                total: Int64(ProcessInfo.processInfo.physicalMemory)
            )
        } else {
            logger.error("Failed to get memory info: \(kerr)")
            return MemoryInfo(used: 0, available: 0, total: 0)
        }
    }
    
    // MARK: - CPU Monitoring
    func recordCPUUsage(for operation: String) {
        let cpuInfo = getCPUInfo()
        cpuUsage[operation] = cpuInfo.usage
        logger.info("CPU usage for '\(operation)': \(cpuInfo.usage, privacy: .public)%")
    }
    
    func getCPUInfo() -> CPUInfo {
        var info = processor_info_array_t.allocate(capacity: 1)
        var numCpuInfo: mach_msg_type_number_t = 0
        var numCpus: natural_t = 0
        
        let result = host_processor_info(mach_host_self(),
                                        PROCESSOR_CPU_LOAD_INFO,
                                        &numCpus,
                                        &info,
                                        &numCpuInfo)
        
        if result == KERN_SUCCESS {
            let cpuLoadInfo = info.withMemoryRebound(to: processor_cpu_load_info_t.self, capacity: 1) { $0 }
            let usage = Double(cpuLoadInfo.pointee.cpu_ticks.0) / Double(cpuLoadInfo.pointee.cpu_ticks.1) * 100
            
            info.deallocate()
            
            return CPUInfo(
                usage: min(100.0, max(0.0, usage)),
                cores: Int(numCpus)
            )
        } else {
            logger.error("Failed to get CPU info: \(result)")
            return CPUInfo(usage: 0.0, cores: 1)
        }
    }
    
    // MARK: - Performance Metrics
    func getPerformanceMetrics() -> PerformanceMetrics {
        let memoryInfo = getMemoryInfo()
        let cpuInfo = getCPUInfo()
        
        return PerformanceMetrics(
            averageOperationTime: calculateAverageOperationTime(),
            totalOperations: operationCounts.values.reduce(0, +),
            memoryUsage: memoryInfo.used,
            cpuUsage: cpuInfo.usage,
            operationCounts: operationCounts,
            memorySnapshots: memoryUsage,
            cpuSnapshots: cpuUsage
        )
    }
    
    private func calculateAverageOperationTime() -> TimeInterval {
        guard !operationCounts.isEmpty else { return 0 }
        
        let totalTime = operationTimings.values.reduce(0, +)
        let totalCount = operationCounts.values.reduce(0, +)
        
        return totalCount > 0 ? totalTime / Double(totalCount) : 0
    }
    
    // MARK: - Performance Analysis
    func analyzePerformance() -> PerformanceAnalysis {
        let metrics = getPerformanceMetrics()
        var issues: [PerformanceIssue] = []
        var recommendations: [String] = []
        
        // Check for slow operations
        for (operation, count) in operationCounts {
            if let timing = operationTimings[operation] {
                let averageTime = timing / Double(count)
                if averageTime > 5.0 { // 5 seconds threshold
                    issues.append(PerformanceIssue(
                        type: .slowOperation,
                        severity: .high,
                        description: "Operation '\(operation)' is slow (\(averageTime)s average)",
                        recommendation: "Optimize \(operation) operation"
                    ))
                }
            }
        }
        
        // Check memory usage
        let memoryInfo = getMemoryInfo()
        let memoryUsagePercent = Double(memoryInfo.used) / Double(memoryInfo.total) * 100
        
        if memoryUsagePercent > 80 {
            issues.append(PerformanceIssue(
                type: .highMemoryUsage,
                severity: .high,
                description: "High memory usage: \(memoryUsagePercent)%",
                recommendation: "Optimize memory usage and consider memory management"
            ))
        }
        
        // Check CPU usage
        let cpuInfo = getCPUInfo()
        if cpuInfo.usage > 90 {
            issues.append(PerformanceIssue(
                type: .highCPUUsage,
                severity: .medium,
                description: "High CPU usage: \(cpuInfo.usage)%",
                recommendation: "Optimize CPU-intensive operations"
            ))
        }
        
        // Generate recommendations
        if issues.isEmpty {
            recommendations.append("Performance is within acceptable limits")
        } else {
            recommendations.append("Consider optimizing slow operations")
            recommendations.append("Monitor memory usage regularly")
            recommendations.append("Profile CPU-intensive operations")
        }
        
        return PerformanceAnalysis(
            metrics: metrics,
            issues: issues,
            recommendations: recommendations,
            overallScore: calculateOverallScore(issues: issues)
        )
    }
    
    private func calculateOverallScore(issues: [PerformanceIssue]) -> Double {
        let totalIssues = issues.count
        let highSeverityIssues = issues.filter { $0.severity == .high }.count
        let mediumSeverityIssues = issues.filter { $0.severity == .medium }.count
        
        let score = max(0, 100 - (highSeverityIssues * 30) - (mediumSeverityIssues * 15) - (totalIssues * 5))
        return Double(score)
    }
    
    // MARK: - Performance Logging
    func logPerformanceSummary() {
        let analysis = analyzePerformance()
        
        logger.info("Performance Summary:")
        logger.info("Overall Score: \(analysis.overallScore, privacy: .public)")
        logger.info("Total Operations: \(analysis.metrics.totalOperations, privacy: .public)")
        logger.info("Memory Usage: \(analysis.metrics.memoryUsage, privacy: .public) bytes")
        logger.info("CPU Usage: \(analysis.metrics.cpuUsage, privacy: .public)%")
        
        if !analysis.issues.isEmpty {
            logger.warning("Performance Issues Found: \(analysis.issues.count, privacy: .public)")
            for issue in analysis.issues {
                logger.warning("Issue: \(issue.description, privacy: .public)")
            }
        }
    }
    
    // MARK: - Performance Optimization
    func optimizePerformance() -> [String] {
        var optimizations: [String] = []
        let analysis = analyzePerformance()
        
        for issue in analysis.issues {
            switch issue.type {
            case .slowOperation:
                optimizations.append("Optimize \(issue.description)")
            case .highMemoryUsage:
                optimizations.append("Implement memory management strategies")
            case .highCPUUsage:
                optimizations.append("Optimize CPU-intensive operations")
            case .memoryLeak:
                optimizations.append("Fix memory leaks")
            case .inefficientAlgorithm:
                optimizations.append("Replace inefficient algorithms")
            }
        }
        
        return optimizations
    }
    
    // MARK: - Performance Testing
    func runPerformanceTest(_ testName: String, iterations: Int = 100, block: () throws -> Void) rethrows -> PerformanceTestResult {
        var times: [TimeInterval] = []
        var errors: [Error] = []
        
        for i in 0..<iterations {
            let startTime = Date()
            
            do {
                try block()
                let endTime = Date()
                times.append(endTime.timeIntervalSince(startTime))
            } catch {
                errors.append(error)
            }
        }
        
        let averageTime = times.reduce(0, +) / Double(times.count)
        let minTime = times.min() ?? 0
        let maxTime = times.max() ?? 0
        
        return PerformanceTestResult(
            testName: testName,
            iterations: iterations,
            averageTime: averageTime,
            minTime: minTime,
            maxTime: maxTime,
            successRate: Double(times.count) / Double(iterations),
            errors: errors
        )
    }
    
    // MARK: - Cleanup
    func clearMetrics() {
        operationTimings.removeAll()
        operationCounts.removeAll()
        memoryUsage.removeAll()
        cpuUsage.removeAll()
    }
}

// MARK: - Supporting Types
struct MemoryInfo {
    let used: Int64
    let available: Int64
    let total: Int64
    
    var usagePercent: Double {
        return Double(used) / Double(total) * 100
    }
}

struct CPUInfo {
    let usage: Double
    let cores: Int
}

struct PerformanceMetrics {
    let averageOperationTime: TimeInterval
    let totalOperations: Int
    let memoryUsage: Int64
    let cpuUsage: Double
    let operationCounts: [String: Int]
    let memorySnapshots: [String: Int64]
    let cpuSnapshots: [String: Double]
}

enum PerformanceIssueType {
    case slowOperation
    case highMemoryUsage
    case highCPUUsage
    case memoryLeak
    case inefficientAlgorithm
}

enum PerformanceSeverity {
    case low
    case medium
    case high
    case critical
}

struct PerformanceIssue {
    let type: PerformanceIssueType
    let severity: PerformanceSeverity
    let description: String
    let recommendation: String
}

struct PerformanceAnalysis {
    let metrics: PerformanceMetrics
    let issues: [PerformanceIssue]
    let recommendations: [String]
    let overallScore: Double
}

struct PerformanceTestResult {
    let testName: String
    let iterations: Int
    let averageTime: TimeInterval
    let minTime: TimeInterval
    let maxTime: TimeInterval
    let successRate: Double
    let errors: [Error]
}

// MARK: - Performance Extensions
extension PerformanceMonitor {
    func monitorImageProcessing(_ image: UIImage, operation: String) -> UIImage? {
        recordMemoryUsage(for: "\(operation)_start")
        recordCPUUsage(for: "\(operation)_start")
        
        let result = measureOperation(operation) {
            // Simulate image processing
            return image
        }
        
        recordMemoryUsage(for: "\(operation)_end")
        recordCPUUsage(for: "\(operation)_end")
        
        return result
    }
    
    func monitorAnalysisOperation(_ operation: String, block: () async throws -> Void) async rethrows {
        recordMemoryUsage(for: "\(operation)_start")
        recordCPUUsage(for: "\(operation)_start")
        
        try await measureAsyncOperation(operation, block: block)
        
        recordMemoryUsage(for: "\(operation)_end")
        recordCPUUsage(for: "\(operation)_end")
    }
}