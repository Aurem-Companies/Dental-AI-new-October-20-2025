# Release Checklist - DentalAI iOS App

## Pre-Release Verification

### ✅ Model Verification
- [ ] Verify model probe: "[DEBUG][Bundle] dental_model.onnx: true"
- [ ] Confirm ONNX model loads without errors
- [ ] Test fallback to CV service if ONNX unavailable
- [ ] Verify FeatureFlags auto-disable when models missing

### ✅ Build & Archive
- [ ] Product → Clean Build Folder
- [ ] Product → Archive
- [ ] Distribute → TestFlight
- [ ] Verify archive size < 500MB

### ✅ App Store Configuration
- [ ] Turn on "Automatically manage signing"
- [ ] Set unique bundle ID (com.yourcompany.dentalai)
- [ ] Verify privacy strings are human-readable:
  - Camera: "DentalAI needs camera access to take photos of your teeth for analysis"
  - Photos: "DentalAI needs photo library access to analyze existing photos"
- [ ] Confirm App Store Connect metadata

### ✅ Screenshots Required
- [ ] Home screen (main interface)
- [ ] Camera capture screen
- [ ] Analysis overlay with results
- [ ] Share sheet functionality
- [ ] Settings/profile screen

### ✅ Pricing & Monetization
- [ ] Pricing: $4.99 one-time purchase
- [ ] No subscription model (yet)
- [ ] In-app purchases: None initially
- [ ] Free trial: Consider 7-day trial

### ✅ Legal & Compliance
- [ ] Disclaimer present: "Not a medical device"
- [ ] Educational use only
- [ ] No diagnosis/treatment claims
- [ ] Privacy policy updated
- [ ] Terms of service current

### ✅ Testing
- [ ] Test on iPhone 15 (iOS 17+)
- [ ] Test camera permissions flow
- [ ] Test photo analysis workflow
- [ ] Test share functionality
- [ ] Test data deletion/clear history
- [ ] Test offline functionality

### ✅ Performance
- [ ] App launch time < 3 seconds
- [ ] Analysis completion < 10 seconds
- [ ] Memory usage reasonable
- [ ] No crashes during normal use
- [ ] Battery usage acceptable

## Post-Release Monitoring

### 📊 Analytics Setup
- [ ] App Store Connect analytics enabled
- [ ] Crash reporting configured
- [ ] User feedback collection ready
- [ ] Performance monitoring active

### 🔄 Update Strategy
- [ ] Version numbering scheme defined
- [ ] Hotfix process documented
- [ ] Feature update timeline planned
- [ ] User communication plan ready

## Success Metrics

### 📈 Key Performance Indicators
- [ ] App Store rating target: 4.5+ stars
- [ ] Crash rate target: < 1%
- [ ] Analysis success rate: > 95%
- [ ] User retention: 70%+ after 7 days
- [ ] Conversion rate: 5%+ trial to paid

### 🎯 Launch Goals
- [ ] 1000+ downloads in first week
- [ ] 50+ reviews in first month
- [ ] Featured in App Store (if possible)
- [ ] Press coverage secured
- [ ] Influencer partnerships active

---

**Release Date Target**: [To be determined]
**Version**: 1.0.0
**Build Number**: [To be set]
