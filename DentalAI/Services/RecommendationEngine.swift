import Foundation
import SwiftUI

// MARK: - Recommendation Engine
class RecommendationEngine {
    
    // MARK: - Properties
    private let dataManager = DataManager.shared
    
    // MARK: - Generate Personalized Recommendations
    func generatePersonalizedRecommendations(for result: DentalAnalysisResult, userProfile: UserProfile) -> [Recommendation] {
        var recommendations: [Recommendation] = []
        
        // Generate recommendations based on detected conditions
        for (condition, confidence) in result.detectedConditions {
            if confidence > 0.5 {
                let conditionRecommendations = generateRecommendationsForCondition(condition, confidence: confidence, userProfile: userProfile)
                recommendations.append(contentsOf: conditionRecommendations)
            }
        }
        
        // Add general health recommendations
        let generalRecommendations = generateGeneralHealthRecommendations(for: result, userProfile: userProfile)
        recommendations.append(contentsOf: generalRecommendations)
        
        // Add age-based recommendations
        let ageRecommendations = generateAgeBasedRecommendations(for: result, userProfile: userProfile)
        recommendations.append(contentsOf: ageRecommendations)
        
        // Add history-based recommendations
        let historyRecommendations = generateHistoryBasedRecommendations(for: result, userProfile: userProfile)
        recommendations.append(contentsOf: historyRecommendations)
        
        // Add seasonal recommendations
        let seasonalRecommendations = generateSeasonalRecommendations(for: result, userProfile: userProfile)
        recommendations.append(contentsOf: seasonalRecommendations)
        
        // Remove duplicates and sort by priority
        return removeDuplicateRecommendations(recommendations).sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
    
    // MARK: - Condition-Specific Recommendations
    private func generateRecommendationsForCondition(_ condition: DentalCondition, confidence: Float, userProfile: UserProfile) -> [Recommendation] {
        var recommendations: [Recommendation] = []
        
        switch condition {
        case .cavity:
            recommendations.append(Recommendation(
                category: .professionalCare,
                priority: .urgent,
                actionItems: [
                    "Schedule dental appointment within 1 week",
                    "Avoid sugary foods and drinks",
                    "Use fluoride toothpaste",
                    "Consider dental sealants"
                ],
                personalizedText: "Cavities detected with \(Int(confidence * 100))% confidence. Immediate professional care is recommended to prevent further decay.",
                estimatedCost: 150.0,
                timeframe: "Within 1 week",
                relatedConditions: [.cavity]
            ))
            
            recommendations.append(Recommendation(
                    category: .homeCare,
                priority: .high,
                    actionItems: [
                    "Brush twice daily with fluoride toothpaste",
                    "Floss daily",
                    "Use mouthwash with fluoride",
                    "Limit sugary snacks"
                ],
                personalizedText: "Enhanced home care routine to prevent cavity progression.",
                timeframe: "Daily",
                relatedConditions: [.cavity]
            ))
            
        case .gingivitis:
            recommendations.append(Recommendation(
                category: .professionalCare,
                priority: .high,
                    actionItems: [
                    "Schedule dental cleaning",
                    "Consider deep cleaning if severe",
                    "Ask about antimicrobial mouthwash"
                ],
                personalizedText: "Gingivitis detected. Professional cleaning can reverse early gum disease.",
                estimatedCost: 100.0,
                timeframe: "Within 2 weeks",
                relatedConditions: [.gingivitis]
            ))
            
            recommendations.append(Recommendation(
                    category: .homeCare,
                priority: .high,
                actionItems: [
                    "Improve brushing technique",
                    "Floss daily",
                    "Use soft-bristled toothbrush",
                    "Consider electric toothbrush"
                ],
                personalizedText: "Proper oral hygiene can reverse gingivitis.",
                timeframe: "Daily",
                relatedConditions: [.gingivitis]
            ))
            
        case .discoloration:
            recommendations.append(Recommendation(
                category: .professionalCare,
                priority: .medium,
                    actionItems: [
                        "Consider professional whitening",
                    "Ask about causes of discoloration",
                    "Evaluate for underlying issues"
                ],
                personalizedText: "Tooth discoloration detected. Professional whitening can restore brightness.",
                estimatedCost: 300.0,
                timeframe: "Within 1 month",
                relatedConditions: [.discoloration]
            ))
            
            recommendations.append(Recommendation(
                category: .lifestyleChanges,
                priority: .medium,
                actionItems: [
                    "Limit coffee and tea consumption",
                    "Avoid tobacco products",
                    "Reduce red wine intake",
                    "Use straw for colored beverages"
                ],
                personalizedText: "Lifestyle changes can prevent further discoloration.",
                timeframe: "Ongoing",
                relatedConditions: [.discoloration]
            ))
            
        case .plaque:
            recommendations.append(Recommendation(
                category: .homeCare,
                priority: .medium,
                actionItems: [
                    "Brush more thoroughly",
                    "Use plaque-disclosing tablets",
                    "Consider electric toothbrush",
                    "Increase brushing frequency"
                ],
                personalizedText: "Plaque buildup detected. Improved brushing technique can remove it.",
                timeframe: "Daily",
                relatedConditions: [.plaque]
            ))
            
        case .tartar:
            recommendations.append(Recommendation(
                category: .professionalCare,
                priority: .high,
                actionItems: [
                    "Schedule dental cleaning",
                    "Ask about tartar removal",
                    "Consider more frequent cleanings"
                ],
                personalizedText: "Tartar detected. Professional cleaning is required as it cannot be removed at home.",
                estimatedCost: 120.0,
                timeframe: "Within 2 weeks",
                relatedConditions: [.tartar]
            ))
            
        case .deadTooth:
            recommendations.append(Recommendation(
                category: .emergencyCare,
                priority: .urgent,
                actionItems: [
                    "Schedule immediate dental appointment",
                    "Consider root canal treatment",
                    "Evaluate tooth extraction options"
                ],
                personalizedText: "Dead tooth detected. Immediate professional care is required to prevent infection.",
                estimatedCost: 800.0,
                timeframe: "Within 3 days",
                relatedConditions: [.deadTooth]
            ))
            
        case .rootCanal:
            recommendations.append(Recommendation(
                category: .professionalCare,
                priority: .urgent,
                actionItems: [
                    "Complete root canal treatment",
                    "Follow post-treatment care instructions",
                    "Consider crown placement"
                ],
                personalizedText: "Root canal treatment needed. This is a priority procedure.",
                estimatedCost: 1000.0,
                timeframe: "Within 1 week",
                relatedConditions: [.rootCanal]
            ))
            
        case .chippedTeeth:
            recommendations.append(Recommendation(
                category: .professionalCare,
                priority: .medium,
                    actionItems: [
                    "Schedule dental appointment",
                    "Consider bonding or veneers",
                    "Evaluate for underlying damage"
                ],
                personalizedText: "Chipped teeth detected. Professional repair can restore appearance and function.",
                estimatedCost: 200.0,
                timeframe: "Within 2 weeks",
                relatedConditions: [.chippedTeeth]
            ))
            
        case .misalignedTeeth:
            recommendations.append(Recommendation(
                category: .professionalCare,
                priority: .low,
                    actionItems: [
                    "Consult with orthodontist",
                    "Consider braces or aligners",
                    "Evaluate bite issues"
                ],
                personalizedText: "Misaligned teeth detected. Orthodontic treatment can improve alignment.",
                estimatedCost: 3000.0,
                timeframe: "Within 3 months",
                relatedConditions: [.misalignedTeeth]
            ))
            
        case .healthy:
            recommendations.append(Recommendation(
                category: .preventiveCare,
                priority: .low,
                actionItems: [
                    "Continue current oral hygiene routine",
                    "Schedule regular dental checkups",
                    "Maintain healthy diet",
                    "Stay hydrated"
                ],
                personalizedText: "Great job! Your teeth look healthy. Keep up the good work!",
                timeframe: "Ongoing",
                relatedConditions: [.healthy]
            ))
        }
        
        return recommendations
    }
    
    // MARK: - General Health Recommendations
    private func generateGeneralHealthRecommendations(for result: DentalAnalysisResult, userProfile: UserProfile) -> [Recommendation] {
        var recommendations: [Recommendation] = []
        
        // Overall health score recommendations
        if result.healthScore < 30 {
            recommendations.append(Recommendation(
                category: .emergencyCare,
                        priority: .urgent,
                actionItems: [
                    "Schedule immediate dental appointment",
                    "Consider comprehensive dental evaluation",
                    "Address all detected issues"
                ],
                personalizedText: "Your dental health score is very low. Immediate professional care is recommended.",
                estimatedCost: 500.0,
                timeframe: "Within 3 days",
                relatedConditions: []
            ))
        } else if result.healthScore < 60 {
            recommendations.append(Recommendation(
                category: .professionalCare,
                priority: .high,
                actionItems: [
                    "Schedule dental appointment",
                    "Address detected issues",
                    "Improve oral hygiene routine"
                ],
                personalizedText: "Your dental health needs attention. Professional care can help improve your score.",
                estimatedCost: 300.0,
                timeframe: "Within 2 weeks",
                relatedConditions: []
            ))
        } else if result.healthScore < 80 {
            recommendations.append(Recommendation(
                category: .preventiveCare,
                priority: .medium,
                        actionItems: [
                    "Schedule regular dental checkup",
                    "Maintain good oral hygiene",
                    "Address minor issues"
                ],
                personalizedText: "Your dental health is good but can be improved with proper care.",
                estimatedCost: 150.0,
                timeframe: "Within 1 month",
                relatedConditions: []
            ))
        }
        
        return recommendations
    }
    
    // MARK: - Age-Based Recommendations
    private func generateAgeBasedRecommendations(for result: DentalAnalysisResult, userProfile: UserProfile) -> [Recommendation] {
        var recommendations: [Recommendation] = []
        
        guard let age = userProfile.age else { return recommendations }
        
        if age < 18 {
            recommendations.append(Recommendation(
                category: .preventiveCare,
                priority: .medium,
                actionItems: [
                    "Ensure regular dental checkups",
                    "Consider fluoride treatments",
                    "Monitor orthodontic needs",
                    "Establish good oral hygiene habits"
                ],
                personalizedText: "As a young person, establishing good oral hygiene habits now will benefit you for life.",
                timeframe: "Ongoing",
                relatedConditions: []
            ))
        } else if age >= 18 && age < 30 {
            recommendations.append(Recommendation(
                category: .preventiveCare,
                priority: .low,
                actionItems: [
                    "Maintain regular dental checkups",
                    "Consider cosmetic treatments",
                    "Protect against grinding"
                ],
                personalizedText: "Your 20s are a great time to establish healthy dental habits and consider cosmetic improvements.",
                timeframe: "Ongoing",
                relatedConditions: []
            ))
        } else if age >= 30 && age < 50 {
            recommendations.append(Recommendation(
                category: .preventiveCare,
                priority: .medium,
                actionItems: [
                    "Increase dental checkup frequency",
                    "Monitor gum health closely",
                    "Consider night guards",
                    "Address stress-related issues"
                ],
                personalizedText: "In your 30s and 40s, preventive care becomes even more important.",
                timeframe: "Ongoing",
                relatedConditions: []
            ))
        } else if age >= 50 {
            recommendations.append(Recommendation(
                category: .professionalCare,
                priority: .medium,
                        actionItems: [
                    "Schedule comprehensive dental evaluation",
                    "Monitor for oral cancer",
                    "Consider dental implants",
                    "Address dry mouth issues"
                ],
                personalizedText: "As you age, comprehensive dental care becomes increasingly important.",
                estimatedCost: 400.0,
                timeframe: "Within 1 month",
                relatedConditions: []
            ))
        }
        
        return recommendations
    }
    
    // MARK: - History-Based Recommendations
    private func generateHistoryBasedRecommendations(for result: DentalAnalysisResult, userProfile: UserProfile) -> [Recommendation] {
        var recommendations: [Recommendation] = []
        
        let history = userProfile.analysisHistory
        guard !history.isEmpty else { return recommendations }
        
        // Analyze trends
        let recentResults = history.prefix(5)
        let recentScores = recentResults.map { $0.healthScore }
        let avgRecentScore = recentScores.reduce(0, +) / recentScores.count
        
        if result.healthScore > avgRecentScore {
            recommendations.append(Recommendation(
                category: .preventiveCare,
                priority: .low,
                actionItems: [
                    "Continue current oral hygiene routine",
                    "Maintain regular dental checkups",
                    "Keep up the good work"
                ],
                personalizedText: "Great improvement! Your dental health is getting better.",
                timeframe: "Ongoing",
                relatedConditions: []
            ))
        } else if result.healthScore < avgRecentScore {
            recommendations.append(Recommendation(
                    category: .homeCare,
                priority: .medium,
                    actionItems: [
                        "Review and improve oral hygiene routine",
                    "Consider changing toothpaste or mouthwash",
                    "Increase brushing frequency",
                    "Schedule dental checkup"
                ],
                personalizedText: "Your dental health has declined recently. Let's work on improving it.",
                timeframe: "Daily",
                relatedConditions: []
            ))
        }
        
        // Check for recurring issues
        let recurringConditions = getRecurringConditions(from: history)
        for condition in recurringConditions {
            recommendations.append(Recommendation(
                category: .professionalCare,
                priority: .high,
                    actionItems: [
                    "Address recurring \(condition.displayName.lowercased())",
                    "Consider specialized treatment",
                    "Evaluate underlying causes"
                ],
                personalizedText: "You've had recurring issues with \(condition.displayName.lowercased()). Professional evaluation is recommended.",
                estimatedCost: 200.0,
                timeframe: "Within 2 weeks",
                relatedConditions: [condition]
            ))
        }
        
        return recommendations
    }
    
    // MARK: - Seasonal Recommendations
    private func generateSeasonalRecommendations(for result: DentalAnalysisResult, userProfile: UserProfile) -> [Recommendation] {
        var recommendations: [Recommendation] = []
        
        let calendar = Calendar.current
        let month = calendar.component(.month, from: Date())
        
        switch month {
        case 12, 1, 2: // Winter
            recommendations.append(Recommendation(
                category: .lifestyleChanges,
                priority: .low,
                    actionItems: [
                    "Stay hydrated during winter months",
                    "Limit hot beverages that can stain teeth",
                    "Consider vitamin D supplements",
                    "Protect against dry mouth"
                ],
                personalizedText: "Winter can be tough on oral health. Stay hydrated and protect against dry mouth.",
                timeframe: "Seasonal",
                relatedConditions: []
            ))
            
        case 3, 4, 5: // Spring
            recommendations.append(Recommendation(
                category: .preventiveCare,
                priority: .low,
                    actionItems: [
                    "Schedule spring dental checkup",
                        "Consider professional cleaning",
                    "Evaluate any winter-related issues"
                ],
                personalizedText: "Spring is a great time for a fresh start with your dental health.",
                estimatedCost: 150.0,
                timeframe: "Within 1 month",
                relatedConditions: []
            ))
            
        case 6, 7, 8: // Summer
            recommendations.append(Recommendation(
                category: .lifestyleChanges,
                priority: .low,
                    actionItems: [
                    "Limit sugary summer drinks",
                    "Stay hydrated with water",
                    "Protect teeth during sports",
                    "Consider whitening treatments"
                ],
                personalizedText: "Summer activities can affect your teeth. Stay hydrated and protect your smile.",
                timeframe: "Seasonal",
                relatedConditions: []
            ))
            
        case 9, 10, 11: // Fall
            recommendations.append(Recommendation(
                category: .preventiveCare,
                priority: .low,
                    actionItems: [
                    "Schedule fall dental checkup",
                    "Prepare for holiday season",
                    "Address any summer-related issues"
                ],
                personalizedText: "Fall is perfect for preparing your smile for the holiday season.",
                estimatedCost: 150.0,
                timeframe: "Within 1 month",
                relatedConditions: []
            ))
            
        default:
            break
        }
        
        return recommendations
    }
    
    // MARK: - Product Recommendations
    func generateProductRecommendations(for result: DentalAnalysisResult, userProfile: UserProfile) -> [Recommendation] {
        var recommendations: [Recommendation] = []
        
        // Analyze detected conditions for product recommendations
        for (condition, confidence) in result.detectedConditions {
            if confidence > 0.5 {
            switch condition {
            case .cavity:
                    recommendations.append(Recommendation(
                        category: .productRecommendations,
                        priority: .high,
                        actionItems: [
                            "Use fluoride toothpaste",
                            "Consider fluoride mouthwash",
                            "Try dental sealants",
                            "Use interdental brushes"
                        ],
                        personalizedText: "Products to help prevent and treat cavities.",
                        timeframe: "Immediate",
                        relatedConditions: [.cavity]
                    ))
                
            case .gingivitis:
                    recommendations.append(Recommendation(
                        category: .productRecommendations,
                        priority: .high,
                        actionItems: [
                            "Use soft-bristled toothbrush",
                            "Consider electric toothbrush",
                            "Try antimicrobial mouthwash",
                            "Use dental floss"
                        ],
                        personalizedText: "Products to help treat and prevent gingivitis.",
                        timeframe: "Immediate",
                        relatedConditions: [.gingivitis]
                    ))
                
            case .discoloration:
                    recommendations.append(Recommendation(
                        category: .productRecommendations,
                        priority: .medium,
                        actionItems: [
                            "Try whitening toothpaste",
                            "Consider whitening strips",
                            "Use whitening mouthwash",
                            "Try whitening pens"
                        ],
                        personalizedText: "Products to help whiten and brighten your smile.",
                        timeframe: "Within 1 week",
                        relatedConditions: [.discoloration]
                    ))
                
            case .plaque:
                    recommendations.append(Recommendation(
                        category: .productRecommendations,
                        priority: .medium,
                        actionItems: [
                            "Use plaque-disclosing tablets",
                            "Try electric toothbrush",
                            "Use interdental brushes",
                            "Consider water flosser"
                        ],
                        personalizedText: "Products to help remove and prevent plaque buildup.",
                        timeframe: "Immediate",
                        relatedConditions: [.plaque]
                    ))
                
            default:
                break
                }
            }
        }
        
        return recommendations
    }
    
    // MARK: - Lifestyle Recommendations
    func generateLifestyleRecommendations(for result: DentalAnalysisResult, userProfile: UserProfile) -> [Recommendation] {
        var recommendations: [Recommendation] = []
        
        // General lifestyle recommendations
        recommendations.append(Recommendation(
            category: .lifestyleChanges,
            priority: .medium,
                actionItems: [
                "Maintain a balanced diet",
                    "Limit sugary foods and drinks",
                "Stay hydrated with water",
                "Avoid tobacco products",
                "Limit alcohol consumption"
            ],
            personalizedText: "Healthy lifestyle choices support good oral health.",
            timeframe: "Ongoing",
            relatedConditions: []
        ))
        
        // Stress-related recommendations
        if result.detectedConditions.contains(where: { $0.key == .chippedTeeth && $0.value > 0.5 }) {
            recommendations.append(Recommendation(
                category: .lifestyleChanges,
                priority: .medium,
                actionItems: [
                    "Manage stress levels",
                    "Consider stress reduction techniques",
                    "Use night guard if grinding",
                    "Practice relaxation exercises"
                ],
                personalizedText: "Stress can contribute to tooth damage. Managing stress is important for oral health.",
                timeframe: "Ongoing",
                relatedConditions: [.chippedTeeth]
            ))
        }
        
        return recommendations
    }
    
    // MARK: - Helper Methods
    private func getRecurringConditions(from history: [DentalAnalysisResult]) -> [DentalCondition] {
        var conditionCounts: [DentalCondition: Int] = [:]
        
        for result in history {
            for (condition, confidence) in result.detectedConditions {
                if confidence > 0.5 {
                    conditionCounts[condition, default: 0] += 1
                }
            }
        }
        
        return conditionCounts.compactMap { condition, count in
            count >= 3 ? condition : nil
        }
    }
    
    private func removeDuplicateRecommendations(_ recommendations: [Recommendation]) -> [Recommendation] {
        var uniqueRecommendations: [Recommendation] = []
        var seenCategories: Set<RecommendationCategory> = []
        
        for recommendation in recommendations {
            if !seenCategories.contains(recommendation.category) {
                uniqueRecommendations.append(recommendation)
                seenCategories.insert(recommendation.category)
            }
        }
        
        return uniqueRecommendations
    }
}