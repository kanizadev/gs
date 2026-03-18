import 'package:flutter/material.dart';

import 'add_card_page.dart';

class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  static const Color _orange = Color(0xFFFF7A00);

  final List<_PaymentMethod> _methods = <_PaymentMethod>[
    _PaymentMethod(
      id: 'visa_4242',
      brand: _CardBrand.visa,
      masked: '**** **** **** 4978',
      expires: '10/24',
      isDefault: true,
    ),
    _PaymentMethod(
      id: 'mastercard_4444',
      brand: _CardBrand.mastercard,
      masked: '**** **** **** 2478',
      expires: '10/24',
      isDefault: false,
    ),
    _PaymentMethod(
      id: 'paypal',
      brand: _CardBrand.paypal,
      masked: 'Maciej Konokonos',
      expires: '',
      isDefault: false,
    ),
  ];

  void _setDefault(String id) {
    setState(() {
      for (final m in _methods) {
        m.isDefault = m.id == id;
      }
    });
  }

  Future<void> _addCard() async {
    final res = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const AddCardPage()),
    );
    if (!mounted || res == null) return;

    final last4 = (res['last4'] ?? '0000').toString();
    final exp = (res['exp'] ?? '10/24').toString();
    final setDefault = (res['default'] as bool?) ?? true;

    final newMethod = _PaymentMethod(
      id: 'visa_${DateTime.now().millisecondsSinceEpoch}',
      brand: _CardBrand.visa,
      masked: '**** **** **** $last4',
      expires: exp,
      isDefault: setDefault,
    );

    setState(() {
      _methods.insert(0, newMethod);
      if (setDefault) _setDefault(newMethod.id);
    });
  }

  Future<void> _editMethod(_PaymentMethod method) async {
    final res = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => AddCardPage(
          initialLast4: method.last4,
          initialExp: method.expires,
          setDefaultInitially: method.isDefault,
        ),
      ),
    );
    if (!mounted || res == null) return;

    final last4 = (res['last4'] ?? method.last4).toString();
    final exp = (res['exp'] ?? method.expires).toString();
    final setDefault = (res['default'] as bool?) ?? method.isDefault;

    setState(() {
      method.masked = '**** **** **** $last4';
      method.expires = exp;
      if (setDefault) _setDefault(method.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Payment methods',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _methods.isEmpty
                  ? const Center(
                      child: Text(
                        'No payment methods',
                        style: TextStyle(
                          color: Color(0xFF868889),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                      itemCount: _methods.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final m = _methods[index];
                        return InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => _setDefault(m.id),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFEDEDED)),
                          ),
                          child: Row(
                            children: [
                              _brandBadge(m.brand),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      m.masked,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                    if (m.expires.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'expires ${m.expires}',
                                        style: const TextStyle(
                                          color: Color(0xFF868889),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                height: 34,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _orange,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                  ),
                                  onPressed: () => _editMethod(m),
                                  child: const Text(
                                    'Edit',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                      },
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _addCard,
                    child: const Text(
                      'Add card',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethod {
  _PaymentMethod({
    required this.id,
    required this.brand,
    required this.masked,
    required this.expires,
    required this.isDefault,
  });

  final String id;
  final _CardBrand brand;
  String masked;
  String expires;
  bool isDefault;

  String get last4 {
    final digits = masked.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length >= 4 ? digits.substring(digits.length - 4) : '0000';
  }
}

enum _CardBrand { visa, mastercard, paypal }

Widget _brandBadge(_CardBrand brand) {
  switch (brand) {
    case _CardBrand.visa:
      return _badge(
        background: const Color(0xFF1A237E),
        child: const Text(
          'VISA',
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            fontFamily: 'Poppins',
          ),
        ),
      );
    case _CardBrand.mastercard:
      return _badge(
        background: Colors.white,
        border: const Color(0xFFEDEDED),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.circle, color: Colors.red, size: 14),
            Icon(Icons.circle, color: Colors.orange, size: 14),
          ],
        ),
      );
    case _CardBrand.paypal:
      return _badge(
        background: Colors.white,
        border: const Color(0xFFEDEDED),
        child: const Icon(Icons.paypal, color: Color(0xFF003087), size: 18),
      );
  }
}

Widget _badge({
  required Color background,
  Color? border,
  required Widget child,
}) {
  return Container(
    width: 54,
    height: 34,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(8),
      border: border == null ? null : Border.all(color: border),
    ),
    child: child,
  );
}

