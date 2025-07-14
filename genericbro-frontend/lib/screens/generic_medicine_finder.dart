import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../models/medicine.dart';
import '../services/api_service.dart';
import '../utils/responsive_utils.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:developer' as developer;

// Define theme colors
const Color primaryColor = Color(0xFF015c68);
const Color primaryLightColor = Color(0xFF03A7C0);
const Color primaryVeryLightColor = Color(0xFFE1F5F8);
const Color textColor = Color(0xFF2D3748);
const Color subtitleColor = Color(0xFF718096);

enum SearchMode {
  name,
  formulation,
}

enum PriceSort {
  none,
  lowToHigh,
  highToLow,
}

extension PriceSortExtension on PriceSort {
  String get apiValue {
    switch (this) {
      case PriceSort.lowToHigh:
        return 'low_to_high';
      case PriceSort.highToLow:
        return 'high_to_low';
      case PriceSort.none:
        return 'none';
    }
  }
}

class GenericMedicineFinder extends StatefulWidget {
  const GenericMedicineFinder({super.key});

  @override
  State<GenericMedicineFinder> createState() => _GenericMedicineFinderState();
}

class _GenericMedicineFinderState extends State<GenericMedicineFinder>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  List<String> typeOptions = [];
  List<String> dosageOptions = [];
  Medicine? exactMatch;
  List<Medicine> similarFormulations = [];
  bool isLoading = false;
  String? errorMessage;
  String? uses;
  String? sideEffects;
  Timer? _debounceTimer;
  bool _isInitialized = false;
  PriceSort _selectedPriceSort = PriceSort.none;
  SearchMode _searchMode = SearchMode.name;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _handleSearchModeChange(SearchMode mode) {
    if (mode != _searchMode) {
      setState(() {
        _searchMode = mode;
        _searchController.clear();
        _typeController.clear();
        _dosageController.clear();
        exactMatch = null;
        similarFormulations = [];
        uses = null;
        sideEffects = null;
        errorMessage = null;
      });
    }
  }

  Future<void> _loadInitialData() async {
    if (_isInitialized) return;

    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final types = await ApiService.fetchSuggestions('Type', '');
      final dosages = await ApiService.fetchSuggestions('Dosage', '');

      if (mounted) {
        setState(() {
          typeOptions = types;
          dosageOptions = dosages;
          isLoading = false;
          _isInitialized = true;
        });
      }
    } catch (e) {
      developer.log('Error loading initial data', error: e);
      if (mounted) {
        setState(() {
          errorMessage = 'Failed to load initial data. Please try again.';
          isLoading = false;
        });
      }
    }
  }

  Future<List<String>> _getSuggestions(String pattern, String field) async {
    if (pattern.isEmpty) {
      return field == 'type' ? typeOptions : field == 'dosage' ? dosageOptions : [];
    }

    try {
      String apiField;
      switch (field.toLowerCase()) {
        case 'medicine name':
          apiField = 'Name';
          break;
        case 'formulation':
          apiField = 'Formulation';
          break;
        case 'type':
          apiField = 'Type';
          break;
        case 'dosage':
          apiField = 'Dosage';
          break;
        default:
          apiField = field;
      }

      // Add a smaller delay to prevent too many API calls
      await Future.delayed(const Duration(milliseconds: 100));

      final suggestions = await ApiService.fetchSuggestions(apiField, pattern);
      developer.log('Got suggestions for $field', error: {
        'pattern': pattern,
        'suggestions': suggestions,
        'apiField': apiField
      });
      return suggestions;
    } catch (e) {
      developer.log('Error getting suggestions', error: {
        'field': field,
        'pattern': pattern,
        'error': e
      });
      // Return empty list on error to prevent UI from breaking
      return [];
    }
  }

  List<Medicine> _sortMedicines(List<Medicine> medicines) {
    if (_selectedPriceSort == PriceSort.none) return medicines;

    final sortedList = List<Medicine>.from(medicines);
    sortedList.sort((a, b) {
      // Use generic price for sorting
      final priceA = a.costOfGeneric;
      final priceB = b.costOfGeneric;
      
      if (_selectedPriceSort == PriceSort.lowToHigh) {
        return priceA.compareTo(priceB);
      } else {
        return priceB.compareTo(priceA);
      }
    });
    return sortedList;
  }

  Future<void> _searchMedicines() async {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }

    // Validate input
    if (_searchController.text.isEmpty && 
        _typeController.text.isEmpty && 
        _dosageController.text.isEmpty) {
      setState(() {
        errorMessage = _searchMode == SearchMode.name
            ? 'Please enter a medicine name, type, or dosage'
            : 'Please enter a formulation, type, or dosage';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
      exactMatch = null;
      similarFormulations = [];
      uses = null;
      sideEffects = null;
    });

    try {
      // If only type is provided, use the dedicated type endpoint
      if (_typeController.text.isNotEmpty &&
          _searchController.text.isEmpty &&
          _dosageController.text.isEmpty) {
        developer.log('Using dedicated type endpoint', error: {
          'type': _typeController.text,
          'sort_order': _selectedPriceSort.apiValue
        });
        
        final medicines = await ApiService.getMedicinesByType(
          _typeController.text,
          sortOrder: _selectedPriceSort.apiValue
        );
        
        if (mounted) {
          setState(() {
            isLoading = false;
            similarFormulations = medicines;
            // For type searches, show uses and side effects of the first medicine if available
            if (medicines.isNotEmpty) {
              uses = medicines[0].uses;
              sideEffects = medicines[0].sideEffects;
            }
          });
        }
        return;
      }

      // Otherwise, use the regular search endpoint
      final searchParams = {
        'name': _searchMode == SearchMode.name ? _searchController.text : null,
        'formulation': _searchMode == SearchMode.formulation ? _searchController.text : null,
        'type': _typeController.text,
        'dosage': _dosageController.text,
      };
      
      developer.log('Searching medicines with params', error: searchParams);

      final searchResult = await ApiService.searchMedicines(
        name: searchParams['name'],
        formulation: searchParams['formulation'],
        type: searchParams['type'],
        dosage: searchParams['dosage'],
        sortOrder: _selectedPriceSort.apiValue,
      );

      developer.log('Search result', error: {
        'exact_match': searchResult['exact_match'],
        'similar_count': (searchResult['similar_formulations'] as List).length,
      });

      if (mounted) {
        setState(() {
          exactMatch = searchResult['exact_match'] as Medicine?;
          similarFormulations = List<Medicine>.from(searchResult['similar_formulations']);
          uses = searchResult['Uses'] as String?;
          sideEffects = searchResult['Side Effects'] as String?;
          isLoading = false;
          
          if (exactMatch == null && similarFormulations.isEmpty) {
            errorMessage = 'No medicines found matching your criteria';
          }
        });
      }
    } catch (e) {
      developer.log('Error searching medicines', error: e);
      if (mounted) {
        setState(() {
          errorMessage = 'Failed to search medicines. Please try again.';
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _typeController.dispose();
    _dosageController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  InputDecoration _buildInputDecoration(String label, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      hintText: label,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
      prefixIcon: Icon(icon, color: const Color(0xFF666666), size: 20),
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF015c68), width: 1.5),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildClearButton(TextEditingController controller) {
    return controller.text.isNotEmpty
        ? IconButton(
            icon: const Icon(Icons.clear, size: 20),
            onPressed: () {
              controller.clear();
              _searchMedicines();
            },
          )
        : const SizedBox.shrink();
  }

  String _cleanTypeValue(String type) {
    // Remove the prefix letter and hyphen, and clean up spaces
    if (type.contains('-')) {
      final parts = type.split('-');
      if (parts.length > 1) {
        return parts.sublist(1).join('-').trim();
      }
    }
    return type.trim();
  }

  Widget _buildTypeField(double width) {
    return SizedBox(
      width: width,
      child: TypeAheadField(
        textFieldConfiguration: TextFieldConfiguration(
          controller: _typeController,
          decoration: _buildInputDecoration(
            'Medicine Type',
            Icons.category,
            suffix: _buildClearButton(_typeController),
          ),
        ),
        suggestionsCallback: (pattern) async {
          final suggestions = await _getSuggestions(pattern, 'Type');
          // Sort suggestions by the cleaned type name
          suggestions.sort((a, b) => _cleanTypeValue(a).compareTo(_cleanTypeValue(b)));
          return suggestions;
        },
        itemBuilder: (context, String suggestion) {
          final cleanedType = _cleanTypeValue(suggestion);
          return ListTile(
            title: Text(
              cleanedType,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              suggestion,
              style: TextStyle(
                fontSize: 12,
                color: subtitleColor,
              ),
            ),
          );
        },
        onSuggestionSelected: (String suggestion) {
          _typeController.text = suggestion;
          _searchMedicines();
        },
        noItemsFoundBuilder: (context) => Container(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No medicine types found',
            style: TextStyle(color: subtitleColor),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(String label, IconData icon, TextEditingController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF4A4A4A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TypeAheadField<String>(
            textFieldConfiguration: TextFieldConfiguration(
              controller: controller,
              decoration: _buildInputDecoration(
                'Enter $label',
                icon,
                suffix: _buildClearButton(controller),
              ),
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF4A4A4A),
              ),
            ),
            suggestionsCallback: (pattern) async {
              if (pattern.length < 1) return [];
              return await _getSuggestions(pattern, label);
            },
            itemBuilder: (context, String suggestion) {
              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                ),
                child: ListTile(
                  title: Text(
                    suggestion,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF4A4A4A),
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  hoverColor: const Color(0xFFE1F5F8),
                ),
              );
            },
            onSuggestionSelected: (String suggestion) {
              controller.text = suggestion;
              _searchMedicines();
            },
            noItemsFoundBuilder: (context) => Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No $label found',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ),
            suggestionsBoxDecoration: SuggestionsBoxDecoration(
              borderRadius: BorderRadius.circular(12),
              elevation: 4,
              shadowColor: Colors.black26,
              constraints: const BoxConstraints(maxHeight: 200),
              hasScrollbar: true,
            ),
            transitionBuilder: (context, suggestionsBox, controller) {
              return suggestionsBox;
            },
            animationDuration: Duration.zero,
            hideOnEmpty: true,
            hideOnLoading: true,
            keepSuggestionsOnLoading: false,
            hideSuggestionsOnKeyboardHide: true,
            keepSuggestionsOnSuggestionSelected: false,
            minCharsForSuggestions: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchModeToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleButton(
              label: 'Search by Name',
              isSelected: _searchMode == SearchMode.name,
              onTap: () => _handleSearchModeChange(SearchMode.name),
            ),
          ),
          Container(
            width: 1,
            height: 32,
            color: Colors.grey.shade300,
          ),
          Expanded(
            child: _buildToggleButton(
              label: 'Search by Formulation',
              isSelected: _searchMode == SearchMode.formulation,
              onTap: () => _handleSearchModeChange(SearchMode.formulation),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF015c68), Color(0xFF0396A6)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: isSelected ? null : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF4A4A4A),
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ),
      ),
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
          onTap: isLoading ? null : _searchMedicines,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'SEARCH MEDICINES',
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

  Widget _buildSortingDropdown() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Sort by Price',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF4A4A4A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DropdownButtonFormField<PriceSort>(
              value: _selectedPriceSort,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                filled: true,
                fillColor: Colors.white,
              ),
              items: const [
                DropdownMenuItem(
                  value: PriceSort.none,
                  child: Text('No sorting'),
                ),
                DropdownMenuItem(
                  value: PriceSort.lowToHigh,
                  child: Text('Price: Low to High'),
                ),
                DropdownMenuItem(
                  value: PriceSort.highToLow,
                  child: Text('Price: High to Low'),
                ),
              ],
              onChanged: (PriceSort? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedPriceSort = newValue;
                  });
                  _searchMedicines();
                }
              },
              dropdownColor: Colors.white,
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF666666)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {int? count}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1F36),
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMedicineCard(Medicine medicine, {bool isExactMatch = false}) {
    // Calculate savings percentage
    double savingsPercentage = ((medicine.costOfBranded - medicine.costOfGeneric) / medicine.costOfBranded) * 100;
    double savingsAmount = medicine.costOfBranded - medicine.costOfGeneric;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: const Color(0xFF4CAF50),
                width: 4,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Medicine Name and Generic Name
                Text(
                  medicine.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1F36),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  medicine.formulation,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 12),

                // Formulation and Type Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FORMULATION',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            medicine.formulation,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1F36),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TYPE',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            medicine.type,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1F36),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Dosage Row
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DOSAGE',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      medicine.dosage,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1F36),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Price Comparison
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Branded Price:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A1F36),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹${medicine.costOfBranded.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE53935),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Generic Price:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A1F36),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹${medicine.costOfGeneric.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'You Save:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A1F36),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹${savingsAmount.toStringAsFixed(2)} (${savingsPercentage.toStringAsFixed(0)}%)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Uses and Side Effects
                if (medicine.uses.isNotEmpty || medicine.sideEffects.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (medicine.uses.isNotEmpty) ...[
                          const Text(
                            'Uses',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1F36),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            medicine.uses,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                          ),
                          if (medicine.sideEffects.isNotEmpty)
                            const SizedBox(height: 12),
                        ],
                        if (medicine.sideEffects.isNotEmpty) ...[
                          const Text(
                            'Side Effects',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1F36),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            medicine.sideEffects,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF015c68),
        elevation: 0,
        title: const Text(
          'Generic Medicine Finder',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Find Generic Alternatives',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Search for branded medicines to find their generic alternatives',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              _buildSearchModeToggle(),
              if (errorMessage != null)
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
                          errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              _buildSearchField(
                _searchMode == SearchMode.name ? 'Medicine Name' : 'Formulation',
                Icons.medication,
                _searchController,
              ),
              _buildSearchField('Type', Icons.category, _typeController),
              _buildSearchField('Dosage', Icons.straighten, _dosageController),
              _buildSortingDropdown(),
              _buildSearchButton(),

              // Results
              if (isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                )
              else if (errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    errorMessage!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                )
              else ...[
                if (exactMatch != null) ...[
                  const SizedBox(height: 24),
                  _buildSectionHeader('Exact Matches', count: 1),
                  _buildMedicineCard(exactMatch!, isExactMatch: true),
                ],
                if (similarFormulations.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildSectionHeader('Similar Matches', count: similarFormulations.length),
                  ...similarFormulations.map((medicine) => _buildMedicineCard(medicine)),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
} 