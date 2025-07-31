class VilleUtils {
  // Map code postal -> ville (extrait, à compléter)
  static const Map<String, String> codePostalToVille = {
    '32000': 'Al Hoceïma',
    '22000': 'Azilal',
    '43150': 'Ben Guerir',
    '13000': 'Benslimane',
    '26100': 'Berrechid',
    '87200': 'Biougra',
    '71000': 'Boujdour',
    '33000': 'Boulemane',
    '91000': 'Chefchaouen',
    '41000': 'Chichaoua',
    '73000': 'Dakhla',
    '52000': 'Errachidia',
    '44000': 'Essaouira',
    '61000': 'Figuig',
    '81000': 'Guelmim',
    '53000': 'Ifrane',
    '43000': 'El Kelaâ des Sraghna',
    '92000': 'Larache',
    '45000': 'Ouarzazate',
    '26000': 'Settat',
    '31000': 'Séfrou',
    '85200': 'Sidi Ifni',
    '16000': 'Sidi Kacem',
    '14200': 'Sidi Slimane',
    '72000': 'Es-Semara',
    '34000': 'Taounate',
    '82000': 'Tan-Tan',
    '83000': 'Taroudant',
    '84000': 'Tata',
    '85000': 'Tiznit',
    // ... (ajoute d'autres codes uniques ici)
  };

  /// Extrait le code postal d'une adresse complète
  static String? extractCodePostal(String address) {
    final regex = RegExp(r'\b\d{5}\b');
    final match = regex.firstMatch(address);
    return match?.group(0);
  }

  /// Convertit un code postal en nom de ville
  static String? villeDepuisCodePostal(String codePostal) {
    if (codePostalToVille.containsKey(codePostal)) {
      return codePostalToVille[codePostal];
    }
    final int cp = int.tryParse(codePostal) ?? -1;
    if (cp >= 20000 && cp <= 20999) return 'Casablanca';
    if (cp >= 10000 && cp <= 10999) return 'Rabat';
    if (cp >= 11000 && cp <= 11999) return 'Salé';
    if (cp >= 40000 && cp <= 40999) return 'Marrakech';
    if (cp >= 30000 && cp <= 30999) return 'Fès';
    if (cp >= 90000 && cp <= 90999) return 'Tanger';
    if (cp >= 14000 && cp <= 14999) return 'Kénitra';
    if (cp >= 15000 && cp <= 15999) return 'Khémisset';
    if (cp >= 25000 && cp <= 25999) return 'Khouribga';
    if (cp >= 24000 && cp <= 24999) return 'El Jadida';
    if (cp >= 50000 && cp <= 50999) return 'Meknès';
    if (cp >= 60000 && cp <= 60999) return 'Oujda';
    if (cp >= 28800 && cp <= 28899) return 'Mohammédia';
    if (cp >= 62000 && cp <= 62999) return 'Nador';
    if (cp >= 46000 && cp <= 46999) return 'Safi';
    if (cp >= 35000 && cp <= 35999) return 'Taza';
    if (cp >= 12000 && cp <= 12999) return 'Témara';
    if (cp >= 93000 && cp <= 93999) return 'Tétouan';
    if (cp >= 80100 && cp <= 80199) return 'Inezgane';
    if (cp >= 86300 && cp <= 86399) return 'Inezgane';
    if (cp >= 23000 && cp <= 23999) return 'Béni Mellal';
    if (cp >= 63300 && cp <= 63399) return 'Berkane';
    return null;
  }

  /// Extrait le nom de la ville depuis une adresse complète
  static String villeDepuisAdresse(String address) {
    final codePostal = extractCodePostal(address);
    if (codePostal != null) {
      return villeDepuisCodePostal(codePostal) ?? codePostal;
    }
    return '';
  }
} 