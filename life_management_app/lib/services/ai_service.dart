import 'package:supabase_flutter/supabase_flutter.dart';

class AIService {
  final _supabase = Supabase.instance.client;
  
  Future<String> sendMessage(String message, {String? sessionId}) async {
    try {
      final response = await _supabase.functions.invoke(
        'gemini-assistant',
        body: {
          'messages': [
            {'role': 'user', 'content': message}
          ],
          'sessionId': sessionId,
        ),
      );
      
      if (response.data != null && response.data['success'] == true) {
        return response.data['message'] as String;
      } else {
        throw Exception(response.data['error'] ?? 'AI service error');
      }
    } catch (e) {
      throw Exception('Failed to get AI response: $e');
    }
  }
  
  Future<Map<String, dynamic>> getFinancialInsights() async {
    try {
      final response = await _supabase.functions.invoke(
        'gemini-assistant',
        body: {
          'messages': [
            {
              'role': 'user',
              'content': 'Analyze my financial data and provide insights'
            }
          ],
          'context': 'financial_analysis',
        ),
      );
      
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to get financial insights: $e');
    }
  }
  
  Future<Map<String, dynamic>> getHabitAnalysis() async {
    try {
      final response = await _supabase.functions.invoke(
        'gemini-assistant',
        body: {
          'messages': [
            {
              'role': 'user',
              'content': 'Analyze my habit tracking data and provide recommendations'
            }
          ],
          'context': 'habit_analysis',
        ),
      );
      
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to get habit analysis: $e');
    }
  }
  
  Future<Map<String, dynamic>> getCryptoPrices(List<String> symbols) async {
    try {
      final response = await _supabase.functions.invoke(
        'crypto-prices',
        body: {'symbols': symbols),
      );
      
      if (response.data != null && response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      } else {
        throw Exception(response.data['error'] ?? 'Crypto price error');
      }
    } catch (e) {
      throw Exception('Failed to get crypto prices: $e');
    }
  }
}
