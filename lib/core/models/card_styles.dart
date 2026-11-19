import 'package:flutter/material.dart';

/// Visual themes that *resemble* real-world card product palettes.
/// These are illustrative colour styles only – CardVault cards are never official
/// bank-issued artwork, and custom designs are never presented as official.
enum CardTexture { none, brushed, diagonal, guilloche, dots, carbon }

class CardStyle {
  final String id, bank, product;
  final List<Color> colors;
  final Color text;
  final CardTexture texture;
  final bool dark;
  const CardStyle(this.id, this.bank, this.product, this.colors,
      {this.text = Colors.white, this.texture = CardTexture.none, this.dark = true});
}

const kNetworks = ['Visa', 'Mastercard', 'RuPay', 'American Express', 'Diners Club'];
const kVariants = ['Classic', 'Platinum', 'Signature', 'Select', 'Gold', 'World', 'World Elite', 'Infinite', 'Premium', 'Co-branded', 'Other'];

const kBanks = [
  'HDFC Bank', 'ICICI Bank', 'State Bank of India', 'Axis Bank', 'Kotak Mahindra Bank',
  'IDFC FIRST Bank', 'Bank of Baroda', 'Punjab National Bank', 'Canara Bank', 'Union Bank of India',
  'IndusInd Bank', 'AU Small Finance Bank', 'Federal Bank', 'Yes Bank', 'American Express',
];

Color _c(int v) => Color(v);

final kThemes = <CardStyle>[
  // HDFC – deep navy / royal blue family, Infinia in brushed graphite-black
  CardStyle('hdfc_regalia', 'HDFC Bank', 'Regalia', [_c(0xFF0B2A5B), _c(0xFF1C4C99), _c(0xFF0A1F44)], texture: CardTexture.guilloche),
  CardStyle('hdfc_infinia', 'HDFC Bank', 'Infinia', [_c(0xFF1A1A1C), _c(0xFF3A3A3F), _c(0xFF0E0E10)], texture: CardTexture.brushed),
  CardStyle('hdfc_diners', 'HDFC Bank', 'Diners Club Black', [_c(0xFF0B0B0C), _c(0xFF2B2B2E), _c(0xFF050505)], texture: CardTexture.carbon),
  CardStyle('hdfc_millennia', 'HDFC Bank', 'Millennia', [_c(0xFF123E8C), _c(0xFF2C6BD6), _c(0xFF0C2B66)], texture: CardTexture.diagonal),
  CardStyle('hdfc_swiggy', 'HDFC Bank', 'Swiggy (Co-branded)', [_c(0xFFFF7A1A), _c(0xFFE85D04), _c(0xFF9D3A00)], texture: CardTexture.dots),
  CardStyle('hdfc_debit', 'HDFC Bank', 'Debit Classic', [_c(0xFF0F3A82), _c(0xFF1E5BC6), _c(0xFF0A2A60)], texture: CardTexture.diagonal),
  // ICICI – orange/maroon identity; Emeralde in deep emerald-black
  CardStyle('icici_amazon', 'ICICI Bank', 'Amazon Pay (Co-branded)', [_c(0xFF1E2A38), _c(0xFF37475A), _c(0xFF131A22)], texture: CardTexture.brushed),
  CardStyle('icici_coral', 'ICICI Bank', 'Coral', [_c(0xFFE2662B), _c(0xFFB5361C), _c(0xFF7A1F10)], texture: CardTexture.diagonal),
  CardStyle('icici_sapphiro', 'ICICI Bank', 'Sapphiro', [_c(0xFF16254F), _c(0xFF2F4A97), _c(0xFF0E1736)], texture: CardTexture.guilloche),
  CardStyle('icici_emeralde', 'ICICI Bank', 'Emeralde Private Metal', [_c(0xFF0B3B34), _c(0xFF1C6B5C), _c(0xFF06231F)], texture: CardTexture.brushed),
  CardStyle('icici_debit', 'ICICI Bank', 'Debit Platinum', [_c(0xFFC7581F), _c(0xFF8E2A18), _c(0xFF5E1B0F)], texture: CardTexture.diagonal),
  // SBI – SBI blue
  CardStyle('sbi_simplyclick', 'State Bank of India', 'SimplyCLICK', [_c(0xFF1D4F9F), _c(0xFF2E7BD1), _c(0xFF123368)], texture: CardTexture.dots),
  CardStyle('sbi_elite', 'State Bank of India', 'Elite', [_c(0xFF14172B), _c(0xFF2A3050), _c(0xFF0A0C1A)], texture: CardTexture.guilloche),
  CardStyle('sbi_debit', 'State Bank of India', 'Debit Classic', [_c(0xFF1B6EC2), _c(0xFF3AA0E8), _c(0xFF0F4C8C)], texture: CardTexture.diagonal),
  CardStyle('sbi_gold', 'State Bank of India', 'Gold', [_c(0xFFB88A2E), _c(0xFFE3C268), _c(0xFF86621A)], texture: CardTexture.guilloche, text: Color(0xFF2A1D05), dark: false),
  // Axis – burgundy / maroon
  CardStyle('axis_magnus', 'Axis Bank', 'Magnus', [_c(0xFF2A0D14), _c(0xFF5D1A2B), _c(0xFF160509)], texture: CardTexture.brushed),
  CardStyle('axis_flipkart', 'Axis Bank', 'Flipkart (Co-branded)', [_c(0xFF1F6BD8), _c(0xFF4A9BFF), _c(0xFF123F85)], texture: CardTexture.dots),
  CardStyle('axis_ace', 'Axis Bank', 'ACE', [_c(0xFF8C1D40), _c(0xFFBA2B58), _c(0xFF5A1028)], texture: CardTexture.diagonal),
  CardStyle('axis_reserve', 'Axis Bank', 'Reserve', [_c(0xFF3B0F1D), _c(0xFF7A2640), _c(0xFF1F0810)], texture: CardTexture.carbon),
  // Kotak – red/navy
  CardStyle('kotak_league', 'Kotak Mahindra Bank', 'League Platinum', [_c(0xFFB3202A), _c(0xFFE23A44), _c(0xFF731018)], texture: CardTexture.diagonal),
  CardStyle('kotak_zen', 'Kotak Mahindra Bank', 'Zen Signature', [_c(0xFF0F1F3F), _c(0xFF223F77), _c(0xFF08122A)], texture: CardTexture.guilloche),
  CardStyle('kotak_811', 'Kotak Mahindra Bank', '811 Debit', [_c(0xFFD7262F), _c(0xFF7E1119), _c(0xFF3F070B)], texture: CardTexture.dots),
  // IDFC FIRST – deep wine / crimson
  CardStyle('idfc_wealth', 'IDFC FIRST Bank', 'Wealth', [_c(0xFF3A1020), _c(0xFF731B3A), _c(0xFF1E0710)], texture: CardTexture.brushed),
  CardStyle('idfc_select', 'IDFC FIRST Bank', 'Select', [_c(0xFF9B1B3A), _c(0xFFCC2F55), _c(0xFF5E0F22)], texture: CardTexture.diagonal),
  CardStyle('idfc_millennia', 'IDFC FIRST Bank', 'Millennia', [_c(0xFF7A1232), _c(0xFFB22349), _c(0xFF450A1D)], texture: CardTexture.dots),
  // Bank of Baroda – orange / navy
  CardStyle('bob_eterna', 'Bank of Baroda', 'Eterna', [_c(0xFFF26A21), _c(0xFFD9480F), _c(0xFF8F2C05)], texture: CardTexture.diagonal),
  CardStyle('bob_premier', 'Bank of Baroda', 'Premier', [_c(0xFF14213D), _c(0xFF2B3F6E), _c(0xFF0A1226)], texture: CardTexture.guilloche),
  // PNB – maroon / gold
  CardStyle('pnb_platinum', 'Punjab National Bank', 'Platinum', [_c(0xFF7A1E2C), _c(0xFFA8323F), _c(0xFF4A0F19)], texture: CardTexture.guilloche),
  CardStyle('pnb_rupay', 'Punjab National Bank', 'RuPay Select', [_c(0xFF8B2332), _c(0xFFC14A3B), _c(0xFF551018)], texture: CardTexture.diagonal),
  // Canara – cyan/yellow identity
  CardStyle('canara_platinum', 'Canara Bank', 'Platinum', [_c(0xFF0B6E99), _c(0xFF1FA4D6), _c(0xFF074A66)], texture: CardTexture.diagonal),
  CardStyle('canara_gold', 'Canara Bank', 'Gold', [_c(0xFFC79A2B), _c(0xFFF0CD6A), _c(0xFF8C6812)], texture: CardTexture.guilloche, text: Color(0xFF2A1D05), dark: false),
  // Union Bank – red/blue
  CardStyle('union_select', 'Union Bank of India', 'Select', [_c(0xFFC0202B), _c(0xFF1B4E9B), _c(0xFF0F2D5C)], texture: CardTexture.diagonal),
  CardStyle('union_classic', 'Union Bank of India', 'Classic', [_c(0xFFB01E28), _c(0xFFD9444C), _c(0xFF6F1017)], texture: CardTexture.dots),
  // IndusInd – maroon / wine
  CardStyle('indusind_legend', 'IndusInd Bank', 'Legend', [_c(0xFF5B0F22), _c(0xFF8F1D3A), _c(0xFF32050F)], texture: CardTexture.brushed),
  CardStyle('indusind_pioneer', 'IndusInd Bank', 'Pioneer Heritage', [_c(0xFF1A1014), _c(0xFF48212E), _c(0xFF0C0608)], texture: CardTexture.carbon),
  // AU Small Finance – orange/purple
  CardStyle('au_lit', 'AU Small Finance Bank', 'LIT', [_c(0xFFF47B20), _c(0xFF6D2077), _c(0xFF3D0E45)], texture: CardTexture.diagonal),
  CardStyle('au_altura', 'AU Small Finance Bank', 'Altura Plus', [_c(0xFF4A1A55), _c(0xFF8A3A97), _c(0xFF2B0F32)], texture: CardTexture.dots),
  // Federal – blue / gold
  CardStyle('federal_signet', 'Federal Bank', 'Signet', [_c(0xFF123E7C), _c(0xFF1F6FBF), _c(0xFF0A2850)], texture: CardTexture.guilloche),
  CardStyle('federal_celesta', 'Federal Bank', 'Celesta', [_c(0xFF0F2447), _c(0xFFB79A4E), _c(0xFF081529)], texture: CardTexture.brushed),
  // Yes – blue / white
  CardStyle('yes_reserv', 'Yes Bank', 'Reserv', [_c(0xFF0B1B3F), _c(0xFF1F3A7A), _c(0xFF050D22)], texture: CardTexture.brushed),
  CardStyle('yes_prosperity', 'Yes Bank', 'Prosperity', [_c(0xFF0F4DA8), _c(0xFF2C80E8), _c(0xFF093272)], texture: CardTexture.diagonal),
  // American Express – Amex blue / platinum / gold / green
  CardStyle('amex_platinum', 'American Express', 'Platinum', [_c(0xFFD8DADD), _c(0xFFA9ADB3), _c(0xFF7E838B)], texture: CardTexture.brushed, text: Color(0xFF1B1D21), dark: false),
  CardStyle('amex_gold', 'American Express', 'Gold', [_c(0xFFD9B766), _c(0xFFB88F3C), _c(0xFF8A6A25)], texture: CardTexture.brushed, text: Color(0xFF2A1D05), dark: false),
  CardStyle('amex_green', 'American Express', 'Green', [_c(0xFF2F7D5B), _c(0xFF3FA074), _c(0xFF1C4D37)], texture: CardTexture.diagonal),
  CardStyle('amex_blue', 'American Express', 'Blue / SmartEarn', [_c(0xFF006FCF), _c(0xFF2C99F0), _c(0xFF00478A)], texture: CardTexture.dots),
  // Network-generic product tiers
  CardStyle('visa_signature', 'Generic', 'Visa Signature', [_c(0xFF1A1F71), _c(0xFF2B35B5), _c(0xFF0E1244)], texture: CardTexture.guilloche),
  CardStyle('mc_world_elite', 'Generic', 'Mastercard World Elite', [_c(0xFF18181B), _c(0xFF3C3C42), _c(0xFF0B0B0D)], texture: CardTexture.carbon),
  CardStyle('rupay_select', 'Generic', 'RuPay Select', [_c(0xFF1F5E3B), _c(0xFF2F8F5B), _c(0xFF12382A)], texture: CardTexture.diagonal),
  CardStyle('custom', 'Custom', 'Custom design', [_c(0xFF2B2F3A), _c(0xFF4A5166), _c(0xFF171A22)], texture: CardTexture.guilloche),
];

CardStyle themeById(String id) => kThemes.firstWhere((t) => t.id == id, orElse: () => kThemes.last);

List<CardStyle> themesForBank(String bank) {
  final l = kThemes.where((t) => t.bank == bank).toList();
  return l.isEmpty ? kThemes.where((t) => t.bank == 'Generic').toList() : l;
}

/// Preset custom palettes shown in the custom-theme picker.
const kCustomPalettes = <List<int>>[
  [0xFF2B2F3A, 0xFF171A22], [0xFF0F3A82, 0xFF0A2A60], [0xFF7A1E2C, 0xFF3F0C14], [0xFF1F5E3B, 0xFF0F2E1D],
  [0xFF6D2077, 0xFF2D0B33], [0xFFE2662B, 0xFF7A1F10], [0xFFD9B766, 0xFF86621A], [0xFF0B6E99, 0xFF063A52],
];
