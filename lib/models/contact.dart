class Contact {
  final String? id;
  final String name;
  final String phone;
  final String email;
  final String address;

  Contact({
    this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
  });

  factory Contact.fromMap(String id, Map<dynamic, dynamic> map) {
    return Contact(
      id: id,
      name: map['name']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
    };
  }
}