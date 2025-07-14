import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import 'dart:async';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class PharmacyLocator extends StatefulWidget {
  const PharmacyLocator({super.key});

  @override
  State<PharmacyLocator> createState() => _PharmacyLocatorState();
}

class _PharmacyLocatorState extends State<PharmacyLocator> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _searchResults = [];
  String? _errorMessage;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _pinController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _areaController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _performSearch() async {
    // Check if any field has input
    final pin = _pinController.text.trim();
    final district = _districtController.text.trim();
    final state = _stateController.text.trim();
    final area = _areaController.text.trim();

    if (pin.isEmpty && district.isEmpty && state.isEmpty && area.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter at least one search criteria';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Map<String, dynamic> response;

      // Prioritize search order: PIN > District > State > Area
      if (pin.isNotEmpty) {
        response = await ApiService.searchPharmaciesByPincode(pin);
      } else if (district.isNotEmpty) {
        response = await ApiService.searchByDistrict(district);
      } else if (state.isNotEmpty) {
        response = await ApiService.searchByState(state);
      } else {
        response = await ApiService.searchPharmaciesByArea(area);
      }

      setState(() {
        _searchResults = List<Map<String, dynamic>>.from(response['pharmacies']);
        if (_searchResults.isEmpty) {
          _errorMessage = 'No pharmacies found';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _searchResults = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildSuggestionField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required String type,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF4A4A4A),
            fontWeight: FontWeight.w500,
              ),
            ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
              ),
            ),
          child: TypeAheadField(
            textFieldConfiguration: TextFieldConfiguration(
              controller: controller,
              keyboardType: keyboardType ?? TextInputType.text,
              maxLength: maxLength,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF4A4A4A),
            ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 16,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: InputBorder.none,
                counterText: '',
              ),
            ),
            suggestionsCallback: (pattern) async {
              if (pattern.length < 1) return [];
              try {
                switch (type) {
                  case 'pincode':
                    final response = await ApiService.getSuggestions('pincode', pattern);
                    return response;
                  case 'district':
                    final response = await ApiService.getSuggestions('district', pattern);
                    return response;
                  case 'state':
                    final response = await ApiService.getSuggestions('state', pattern);
                    return response;
                  case 'area':
                    final response = await ApiService.getSuggestions('area', pattern);
                    return response;
                  default:
                    return [];
                }
              } catch (e) {
                return [];
              }
            },
            itemBuilder: (context, suggestion) {
              return ListTile(
                title: Text(
                  suggestion.toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4A4A4A),
              ),
            ),
              );
            },
            onSuggestionSelected: (suggestion) {
              controller.text = suggestion.toString();
            },
            suggestionsBoxDecoration: SuggestionsBoxDecoration(
              borderRadius: BorderRadius.circular(12),
              elevation: 4,
              color: Colors.white,
            ),
            hideOnEmpty: true,
            hideOnLoading: true,
            keepSuggestionsOnLoading: false,
            minCharsForSuggestions: 1,
            animationDuration: const Duration(milliseconds: 300),
            transitionBuilder: (context, suggestionsBox, controller) {
              return suggestionsBox;
            },
              ),
            ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSearchButton() {
    return Container(
      width: double.infinity,
      height: 56,
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF015c68), Color(0xFF0396A6)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF015c68).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
              ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _performSearch,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'SEARCH PHARMACIES',
                      style: TextStyle(
                      color: Colors.white,
                        fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      ),
                    ),
                  ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF015c68),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pharmacy Locator',
              style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              const Text(
                'Enter your location',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 24),
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              _buildSuggestionField(
                label: 'Enter PIN code',
                hint: 'Enter 6-digit PIN code',
                controller: _pinController,
                type: 'pincode',
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
              _buildSuggestionField(
                label: 'Enter district',
                hint: 'Enter district name',
                controller: _districtController,
                type: 'district',
              ),
              _buildSuggestionField(
                label: 'Enter state',
                hint: 'Enter state name',
                controller: _stateController,
                type: 'state',
              ),
              _buildSuggestionField(
                label: 'Enter area',
                hint: 'Enter area/locality name',
                controller: _areaController,
                type: 'area',
              ),
              _buildSearchButton(),
              if (_searchResults.isNotEmpty) ...[
                const SizedBox(height: 24),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final pharmacy = _searchResults[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pharmacy['Name'] ?? 'N/A',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, 
                                  size: 18, 
                                  color: Color(0xFF666666)
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                              pharmacy['Address'] ?? 'N/A',
                              style: const TextStyle(
                fontSize: 16,
                                color: Color(0xFF666666),
                              ),
                            ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_city_outlined, 
                                  size: 18, 
                                  color: Color(0xFF666666)
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${pharmacy['District Name'] ?? 'N/A'}, ${pharmacy['State Name'] ?? 'N/A'}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF666666),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.local_post_office_outlined, 
                                  size: 18, 
                                  color: Color(0xFF666666)
                                ),
                                const SizedBox(width: 4),
                            Text(
                                  'PIN: ${pharmacy['Pin Code'] ?? 'N/A'}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF666666),
              ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.phone_outlined, 
                                  size: 18, 
                                  color: Color(0xFF666666)
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  pharmacy['Contact'] ?? 'N/A',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF666666),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (pharmacy['Contact'] != null)
                                  IconButton(
                                    icon: const Icon(Icons.copy, size: 18),
                                    color: const Color(0xFF015c68),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(
                                        text: pharmacy['Contact']!
                                      ));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Contact number copied to clipboard'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                  ),
                              ],
            ),
          ],
        ),
      ),
    );
                  },
                ),
              ],
            ],
              ),
            ),
      ),
    );
  }
} 