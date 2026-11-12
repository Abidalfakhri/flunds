import 'package:flutter/material.dart';

enum InsightLevel { info, warning, critical }

                                                                          
                                                                           
                                                
enum InsightAction { none, openDebts, openGoals, openAnalysis, openCategories }

                                                                            
                                                                        
                                                                           
                                                  
class Insight {
  final String title;
  final String message;
  final IconData icon;
  final InsightLevel level;
  final InsightAction action;

  const Insight({
    required this.title,
    required this.message,
    required this.icon,
    required this.level,
    this.action = InsightAction.none,
  });
}
