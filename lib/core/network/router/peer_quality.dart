/// Peer quality scoring for routing decisions
class PeerQuality {
  final String peerId;
  double reliability = 1.0; // 0.0 - 1.0
  int successfulForwards = 0;
  int failedForwards = 0;
  int totalPacketsReceived = 0;
  DateTime lastSeen = DateTime.now();
  
  PeerQuality(this.peerId);
  
  /// Update score based on forward success
  void updateForwardScore(bool success) {
    if (success) {
      successfulForwards++;
      reliability = (reliability * 0.9) + 0.1; // Slowly increase
      reliability = reliability.clamp(0.0, 1.0);
    } else {
      failedForwards++;
      reliability = (reliability * 0.9) - 0.15; // Faster decrease
      reliability = reliability.clamp(0.0, 1.0);
    }
  }
  
  /// Update last seen timestamp
  void markSeen() {
    lastSeen = DateTime.now();
    totalPacketsReceived++;
  }
  
  /// Calculate overall quality score (0.0 - 1.0)
  double get qualityScore {
    // Factors: reliability, recency, activity
    final recencyScore = _calculateRecencyScore();
    final activityScore = _calculateActivityScore();
    
    return (reliability * 0.5) + (recencyScore * 0.3) + (activityScore * 0.2);
  }
  
  /// Calculate recency score based on last seen
  double _calculateRecencyScore() {
    final elapsed = DateTime.now().difference(lastSeen);
    if (elapsed.inMinutes < 5) return 1.0;
    if (elapsed.inMinutes < 15) return 0.7;
    if (elapsed.inMinutes < 30) return 0.4;
    return 0.1;
  }
  
  /// Calculate activity score based on packet count
  double _calculateActivityScore() {
    if (totalPacketsReceived > 100) return 1.0;
    if (totalPacketsReceived > 50) return 0.8;
    if (totalPacketsReceived > 20) return 0.6;
    if (totalPacketsReceived > 5) return 0.4;
    return 0.2;
  }
  
  /// Get success rate
  double get successRate {
    final total = successfulForwards + failedForwards;
    if (total == 0) return 1.0;
    return successfulForwards / total;
  }
  
  @override
  String toString() {
    return 'PeerQuality($peerId: score=${qualityScore.toStringAsFixed(2)}, '
           'reliability=${reliability.toStringAsFixed(2)}, '
           'success=$successfulForwards, failed=$failedForwards)';
  }
}

/// Adaptive TTL calculator based on network density
class AdaptiveTTLCalculator {
  static const int minTTL = 3;
  static const int maxTTL = 15;
  static const int defaultTTL = 10;
  
  /// Calculate TTL based on current peer count
  static int calculateTTL(int peerCount) {
    // Dense network (>10 peers): Lower TTL to reduce congestion
    if (peerCount > 10) return 5;
    
    // Medium network (5-10 peers): Moderate TTL
    if (peerCount > 5) return 8;
    
    // Sparse network (<5 peers): Higher TTL for better reach
    if (peerCount > 2) return 12;
    
    // Very sparse (1-2 peers): Maximum TTL
    return maxTTL;
  }
  
  /// Calculate TTL with quality adjustment
  static int calculateTTLWithQuality(int peerCount, double avgPeerQuality) {
    int baseTTL = calculateTTL(peerCount);
    
    // If peers are high quality, can use lower TTL
    if (avgPeerQuality > 0.8) {
      baseTTL = (baseTTL * 0.8).round();
    }
    // If peers are low quality, increase TTL for redundancy
    else if (avgPeerQuality < 0.4) {
      baseTTL = (baseTTL * 1.3).round();
    }
    
    return baseTTL.clamp(minTTL, maxTTL);
  }
}
