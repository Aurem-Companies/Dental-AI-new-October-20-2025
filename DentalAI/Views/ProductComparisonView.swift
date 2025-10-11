import SwiftUI

struct ProductComparisonView: View {
    @StateObject private var recommendationEngine = RecommendationEngine()
    @State private var selectedProduct: ProductComparison?
    @State private var showingDetails = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerView
                    
                    // Product Comparison Cards
                    productComparisonCards
                    
                    // Detailed Comparison
                    if showingDetails {
                        detailedComparisonView
                    }
                }
                .padding()
            }
            .navigationTitle("Product Comparison")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 12) {
            Text("Choose the Right Products")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Compare different dental care products to find what works best for you")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Product Comparison Cards
    private var productComparisonCards: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(recommendationEngine.getProductComparison()) { product in
                ProductCard(
                    product: product,
                    isSelected: selectedProduct?.id == product.id,
                    onTap: {
                        selectedProduct = product
                        showingDetails = true
                    }
                )
            }
        }
    }
    
    // MARK: - Detailed Comparison View
    private var detailedComparisonView: some View {
        VStack(spacing: 16) {
            if let product = selectedProduct {
                // Product Header
                VStack(spacing: 8) {
                    Text(product.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    HStack {
                        Text("Effectiveness:")
                            .font(.headline)
                        Text("\(product.effectivenessPercentage)%")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(effectivenessColor(product.effectiveness))
                        Text("(\(product.effectivenessRating))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Benefits
                VStack(alignment: .leading, spacing: 8) {
                    Text("Benefits")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    ForEach(product.benefits, id: \.self) { benefit in
                        HStack(alignment: .top) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text(benefit)
                                .font(.body)
                        }
                    }
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
                
                // Drawbacks
                VStack(alignment: .leading, spacing: 8) {
                    Text("Considerations")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    ForEach(product.drawbacks, id: \.self) { drawback in
                        HStack(alignment: .top) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                            Text(drawback)
                                .font(.body)
                        }
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                
                // Best For
                VStack(alignment: .leading, spacing: 8) {
                    Text("Best For")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(product.bestFor, id: \.self) { use in
                            Text(use)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button("Get Recommendations") {
                        // Navigate to recommendations
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .fontWeight(.semibold)
                    
                    Button("Compare with Other Products") {
                        showingDetails = false
                        selectedProduct = nil
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func effectivenessColor(_ effectiveness: Double) -> Color {
        switch effectiveness {
        case 0.9...1.0:
            return .green
        case 0.8..<0.9:
            return .blue
        case 0.7..<0.8:
            return .yellow
        case 0.6..<0.7:
            return .orange
        default:
            return .red
        }
    }
}

// MARK: - Product Card
struct ProductCard: View {
    let product: ProductComparison
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Product Name
                Text(product.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                // Effectiveness
                HStack {
                    Text("Effectiveness:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(product.effectivenessPercentage)%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(effectivenessColor(product.effectiveness))
                }
                
                // Key Benefits
                VStack(alignment: .leading, spacing: 4) {
                    Text("Key Benefits:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    ForEach(Array(product.benefits.prefix(2)), id: \.self) { benefit in
                        HStack(alignment: .top) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption2)
                            Text(benefit)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .lineLimit(2)
                        }
                    }
                }
                
                Spacer()
                
                // Selection Indicator
                HStack {
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                    } else {
                        Image(systemName: "circle")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .frame(height: 200)
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func effectivenessColor(_ effectiveness: Double) -> Color {
        switch effectiveness {
        case 0.9...1.0:
            return .green
        case 0.8..<0.9:
            return .blue
        case 0.7..<0.8:
            return .yellow
        case 0.6..<0.7:
            return .orange
        default:
            return .red
        }
    }
}

#Preview {
    ProductComparisonView()
}
