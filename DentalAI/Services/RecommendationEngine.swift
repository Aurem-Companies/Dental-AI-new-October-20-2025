import Foundation

class RecommendationEngine: ObservableObject {
    
    // MARK: - Personalized Recommendations
    func generatePersonalizedRecommendations(
        for result: DentalAnalysisResult,
        userProfile: UserProfile? = nil
    ) -> [Recommendation] {
        var recommendations = result.recommendations
        
        // Add personalized recommendations based on user profile
        if let profile = userProfile {
            recommendations.append(contentsOf: getAgeBasedRecommendations(age: profile.age))
            recommendations.append(contentsOf: getHistoryBasedRecommendations(history: profile.dentalHistory))
            recommendations.append(contentsOf: getTrendBasedRecommendations(trend: profile.healthTrend))
        }
        
        // Add seasonal recommendations
        recommendations.append(contentsOf: getSeasonalRecommendations())
        
        // Add general health recommendations
        recommendations.append(contentsOf: getGeneralHealthRecommendations())
        
        // Remove duplicates and sort by priority
        let uniqueRecommendations = Array(Set(recommendations))
        return uniqueRecommendations.sorted { $0.priority.rawValue < $1.priority.rawValue }
    }
    
    // MARK: - Age-Based Recommendations
    private func getAgeBasedRecommendations(age: Int) -> [Recommendation] {
        var recommendations: [Recommendation] = []
        
        switch age {
        case 0...12:
            recommendations.append(
                Recommendation(
                    title: "Child Dental Care",
                    description: "Special care needed for developing teeth.",
                    priority: .important,
                    category: .homeCare,
                    actionItems: [
                        "Use child-friendly toothpaste",
                        "Supervise brushing until age 8",
                        "Limit sugary snacks and drinks",
                        "Schedule regular pediatric dental visits"
                    ]
                )
            )
            
        case 13...19:
            recommendations.append(
                Recommendation(
                    title: "Teen Dental Health",
                    description: "Important years for establishing good oral hygiene habits.",
                    priority: .important,
                    category: .lifestyle,
                    actionItems: [
                        "Establish consistent brushing routine",
                        "Be mindful of sports-related dental injuries",
                        "Limit energy drinks and sports drinks",
                        "Consider orthodontic treatment if needed"
                    ]
                )
            )
            
        case 20...39:
            recommendations.append(
                Recommendation(
                    title: "Adult Preventive Care",
                    description: "Focus on preventing dental problems before they start.",
                    priority: .general,
                    category: .homeCare,
                    actionItems: [
                        "Maintain regular dental checkups",
                        "Consider professional whitening",
                        "Be aware of stress-related dental issues",
                        "Maintain good nutrition for oral health"
                    ]
                )
            )
            
        case 40...59:
            recommendations.append(
                Recommendation(
                    title: "Midlife Dental Care",
                    description: "Pay attention to gum health and tooth wear.",
                    priority: .important,
                    category: .professional,
                    actionItems: [
                        "Monitor gum health closely",
                        "Consider night guards if grinding teeth",
                        "Be aware of medication side effects on oral health",
                        "Maintain regular professional cleanings"
                    ]
                )
            )
            
        case 60...:
            recommendations.append(
                Recommendation(
                    title: "Senior Dental Health",
                    description: "Special considerations for aging teeth and gums.",
                    priority: .important,
                    category: .professional,
                    actionItems: [
                        "Monitor for dry mouth symptoms",
                        "Be aware of medication interactions",
                        "Consider dental implants if needed",
                        "Maintain regular dental visits"
                    ]
                )
            )
            
        default:
            break
        }
        
        return recommendations
    }
    
    // MARK: - History-Based Recommendations
    private func getHistoryBasedRecommendations(history: [DentalAnalysisResult]) -> [Recommendation] {
        var recommendations: [Recommendation] = []
        
        // Analyze recent trends
        let recentResults = history.suffix(3)
        let recentConditions = recentResults.flatMap { $0.conditions }
        
        // Count condition occurrences
        let conditionCounts = Dictionary(grouping: recentConditions, by: { $0 })
            .mapValues { $0.count }
        
        // Generate recommendations based on recurring conditions
        for (condition, count) in conditionCounts {
            if count >= 2 {
                recommendations.append(
                    Recommendation(
                        title: "Address Recurring \(condition.rawValue)",
                        description: "This condition has appeared in multiple recent analyses.",
                        priority: .urgent,
                        category: .professional,
                        actionItems: [
                            "Schedule dental consultation",
                            "Discuss treatment options",
                            "Implement preventive measures"
                        ]
                    )
                )
            }
        }
        
        // Check for improving trends
        if history.count >= 2 {
            let latestScore = history.last?.overallHealthScore ?? 0
            let previousScore = history[history.count - 2].overallHealthScore
            
            if latestScore > previousScore {
                recommendations.append(
                    Recommendation(
                        title: "Continue Current Care",
                        description: "Your dental health is improving. Keep up the good work!",
                        priority: .general,
                        category: .homeCare,
                        actionItems: [
                            "Maintain current oral hygiene routine",
                            "Continue regular dental visits",
                            "Stay consistent with recommendations"
                        ]
                    )
                )
            }
        }
        
        return recommendations
    }
    
    // MARK: - Trend-Based Recommendations
    private func getTrendBasedRecommendations(trend: HealthTrend) -> [Recommendation] {
        switch trend {
        case .improving:
            return [
                Recommendation(
                    title: "Maintain Progress",
                    description: "Your dental health is improving. Continue your current routine.",
                    priority: .general,
                    category: .homeCare,
                    actionItems: [
                        "Keep up current oral hygiene habits",
                        "Continue regular dental checkups",
                        "Stay consistent with recommendations"
                    ]
                )
            ]
            
        case .declining:
            return [
                Recommendation(
                    title: "Address Declining Health",
                    description: "Your dental health needs attention. Consider professional consultation.",
                    priority: .urgent,
                    category: .professional,
                    actionItems: [
                        "Schedule dental appointment soon",
                        "Review and improve oral hygiene routine",
                        "Consider lifestyle changes",
                        "Monitor for any new symptoms"
                    ]
                )
            ]
            
        case .stable:
            return [
                Recommendation(
                    title: "Maintain Stability",
                    description: "Your dental health is stable. Focus on preventive care.",
                    priority: .general,
                    category: .homeCare,
                    actionItems: [
                        "Continue regular dental checkups",
                        "Maintain good oral hygiene",
                        "Stay proactive with preventive care"
                    ]
                )
            ]
        }
    }
    
    // MARK: - Seasonal Recommendations
    private func getSeasonalRecommendations() -> [Recommendation] {
        let currentMonth = Calendar.current.component(.month, from: Date())
        var recommendations: [Recommendation] = []
        
        switch currentMonth {
        case 12, 1, 2: // Winter
            recommendations.append(
                Recommendation(
                    title: "Winter Oral Care",
                    description: "Cold weather can affect oral health.",
                    priority: .general,
                    category: .lifestyle,
                    actionItems: [
                        "Stay hydrated to prevent dry mouth",
                        "Protect lips from chapping",
                        "Be mindful of hot beverages",
                        "Maintain regular dental routine"
                    ]
                )
            )
            
        case 3, 4, 5: // Spring
            recommendations.append(
                Recommendation(
                    title: "Spring Dental Checkup",
                    description: "Perfect time for a comprehensive dental examination.",
                    priority: .important,
                    category: .professional,
                    actionItems: [
                        "Schedule annual dental checkup",
                        "Consider professional cleaning",
                        "Review dental insurance benefits",
                        "Plan any needed treatments"
                    ]
                )
            )
            
        case 6, 7, 8: // Summer
            recommendations.append(
                Recommendation(
                    title: "Summer Oral Health",
                    description: "Summer activities can impact dental health.",
                    priority: .general,
                    category: .lifestyle,
                    actionItems: [
                        "Stay hydrated in hot weather",
                        "Be careful with sports and activities",
                        "Limit sugary summer treats",
                        "Protect teeth during sports"
                    ]
                )
            )
            
        case 9, 10, 11: // Fall
            recommendations.append(
                Recommendation(
                    title: "Fall Dental Preparation",
                    description: "Prepare for the holiday season ahead.",
                    priority: .general,
                    category: .homeCare,
                    actionItems: [
                        "Schedule pre-holiday dental checkup",
                        "Stock up on oral hygiene supplies",
                        "Plan for holiday dental care",
                        "Consider whitening before holidays"
                    ]
                )
            )
            
        default:
            break
        }
        
        return recommendations
    }
    
    // MARK: - General Health Recommendations
    private func getGeneralHealthRecommendations() -> [Recommendation] {
        return [
            Recommendation(
                title: "Overall Health Connection",
                description: "Oral health is connected to overall health.",
                priority: .general,
                category: .lifestyle,
                actionItems: [
                    "Maintain a balanced diet",
                    "Stay physically active",
                    "Manage stress levels",
                    "Get adequate sleep",
                    "Avoid tobacco products"
                ]
            ),
            Recommendation(
                title: "Emergency Preparedness",
                description: "Be prepared for dental emergencies.",
                priority: .general,
                category: .emergency,
                actionItems: [
                    "Keep emergency dental contact information",
                    "Know basic first aid for dental injuries",
                    "Have a dental first aid kit",
                    "Know when to seek immediate care"
                ]
            )
        ]
    }
    
    // MARK: - Product Recommendations
    func getProductRecommendations(for conditions: [DentalCondition]) -> [Recommendation] {
        var recommendations: [Recommendation] = []
        
        for condition in conditions {
            switch condition {
            case .cavity:
                recommendations.append(
                    Recommendation(
                        title: "Cavity Prevention Products",
                        description: "Multiple options available for cavity prevention based on your needs.",
                        priority: .important,
                        category: .products,
                        actionItems: [
                            "Consider xylitol-based products (natural alternative to fluoride)",
                            "Use fluoride toothpaste for maximum protection",
                            "Try hydroxyapatite toothpaste (remineralizing)",
                            "Consider fluoride mouthwash",
                            "Ask about professional fluoride treatments"
                        ]
                    )
                )
                
            case .gingivitis:
                recommendations.append(
                    Recommendation(
                        title: "Gum Care Products",
                        description: "Specialized products can help improve gum health.",
                        priority: .important,
                        category: .products,
                        actionItems: [
                            "Use soft-bristled toothbrush",
                            "Try xylitol mouthwash (reduces harmful bacteria)",
                            "Consider antimicrobial mouthwash",
                            "Use gum care toothpaste with xylitol",
                            "Try interdental brushes",
                            "Consider herbal mouthwashes (aloe vera, tea tree oil)"
                        ]
                    )
                )
                
            case .discoloration:
                recommendations.append(
                    Recommendation(
                        title: "Whitening Products",
                        description: "Multiple whitening options available, including natural alternatives.",
                        priority: .important,
                        category: .products,
                        actionItems: [
                            "Consider professional whitening",
                            "Try natural whitening toothpaste (baking soda, activated charcoal)",
                            "Use xylitol-based whitening products",
                            "Try whitening strips",
                            "Consider whitening mouthwash",
                            "Try oil pulling with coconut oil"
                        ]
                    )
                )
                
            case .plaque:
                recommendations.append(
                    Recommendation(
                        title: "Plaque Control Products",
                        description: "Specialized products can help control plaque buildup.",
                        priority: .important,
                        category: .products,
                        actionItems: [
                            "Use plaque control toothpaste with xylitol",
                            "Try electric toothbrush",
                            "Use plaque disclosing tablets",
                            "Consider xylitol-based mouthwash",
                            "Try natural plaque control (oil pulling)",
                            "Consider plaque control mouthwash"
                        ]
                    )
                )
                
            default:
                break
            }
        }
        
        return recommendations
    }
    
    // MARK: - Lifestyle Recommendations
    func getLifestyleRecommendations(for conditions: [DentalCondition]) -> [Recommendation] {
        var recommendations: [Recommendation] = []
        
        // Common lifestyle recommendations
        recommendations.append(
            Recommendation(
                title: "Diet and Nutrition",
                description: "What you eat affects your oral health.",
                priority: .general,
                category: .lifestyle,
                actionItems: [
                    "Limit sugary foods and drinks",
                    "Eat plenty of fruits and vegetables",
                    "Choose water over sugary beverages",
                    "Limit acidic foods",
                    "Eat calcium-rich foods"
                ]
            )
        )
        
        recommendations.append(
            Recommendation(
                title: "Oral Hygiene Habits",
                description: "Good habits are the foundation of oral health.",
                priority: .important,
                category: .lifestyle,
                actionItems: [
                    "Brush twice daily for 2 minutes",
                    "Floss daily",
                    "Use mouthwash",
                    "Replace toothbrush every 3 months",
                    "Don't share toothbrushes"
                ]
            )
        )
        
        // Condition-specific lifestyle recommendations
        for condition in conditions {
            switch condition {
            case .cavity:
                recommendations.append(
                    Recommendation(
                        title: "Cavity Prevention Lifestyle",
                        description: "Lifestyle changes can help prevent new cavities.",
                        priority: .urgent,
                        category: .lifestyle,
                        actionItems: [
                            "Reduce sugar intake",
                            "Avoid frequent snacking",
                            "Drink water after meals",
                            "Chew sugar-free gum"
                        ]
                    )
                )
                
            case .gingivitis:
                recommendations.append(
                    Recommendation(
                        title: "Gum Health Lifestyle",
                        description: "Lifestyle changes can improve gum health.",
                        priority: .urgent,
                        category: .lifestyle,
                        actionItems: [
                            "Quit smoking",
                            "Manage stress",
                            "Eat anti-inflammatory foods",
                            "Stay hydrated"
                        ]
                    )
                )
                
            default:
                break
            }
        }
        
        return recommendations
    }
    
    // MARK: - Alternative Product Recommendations
    func getAlternativeProductRecommendations(for conditions: [DentalCondition], userPreferences: UserPreferences? = nil) -> [Recommendation] {
        var recommendations: [Recommendation] = []
        
        // Check if user prefers natural products
        let prefersNatural = userPreferences?.prefersNaturalProducts ?? false
        
        for condition in conditions {
            switch condition {
            case .cavity:
                if prefersNatural {
                    recommendations.append(
                        Recommendation(
                            title: "Natural Cavity Prevention",
                            description: "Natural alternatives to fluoride for cavity prevention.",
                            priority: .important,
                            category: .products,
                            actionItems: [
                                "Use xylitol toothpaste (reduces cavity-causing bacteria)",
                                "Try hydroxyapatite toothpaste (remineralizes teeth)",
                                "Consider xylitol gum (stimulates saliva production)",
                                "Use xylitol mouthwash",
                                "Try oil pulling with coconut oil"
                            ]
                        )
                    )
                } else {
                    recommendations.append(
                        Recommendation(
                            title: "Comprehensive Cavity Prevention",
                            description: "Multiple approaches for maximum cavity protection.",
                            priority: .important,
                            category: .products,
                            actionItems: [
                                "Use fluoride toothpaste for proven protection",
                                "Add xylitol products for additional benefits",
                                "Consider hydroxyapatite for remineralization",
                                "Use xylitol gum between meals",
                                "Try xylitol mouthwash"
                            ]
                        )
                    )
                }
                
            case .gingivitis:
                recommendations.append(
                    Recommendation(
                        title: "Natural Gum Care",
                        description: "Natural alternatives for gum health.",
                        priority: .important,
                        category: .products,
                        actionItems: [
                            "Use xylitol mouthwash (reduces harmful bacteria)",
                            "Try herbal mouthwashes (aloe vera, tea tree oil)",
                            "Consider xylitol toothpaste",
                            "Use soft-bristled toothbrush",
                            "Try oil pulling with coconut oil"
                        ]
                    )
                )
                
            case .discoloration:
                recommendations.append(
                    Recommendation(
                        title: "Natural Whitening Options",
                        description: "Natural alternatives for teeth whitening.",
                        priority: .important,
                        category: .products,
                        actionItems: [
                            "Try baking soda toothpaste (gentle whitening)",
                            "Use activated charcoal toothpaste",
                            "Consider xylitol-based whitening products",
                            "Try oil pulling with coconut oil",
                            "Use xylitol gum (reduces staining)"
                        ]
                    )
                )
                
            case .plaque:
                recommendations.append(
                    Recommendation(
                        title: "Natural Plaque Control",
                        description: "Natural methods for plaque control.",
                        priority: .important,
                        category: .products,
                        actionItems: [
                            "Use xylitol toothpaste (reduces plaque formation)",
                            "Try oil pulling with coconut oil",
                            "Use xylitol mouthwash",
                            "Consider xylitol gum",
                            "Try herbal mouthwashes"
                        ]
                    )
                )
                
            default:
                break
            }
        }
        
        return recommendations
    }
    
    // MARK: - Product Comparison
    func getProductComparison() -> [ProductComparison] {
        return [
            ProductComparison(
                name: "Xylitol",
                benefits: [
                    "Reduces cavity-causing bacteria",
                    "Stimulates saliva production",
                    "Natural sweetener",
                    "Safe for children",
                    "No fluoride concerns"
                ],
                drawbacks: [
                    "Less proven than fluoride",
                    "May cause digestive issues in large amounts",
                    "More expensive than fluoride",
                    "Limited availability"
                ],
                bestFor: ["Cavity prevention", "Gum health", "Natural alternatives"],
                effectiveness: 0.8
            ),
            ProductComparison(
                name: "Fluoride",
                benefits: [
                    "Proven cavity prevention",
                    "Strengthens tooth enamel",
                    "Widely available",
                    "Cost-effective",
                    "Extensive research"
                ],
                drawbacks: [
                    "Potential toxicity concerns",
                    "Not suitable for young children",
                    "Environmental concerns",
                    "May cause fluorosis"
                ],
                bestFor: ["Maximum cavity protection", "Enamel strengthening"],
                effectiveness: 0.95
            ),
            ProductComparison(
                name: "Hydroxyapatite",
                benefits: [
                    "Natural tooth mineral",
                    "Remineralizes teeth",
                    "No toxicity concerns",
                    "Biocompatible",
                    "Gentle on teeth"
                ],
                drawbacks: [
                    "Newer technology",
                    "Limited research",
                    "More expensive",
                    "Less proven than fluoride"
                ],
                bestFor: ["Remineralization", "Sensitive teeth", "Natural alternatives"],
                effectiveness: 0.7
            )
        ]
    }
}
