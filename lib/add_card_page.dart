import 'package:flutter/material.dart';

class AddCardPage extends StatefulWidget {
  const AddCardPage({
    super.key,
    this.initialName = '',
    this.initialLast4 = '',
    this.initialExp = '',
    this.initialCvv = '',
    this.setDefaultInitially = true,
  });

  final String initialName;
  final String initialLast4;
  final String initialExp; // MM/YY
  final String initialCvv;
  final bool setDefaultInitially;

  @override
  State<AddCardPage> createState() => _AddCardPageState();
}

class _AddCardPageState extends State<AddCardPage> {
  final TextEditingController _cardNumber = TextEditingController();
  final TextEditingController _exp = TextEditingController();
  final TextEditingController _cvv = TextEditingController();
  bool _setDefault = true;

  @override
  void initState() {
    super.initState();
    _setDefault = widget.setDefaultInitially;
    if (widget.initialLast4.isNotEmpty) {
      _cardNumber.text = widget.initialLast4;
    }
    _exp.text = widget.initialExp;
    _cvv.text = widget.initialCvv;
  }

  @override
  void dispose() {
    _cardNumber.dispose();
    _exp.dispose();
    _cvv.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF7A00);

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
          'Add card',
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _cardPreview(
                      name: widget.initialName.isEmpty
                          ? 'ALEXEI SIDORENKO'
                          : widget.initialName,
                      last4: _cardNumber.text.isEmpty
                          ? 'XXXX'
                          : _cardNumber.text.padLeft(4, 'X').substring(
                                _cardNumber.text.length >= 4
                                    ? _cardNumber.text.length - 4
                                    : 0,
                              ),
                      exp: _exp.text.isEmpty ? '01/23' : _exp.text,
                    ),
                    const SizedBox(height: 18),
                    _label('Card number', color: orange),
                    const SizedBox(height: 8),
                    _underlinedField(
                      controller: _cardNumber,
                      hint: '4950 45XX XXXX XXXX',
                      keyboardType: TextInputType.number,
                      accent: orange,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Exp Date'),
                              const SizedBox(height: 8),
                              _underlinedField(
                                controller: _exp,
                                hint: 'DD.MM.YYYY',
                                keyboardType: TextInputType.datetime,
                                accent: orange,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('CVV Code'),
                              const SizedBox(height: 8),
                              _underlinedField(
                                controller: _cvv,
                                hint: '000',
                                keyboardType: TextInputType.number,
                                accent: orange,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Checkbox(
                          value: _setDefault,
                          activeColor: orange,
                          onChanged: (v) => setState(() => _setDefault = v ?? true),
                        ),
                        const Expanded(
                          child: Text(
                            'Set as your default payment method',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
                      backgroundColor: orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      final last4 =
                          _cardNumber.text.replaceAll(RegExp(r'[^0-9]'), '');
                      final cleanedLast4 =
                          last4.isEmpty ? '0000' : last4.padLeft(4, '0');

                      Navigator.pop(context, <String, dynamic>{
                        'last4': cleanedLast4.substring(
                          cleanedLast4.length - 4,
                        ),
                        'exp': _exp.text.trim().isEmpty ? '10/24' : _exp.text.trim(),
                        'default': _setDefault,
                      });
                    },
                    child: const Text(
                      'Add',
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

  Widget _cardPreview({
    required String name,
    required String last4,
    required String exp,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE7EEF9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
              const Spacer(),
              Container(
                width: 34,
                height: 22,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white.withValues(alpha: 0.0),
                ),
                child: const Icon(Icons.circle, color: Colors.red, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'CARD NUMBER',
            style: TextStyle(
              color: Color(0xFF6E7B8A),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '**** **** **** $last4',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MONTH/YEAR',
                      style: TextStyle(
                        color: Color(0xFF6E7B8A),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exp,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'CVV',
                      style: TextStyle(
                        color: Color(0xFF6E7B8A),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'XXX',
                      style: TextStyle(
                        color: Color(0xFF6E7B8A),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _label(String text, {Color color = Colors.black}) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        fontFamily: 'Poppins',
      ),
    );
  }

  Widget _underlinedField({
    required TextEditingController controller,
    required String hint,
    required Color accent,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFFBDBDBD),
          fontSize: 13,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: accent, width: 2),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: accent, width: 2),
        ),
      ),
    );
  }
}

