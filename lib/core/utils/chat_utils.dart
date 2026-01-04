String chatIdOf(String uid1, String uid2) {
  final ids = [uid1, uid2]..sort();
  return ids.join('_');
}
